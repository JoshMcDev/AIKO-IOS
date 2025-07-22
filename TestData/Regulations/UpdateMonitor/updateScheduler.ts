/**
 * Update Scheduler for AIKO Regulation Monitor
 * Manages scheduled checks and provides CLI interface
 */

import { regulationMonitor } from './regulationUpdateMonitor';
import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';

// CLI Interface for manual control
const program = new Command();

program
  .name('aiko-regulation-monitor')
  .description('Monitor and update Federal Acquisition Regulations')
  .version('1.0.0');

program
  .command('start')
  .description('Start automatic monitoring')
  .option('-i, --interval <cron>', 'Cron interval (default: weekly)', '0 0 * * 1')
  .option('-e, --email <email>', 'Notification email address')
  .option('--auto-update', 'Enable automatic updates', false)
  .action(async (options) => {
    console.log('Starting AIKO Regulation Monitor...');
    
    // Configure monitor
    const config = {
      checkInterval: options.interval,
      notificationEmail: options.email,
      autoUpdate: options.autoUpdate
    };

    // Start monitoring
    regulationMonitor.startMonitoring();
    
    console.log('Monitor started with configuration:');
    console.log(JSON.stringify(config, null, 2));
  });

program
  .command('check')
  .description('Run manual update check')
  .option('--update', 'Apply updates if found', false)
  .action(async (options) => {
    console.log('Running manual regulation check...');
    
    const updates = await regulationMonitor.checkNow();
    
    if (updates.length === 0) {
      console.log('No updates found. Regulations are current.');
    } else {
      console.log(`Found ${updates.length} updates:`);
      updates.forEach(update => {
        console.log(`- ${update.regulation} ${update.clauseNumber}: ${update.changeType}`);
      });
      
      if (options.update) {
        console.log('Applying updates...');
        // Updates will be processed automatically by the monitor
      }
    }
  });

program
  .command('history')
  .description('Show update history')
  .option('-n, --number <count>', 'Number of entries to show', '10')
  .action((options) => {
    const history = regulationMonitor.getUpdateHistory(parseInt(options.number));
    
    if (history.length === 0) {
      console.log('No update history found.');
    } else {
      console.log('Recent regulation updates:');
      history.forEach(update => {
        console.log(`[${update.effectiveDate.toLocaleDateString()}] ${update.regulation} ${update.clauseNumber}: ${update.changeType}`);
      });
    }
  });

program
  .command('status')
  .description('Show monitor status')
  .action(() => {
    console.log('AIKO Regulation Monitor Status:');
    console.log('FAR last checked:', regulationMonitor.getLastCheckTime('FAR') || 'Never');
    console.log('DFARS last checked:', regulationMonitor.getLastCheckTime('DFARS') || 'Never');
    console.log('DFARS PGI last checked:', regulationMonitor.getLastCheckTime('DFARS_PGI') || 'Never');
  });

// Alternative: Webhook receiver for push notifications
import express from 'express';
import bodyParser from 'body-parser';

export class RegulationWebhookReceiver {
  private app: express.Application;
  private port: number;

  constructor(port: number = 3000) {
    this.port = port;
    this.app = express();
    this.setupRoutes();
  }

