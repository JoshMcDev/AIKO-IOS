/**
 * Regulation Update Monitor for AIKO
 * Monitors acquisition.gov for FAR/DFAR updates and synchronizes local knowledge base
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import axios from 'axios';
import * as cheerio from 'cheerio';
import { CronJob } from 'cron';
import nodemailer from 'nodemailer';
import { JSDOM } from 'jsdom';

interface RegulationUpdate {
  regulation: string;
  clauseNumber: string;
  changeType: 'added' | 'modified' | 'deleted';
  effectiveDate: Date;
  federalRegisterCitation?: string;
  oldContent?: string;
  newContent?: string;
  changeHash?: string;
}

interface MonitorConfig {
  checkInterval: string; // Cron format
  notificationEmail?: string;
  autoUpdate: boolean;
  backupBeforeUpdate: boolean;
  maxBackups: number;
  sources: RegulationSource[];
}

interface RegulationSource {
  name: string;
  baseUrl: string;
  changelogUrl?: string;
  rssUrl?: string;
  lastChecked?: Date;
  lastChangeHash?: string;
}

export class RegulationUpdateMonitor {
  private config: MonitorConfig;
  private regulationsPath: string;
  private cronJob?: CronJob;
  private updateHistory: RegulationUpdate[] = [];
  private emailTransporter?: nodemailer.Transporter;

  constructor(
    regulationsPath: string = '/Users/J/aiko/Sources/Resources/Regulations',
    config?: Partial<MonitorConfig>
  ) {
    this.regulationsPath = regulationsPath;
    this.config = {
      checkInterval: '0 0 * * 1', // Weekly on Monday at midnight
      autoUpdate: false,
      backupBeforeUpdate: true,
      maxBackups: 10,
      sources: [
        {
          name: 'FAR',
          baseUrl: 'https://www.acquisition.gov/far',
          changelogUrl: 'https://www.acquisition.gov/far/current-rule-making',
          rssUrl: 'https://www.acquisition.gov/rss/far'
        },
        {
          name: 'DFARS',
          baseUrl: 'https://www.acquisition.gov/dfars',
          changelogUrl: 'https://www.acquisition.gov/dfars/current-dfars-cases',
          rssUrl: 'https://www.acquisition.gov/rss/dfars'
        },
        {
          name: 'DFARS_PGI',
          baseUrl: 'https://www.acquisition.gov/dfarspgi',
          changelogUrl: 'https://www.acquisition.gov/dfarspgi/current-pgi-changes'
        }
      ],
      ...config
    };

    this.loadUpdateHistory();
    this.initializeEmailNotifications();
  }

  /**
   * Start monitoring for regulation updates
   */
  startMonitoring(): void {
    console.log(`Starting regulation update monitoring with interval: ${this.config.checkInterval}`);
    
    // Run initial check
    this.checkForUpdates();

    // Schedule recurring checks
    this.cronJob = new CronJob(this.config.checkInterval, () => {
      this.checkForUpdates();
    });

    this.cronJob.start();
  }

  /**
   * Stop monitoring
   */
  stopMonitoring(): void {
    if (this.cronJob) {
      this.cronJob.stop();
      console.log('Regulation monitoring stopped');
    }
  }

  /**
   * Check all sources for updates
   */
  async checkForUpdates(): Promise<RegulationUpdate[]> {
    console.log(`Checking for regulation updates at ${new Date().toISOString()}`);
    const allUpdates: RegulationUpdate[] = [];

    for (const source of this.config.sources) {
      try {
        const updates = await this.checkSourceForUpdates(source);
        allUpdates.push(...updates);
        
        // Update last checked timestamp
        source.lastChecked = new Date();
        this.saveConfig();
      } catch (error) {
        console.error(`Error checking ${source.name} for updates:`, error);
      }
    }

    if (allUpdates.length > 0) {
      await this.processUpdates(allUpdates);
    }

    return allUpdates;
  }

  /**
   * Check a specific source for updates
   */
  private async checkSourceForUpdates(source: RegulationSource): Promise<RegulationUpdate[]> {
    const updates: RegulationUpdate[] = [];

    // Method 1: Check RSS feed if available
    if (source.rssUrl) {
      const rssUpdates = await this.checkRSSFeed(source);
      updates.push(...rssUpdates);
    }

    // Method 2: Check changelog page
    if (source.changelogUrl) {
      const changelogUpdates = await this.checkChangelogPage(source);
      updates.push(...changelogUpdates);
    }

    // Method 3: Compare file hashes (fallback method)
    if (updates.length === 0) {
      const hashUpdates = await this.compareFileHashes(source);
      updates.push(...hashUpdates);
    }

    return updates;
  }

  /**
   * Check RSS feed for updates
   */
  private async checkRSSFeed(source: RegulationSource): Promise<RegulationUpdate[]> {
    const updates: RegulationUpdate[] = [];

    try {
      const response = await axios.get(source.rssUrl!, { 
        timeout: 30000,
        headers: {
          'User-Agent': 'AIKO-Regulation-Monitor/1.0'
        }
      });

      const $ = cheerio.load(response.data, { xmlMode: true });
      
      $('item').each((_, element) => {
        const title = $(element).find('title').text();
        const link = $(element).find('link').text();
        const pubDate = new Date($(element).find('pubDate').text());
        const description = $(element).find('description').text();

        // Parse FAR/DFAR clause numbers from title/description
        const clausePattern = /\b(52\.\d{3}-\d+|252\.\d{3}-\d{4})\b/g;
        const matches = (title + ' ' + description).matchAll(clausePattern);

        for (const match of matches) {
          updates.push({
            regulation: source.name,
            clauseNumber: match[1],
            changeType: this.determineChangeType(description),
            effectiveDate: pubDate,
            federalRegisterCitation: this.extractFederalRegisterCitation(description)
          });
        }
      });
    } catch (error) {
      console.error(`Error checking RSS feed for ${source.name}:`, error);
    }

    return updates;
  }

  /**
   * Check changelog page for updates
   */
  private async checkChangelogPage(source: RegulationSource): Promise<RegulationUpdate[]> {
    const updates: RegulationUpdate[] = [];

    try {
      const response = await axios.get(source.changelogUrl!, {
        timeout: 30000,
        headers: {
          'User-Agent': 'AIKO-Regulation-Monitor/1.0'
        }
      });

      const $ = cheerio.load(response.data);
      const currentHash = this.calculateHash(response.data);

      // Only process if content has changed
      if (currentHash !== source.lastChangeHash) {
        // Extract updates from changelog format
        // This would need to be customized based on actual page structure
        $('.changelog-entry, .rule-making, .far-case').each((_, element) => {
          const text = $(element).text();
          const clauseMatches = text.matchAll(/\b(52\.\d{3}-\d+|252\.\d{3}-\d{4})\b/g);
          
          for (const match of clauseMatches) {
            updates.push({
              regulation: source.name,
              clauseNumber: match[1],
              changeType: 'modified',
              effectiveDate: this.extractDate(text),
              federalRegisterCitation: this.extractFederalRegisterCitation(text)
            });
          }
        });

        source.lastChangeHash = currentHash;
        this.saveConfig();
      }
    } catch (error) {
      console.error(`Error checking changelog for ${source.name}:`, error);
    }

    return updates;
  }

  /**
   * Compare file hashes to detect changes
   */
  private async compareFileHashes(source: RegulationSource): Promise<RegulationUpdate[]> {
    const updates: RegulationUpdate[] = [];
    const hashFile = path.join(this.regulationsPath, source.name, '.hashes.json');
    
    let previousHashes: Record<string, string> = {};
    if (fs.existsSync(hashFile)) {
      previousHashes = JSON.parse(fs.readFileSync(hashFile, 'utf-8'));
    }

    const currentHashes: Record<string, string> = {};
    const regulationDir = path.join(this.regulationsPath, source.name);

    if (fs.existsSync(regulationDir)) {
      const files = fs.readdirSync(regulationDir)
        .filter(f => f.endsWith('.html'));

      for (const file of files) {
        const filePath = path.join(regulationDir, file);
        const content = fs.readFileSync(filePath, 'utf-8');
        const hash = this.calculateHash(content);
        currentHashes[file] = hash;

        const clauseNumber = file.replace('.html', '');

        // Check if file is new
        if (!previousHashes[file]) {
          updates.push({
            regulation: source.name,
            clauseNumber,
            changeType: 'added',
            effectiveDate: new Date(),
            changeHash: hash
          });
        }
        // Check if file has changed
        else if (previousHashes[file] !== hash) {
          updates.push({
            regulation: source.name,
            clauseNumber,
            changeType: 'modified',
            effectiveDate: new Date(),
            oldContent: previousHashes[file],
            newContent: hash,
            changeHash: hash
          });
        }
      }

      // Check for deleted files
      for (const file in previousHashes) {
        if (!currentHashes[file]) {
          updates.push({
            regulation: source.name,
            clauseNumber: file.replace('.html', ''),
            changeType: 'deleted',
            effectiveDate: new Date()
          });
        }
      }

      // Save current hashes
      fs.writeFileSync(hashFile, JSON.stringify(currentHashes, null, 2));
    }

    return updates;
  }

  /**
   * Process detected updates
   */
  private async processUpdates(updates: RegulationUpdate[]): Promise<void> {
    console.log(`Processing ${updates.length} regulation updates`);

    // Save update history
    this.updateHistory.push(...updates);
    this.saveUpdateHistory();

    // Create backup if configured
    if (this.config.backupBeforeUpdate) {
      await this.createBackup();
    }

    // Download and update files if auto-update is enabled
    if (this.config.autoUpdate) {
      for (const update of updates) {
        try {
          await this.downloadAndUpdateClause(update);
        } catch (error) {
          console.error(`Error updating ${update.regulation} ${update.clauseNumber}:`, error);
        }
      }
    }

    // Send notifications
    await this.sendUpdateNotifications(updates);

    // Generate update report
    await this.generateUpdateReport(updates);
  }

  /**
   * Download and update a specific clause
   */
  private async downloadAndUpdateClause(update: RegulationUpdate): Promise<void> {
    if (update.changeType === 'deleted') {
      // Archive deleted clause
      const filePath = path.join(this.regulationsPath, update.regulation, `${update.clauseNumber}.html`);
      const archivePath = path.join(this.regulationsPath, '.archive', update.regulation, `${update.clauseNumber}.html`);
      
      if (fs.existsSync(filePath)) {
        fs.mkdirSync(path.dirname(archivePath), { recursive: true });
        fs.renameSync(filePath, archivePath);
      }
      return;
    }

    // Construct URL for specific clause
    const clauseUrl = this.constructClauseUrl(update.regulation, update.clauseNumber);
    
    try {
      const response = await axios.get(clauseUrl, {
        timeout: 30000,
        headers: {
          'User-Agent': 'AIKO-Regulation-Monitor/1.0'
        }
      });

      const filePath = path.join(this.regulationsPath, update.regulation, `${update.clauseNumber}.html`);
      
      // Ensure directory exists
      fs.mkdirSync(path.dirname(filePath), { recursive: true });
      
      // Save updated content
      fs.writeFileSync(filePath, response.data);
      
      console.log(`Updated ${update.regulation} ${update.clauseNumber}`);
    } catch (error) {
      console.error(`Failed to download ${update.regulation} ${update.clauseNumber}:`, error);
      throw error;
    }
  }

  /**
   * Create backup of current regulations
   */
  private async createBackup(): Promise<string> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = path.join(this.regulationsPath, '.backups', `backup-${timestamp}`);
    
    console.log(`Creating backup at ${backupDir}`);
    
    // Copy all regulation directories
    for (const source of this.config.sources) {
      const sourceDir = path.join(this.regulationsPath, source.name);
      const backupSourceDir = path.join(backupDir, source.name);
      
      if (fs.existsSync(sourceDir)) {
        await this.copyDirectory(sourceDir, backupSourceDir);
      }
    }

    // Manage backup retention
    await this.cleanOldBackups();
    
    return backupDir;
  }

  /**
   * Send email notifications about updates
   */
  private async sendUpdateNotifications(updates: RegulationUpdate[]): Promise<void> {
    if (!this.config.notificationEmail || !this.emailTransporter) {
      return;
    }

    const subject = `AIKO Regulation Update Alert: ${updates.length} changes detected`;
    
    let html = `
      <h2>Regulation Updates Detected</h2>
      <p>${updates.length} changes were detected in the Federal Acquisition Regulations.</p>
      <h3>Summary of Changes:</h3>
      <table border="1" cellpadding="5" cellspacing="0">
        <tr>
          <th>Regulation</th>
          <th>Clause</th>
          <th>Change Type</th>
          <th>Effective Date</th>
          <th>Citation</th>
        </tr>
    `;

    for (const update of updates) {
      html += `
        <tr>
          <td>${update.regulation}</td>
          <td>${update.clauseNumber}</td>
          <td>${update.changeType}</td>
          <td>${update.effectiveDate.toLocaleDateString()}</td>
          <td>${update.federalRegisterCitation || 'N/A'}</td>
        </tr>
      `;
    }

    html += `
      </table>
      <p>Auto-update is ${this.config.autoUpdate ? 'ENABLED' : 'DISABLED'}.</p>
      <p>View full report at: ${path.join(this.regulationsPath, 'update-reports', 'latest.html')}</p>
    `;

    try {
      await this.emailTransporter.sendMail({
        from: '"AIKO Regulation Monitor" <aiko-monitor@example.com>',
        to: this.config.notificationEmail,
        subject,
        html
      });
      console.log('Update notification email sent');
    } catch (error) {
      console.error('Failed to send notification email:', error);
    }
  }

  /**
   * Generate detailed update report
   */
  private async generateUpdateReport(updates: RegulationUpdate[]): Promise<void> {
    const reportDir = path.join(this.regulationsPath, 'update-reports');
    fs.mkdirSync(reportDir, { recursive: true });

    const timestamp = new Date().toISOString();
    const reportPath = path.join(reportDir, `report-${timestamp.split('T')[0]}.html`);
    const latestPath = path.join(reportDir, 'latest.html');

    let html = `
<!DOCTYPE html>
<html>
<head>
  <title>AIKO Regulation Update Report - ${timestamp}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    table { border-collapse: collapse; width: 100%; margin-top: 20px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    .added { background-color: #d4edda; }
    .modified { background-color: #fff3cd; }
    .deleted { background-color: #f8d7da; }
    .summary { background-color: #d1ecf1; padding: 15px; border-radius: 5px; margin: 20px 0; }
  </style>
</head>
<body>
  <h1>AIKO Regulation Update Report</h1>
  <p><strong>Generated:</strong> ${new Date(timestamp).toLocaleString()}</p>
  
  <div class="summary">
    <h2>Summary</h2>
    <ul>
      <li>Total Changes: ${updates.length}</li>
      <li>Added: ${updates.filter(u => u.changeType === 'added').length}</li>
      <li>Modified: ${updates.filter(u => u.changeType === 'modified').length}</li>
      <li>Deleted: ${updates.filter(u => u.changeType === 'deleted').length}</li>
    </ul>
  </div>

  <h2>Detailed Changes</h2>
  <table>
    <thead>
      <tr>
        <th>Regulation</th>
        <th>Clause Number</th>
        <th>Change Type</th>
        <th>Effective Date</th>
        <th>Federal Register</th>
        <th>Action Taken</th>
      </tr>
    </thead>
    <tbody>
`;

    for (const update of updates) {
      const rowClass = update.changeType;
      const actionTaken = this.config.autoUpdate ? 'Updated' : 'Pending Manual Update';
      
      html += `
      <tr class="${rowClass}">
        <td>${update.regulation}</td>
        <td>${update.clauseNumber}</td>
        <td>${update.changeType}</td>
        <td>${update.effectiveDate.toLocaleDateString()}</td>
        <td>${update.federalRegisterCitation || 'N/A'}</td>
        <td>${actionTaken}</td>
      </tr>
`;
    }

    html += `
    </tbody>
  </table>

  <h2>Next Steps</h2>
  <ul>
    <li>Review all changes for impact on current contracts</li>
    <li>Update clause selection logic if new clauses added</li>
    <li>Verify clause text accuracy after updates</li>
    <li>Update any cached clause data</li>
  </ul>

  <h2>Update History</h2>
  <p>Total updates tracked: ${this.updateHistory.length}</p>
  <p>Monitoring since: ${this.updateHistory[0]?.effectiveDate.toLocaleDateString() || 'N/A'}</p>
</body>
</html>
`;

    // Save report
    fs.writeFileSync(reportPath, html);
    fs.writeFileSync(latestPath, html);
    
    console.log(`Update report generated: ${reportPath}`);
  }

  /**
   * Helper methods
   */
  
  private calculateHash(content: string): string {
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  private determineChangeType(description: string): 'added' | 'modified' | 'deleted' {
    const lowerDesc = description.toLowerCase();
    if (lowerDesc.includes('new') || lowerDesc.includes('add')) return 'added';
    if (lowerDesc.includes('delete') || lowerDesc.includes('remove')) return 'deleted';
    return 'modified';
  }

  private extractDate(text: string): Date {
    // Try multiple date formats
    const datePatterns = [
      /(\d{1,2}\/\d{1,2}\/\d{4})/,
      /(\w+ \d{1,2}, \d{4})/,
      /(\d{4}-\d{2}-\d{2})/
    ];

    for (const pattern of datePatterns) {
      const match = text.match(pattern);
      if (match) {
        const date = new Date(match[1]);
        if (!isNaN(date.getTime())) {
          return date;
        }
      }
    }

    return new Date();
  }

  private extractFederalRegisterCitation(text: string): string | undefined {
    const frPattern = /(\d{2,3} FR \d{4,6})/;
    const match = text.match(frPattern);
    return match ? match[1] : undefined;
  }

  private constructClauseUrl(regulation: string, clauseNumber: string): string {
    // Map regulation to base URL pattern
    const baseUrls: Record<string, string> = {
      'FAR': `https://www.acquisition.gov/far/`,
      'DFARS': `https://www.acquisition.gov/dfars/`,
      'DFARS_PGI': `https://www.acquisition.gov/dfarspgi/`
    };

    const base = baseUrls[regulation] || baseUrls['FAR'];
    return `${base}${clauseNumber}`;
  }

  private async copyDirectory(src: string, dest: string): Promise<void> {
    fs.mkdirSync(dest, { recursive: true });
    
    const entries = fs.readdirSync(src, { withFileTypes: true });
    
    for (const entry of entries) {
      const srcPath = path.join(src, entry.name);
      const destPath = path.join(dest, entry.name);
      
      if (entry.isDirectory()) {
        await this.copyDirectory(srcPath, destPath);
      } else {
        fs.copyFileSync(srcPath, destPath);
      }
    }
  }

  private async cleanOldBackups(): Promise<void> {
    const backupRoot = path.join(this.regulationsPath, '.backups');
    
    if (!fs.existsSync(backupRoot)) {
      return;
    }

    const backups = fs.readdirSync(backupRoot)
      .filter(f => f.startsWith('backup-'))
      .sort()
      .reverse();

    // Keep only the configured number of backups
    const backupsToDelete = backups.slice(this.config.maxBackups);
    
    for (const backup of backupsToDelete) {
      const backupPath = path.join(backupRoot, backup);
      console.log(`Deleting old backup: ${backup}`);
      fs.rmSync(backupPath, { recursive: true, force: true });
    }
  }

  private loadUpdateHistory(): void {
    const historyPath = path.join(this.regulationsPath, '.update-history.json');
    
    if (fs.existsSync(historyPath)) {
      const data = JSON.parse(fs.readFileSync(historyPath, 'utf-8'));
      this.updateHistory = data.map((u: any) => ({
        ...u,
        effectiveDate: new Date(u.effectiveDate)
      }));
    }
  }

  private saveUpdateHistory(): void {
    const historyPath = path.join(this.regulationsPath, '.update-history.json');
    fs.writeFileSync(historyPath, JSON.stringify(this.updateHistory, null, 2));
  }

  private saveConfig(): void {
    const configPath = path.join(this.regulationsPath, '.monitor-config.json');
    fs.writeFileSync(configPath, JSON.stringify(this.config, null, 2));
  }

  private initializeEmailNotifications(): void {
    if (this.config.notificationEmail) {
      // Configure email transporter (example using Gmail)
      this.emailTransporter = nodemailer.createTransporter({
        service: 'gmail',
        auth: {
          user: process.env.AIKO_EMAIL_USER,
          pass: process.env.AIKO_EMAIL_PASS
        }
      });
    }
  }

  /**
   * Manual update check command
   */
  async checkNow(): Promise<RegulationUpdate[]> {
    console.log('Running manual update check...');
    return await this.checkForUpdates();
  }

  /**
   * Get update history
   */
  getUpdateHistory(limit?: number): RegulationUpdate[] {
    const history = [...this.updateHistory].reverse();
    return limit ? history.slice(0, limit) : history;
  }

  /**
   * Get last check timestamp for a source
   */
  getLastCheckTime(sourceName: string): Date | undefined {
    const source = this.config.sources.find(s => s.name === sourceName);
    return source?.lastChecked;
  }
}

// Export singleton instance
export const regulationMonitor = new RegulationUpdateMonitor();

// Export default for easier imports
export default regulationMonitor;