  private setupRoutes(): void {
    this.app.use(bodyParser.json());
    
    // Webhook endpoint for acquisition.gov notifications
    this.app.post('/webhook/regulation-update', async (req, res) => {
      console.log('Received regulation update webhook:', req.body);
      
      try {
        // Validate webhook signature (if implemented by acquisition.gov)
        if (!this.validateWebhookSignature(req)) {
          return res.status(401).json({ error: 'Invalid signature' });
        }

        // Process the update notification
        const update = this.parseWebhookPayload(req.body);
        
        if (update) {
          // Trigger immediate check for specific regulation
          await regulationMonitor.checkNow();
          
          res.status(200).json({ 
            status: 'success',
            message: 'Update notification received and processed'
          });
        } else {
          res.status(400).json({ error: 'Invalid payload format' });
        }
      } catch (error) {
        console.error('Webhook processing error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    });

    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.status(200).json({ 
        status: 'healthy',
        service: 'AIKO Regulation Monitor',
        lastCheck: regulationMonitor.getLastCheckTime('FAR')
      });
    });
  }

  private validateWebhookSignature(req: express.Request): boolean {
    // Implement signature validation if acquisition.gov provides it
    // For now, return true for development
    return true;
  }

  private parseWebhookPayload(payload: any): any {
    // Parse acquisition.gov webhook format
    // This would need to match their actual format
    if (payload.regulation && payload.changes) {
      return {
        regulation: payload.regulation,
        changes: payload.changes,
        effectiveDate: new Date(payload.effectiveDate)
      };
    }
    return null;
  }

  start(): void {
    this.app.listen(this.port, () => {
      console.log(`Webhook receiver listening on port ${this.port}`);
    });
  }
}

// Web scraper alternative using Puppeteer
import puppeteer from 'puppeteer';

export class RegulationScraper {
  private browser?: puppeteer.Browser;

  async initialize(): Promise<void> {
    this.browser = await puppeteer.launch({ 
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
  }

  async scrapeLatestUpdates(): Promise<any[]> {
    if (!this.browser) {
      await this.initialize();
    }

    const page = await this.browser!.newPage();
    const updates: any[] = [];

    try {
      // Scrape FAR updates
      await page.goto('https://www.acquisition.gov/far/current-rule-making', {
        waitUntil: 'networkidle2'
      });

      // Wait for content to load
      await page.waitForSelector('.rule-making-table, .updates-list', { timeout: 10000 });

      // Extract update information
      const farUpdates = await page.evaluate(() => {
        const updates: any[] = [];
        
        // Adjust selectors based on actual page structure
        document.querySelectorAll('.rule-making-item, .update-row').forEach(item => {
          const title = item.querySelector('.title')?.textContent || '';
          const date = item.querySelector('.date')?.textContent || '';
          const federalRegister = item.querySelector('.fr-citation')?.textContent || '';
          
          // Extract clause numbers
          const clauseMatches = title.match(/\b(52\.\d{3}-\d+)\b/g) || [];
          
          clauseMatches.forEach(clause => {
            updates.push({
              regulation: 'FAR',
              clauseNumber: clause,
              title,
              date,
              federalRegister
            });
          });
        });
        
        return updates;
      });

      updates.push(...farUpdates);

      // Scrape DFARS updates
      await page.goto('https://www.acquisition.gov/dfars/current-dfars-cases', {
        waitUntil: 'networkidle2'
      });

      const dfarsUpdates = await page.evaluate(() => {
        const updates: any[] = [];
        
        document.querySelectorAll('.dfars-case').forEach(item => {
          const caseNumber = item.querySelector('.case-number')?.textContent || '';
          const description = item.querySelector('.description')?.textContent || '';
          const status = item.querySelector('.status')?.textContent || '';
          
          // Extract clause numbers
          const clauseMatches = description.match(/\b(252\.\d{3}-\d{4})\b/g) || [];
          
          clauseMatches.forEach(clause => {
            updates.push({
              regulation: 'DFARS',
              clauseNumber: clause,
              caseNumber,
              description,
              status
            });
          });
        });
        
        return updates;
      });

      updates.push(...dfarsUpdates);

    } catch (error) {
      console.error('Error scraping regulation updates:', error);
    } finally {
      await page.close();
    }

    return updates;
  }

  async cleanup(): Promise<void> {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// GitHub Actions workflow generator
export function generateGitHubActionsWorkflow(): string {
  return `
name: Check Regulation Updates

on:
  schedule:
    # Run every Monday at 2 AM UTC
    - cron: '0 2 * * 1'
  workflow_dispatch:
    inputs:
      auto_update:
        description: 'Automatically apply updates'
        required: false
        default: 'false'

jobs:
  check-updates:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: |
        cd Sources/Resources/Regulations/UpdateMonitor
        npm install
        
    - name: Check for regulation updates
      run: |
        cd Sources/Resources/Regulations/UpdateMonitor
        npx ts-node updateScheduler.ts check
        
    - name: Apply updates (if enabled)
      if: github.event.inputs.auto_update == 'true'
      run: |
        cd Sources/Resources/Regulations/UpdateMonitor
        npx ts-node updateScheduler.ts check --update
        
    - name: Commit updates
      if: github.event.inputs.auto_update == 'true'
      run: |
        git config --local user.email "aiko-bot@example.com"
        git config --local user.name "AIKO Bot"
        git add Sources/Resources/Regulations/
        git commit -m "Auto-update: Federal Acquisition Regulations" || exit 0
        git push
        
    - name: Send notification
      if: always()
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: 'Regulation update check completed'
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
`;
}

// Export CLI if run directly
if (require.main === module) {
  program.parse(process.argv);
}