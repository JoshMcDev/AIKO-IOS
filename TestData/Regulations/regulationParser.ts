/**
 * Regulation Parser for AIKO
 * Parses and searches FAR/DFAR HTML regulation files
 */

import * as fs from 'fs';
import * as path from 'path';
import { JSDOM } from 'jsdom';

export interface RegulationContent {
  regulation: string;
  part: string;
  section: string;
  title: string;
  text: string;
  htmlContent: string;
  prescription?: string;
  clauseNumber?: string;
}

export class RegulationParser {
  private regulationsPath: string;
  private cache: Map<string, RegulationContent>;

  constructor(regulationsPath: string = '/Users/J/aiko/Sources/Resources/Regulations') {
    this.regulationsPath = regulationsPath;
    this.cache = new Map();
  }

  /**
   * Get the full text of a specific clause or section
   */
  async getClauseText(regulation: string, clauseNumber: string): Promise<RegulationContent | null> {
    const cacheKey = `${regulation}:${clauseNumber}`;
    
    // Check cache first
    if (this.cache.has(cacheKey)) {
      return this.cache.get(cacheKey)!;
    }

    // Convert clause number to filename
    const filename = `${clauseNumber}.html`;
    const filePath = path.join(this.regulationsPath, regulation, filename);

    try {
      const htmlContent = await fs.promises.readFile(filePath, 'utf-8');
      const dom = new JSDOM(htmlContent);
      const document = dom.window.document;

      // Extract title
      const titleElement = document.querySelector('h1, h2, h3');
      const title = titleElement?.textContent?.trim() || '';

      // Extract main content
      const contentElement = document.querySelector('body');
      const text = contentElement?.textContent?.trim() || '';

      // Parse clause details
      const parts = clauseNumber.split('.');
      const result: RegulationContent = {
        regulation,
        part: parts[0],
        section: clauseNumber,
        title,
        text,
        htmlContent,
        clauseNumber
      };

      // Look for prescription reference
      const prescriptionMatch = text.match(/prescribed in ([0-9.]+)/i);
      if (prescriptionMatch) {
        result.prescription = prescriptionMatch[1];
      }

      // Cache the result
      this.cache.set(cacheKey, result);
      
      return result;
    } catch (error) {
      console.error(`Error reading clause ${clauseNumber} from ${regulation}:`, error);
      return null;
    }
  }

  /**
   * Search regulations for specific text
   */
  async searchRegulations(
    searchTerm: string, 
    regulations: string[] = ['FAR', 'DFARS'],
    options: { caseSensitive?: boolean; wholeWord?: boolean } = {}
  ): Promise<RegulationContent[]> {
    const results: RegulationContent[] = [];
    const { caseSensitive = false, wholeWord = false } = options;

    for (const regulation of regulations) {
      const regulationPath = path.join(this.regulationsPath, regulation);
      
      try {
        const files = await fs.promises.readdir(regulationPath);
        const htmlFiles = files.filter(f => f.endsWith('.html'));

        for (const file of htmlFiles) {
          const filePath = path.join(regulationPath, file);
          const content = await fs.promises.readFile(filePath, 'utf-8');
          
          let searchContent = content;
          let searchPattern = searchTerm;
          
          if (!caseSensitive) {
            searchContent = content.toLowerCase();
            searchPattern = searchTerm.toLowerCase();
          }

          if (wholeWord) {
            const regex = new RegExp(`\\b${searchPattern}\\b`);
            if (!regex.test(searchContent)) continue;
          } else {
            if (!searchContent.includes(searchPattern)) continue;
          }

          // Parse the matching file
          const clauseNumber = file.replace('.html', '');
          const clauseContent = await this.getClauseText(regulation, clauseNumber);
          
          if (clauseContent) {
            results.push(clauseContent);
          }
        }
      } catch (error) {
        console.error(`Error searching ${regulation}:`, error);
      }
    }

    return results;
  }

  /**
   * Get all clauses for a specific FAR/DFAR part
   */
  async getClausesByPart(regulation: string, part: string): Promise<RegulationContent[]> {
    const results: RegulationContent[] = [];
    const regulationPath = path.join(this.regulationsPath, regulation);

    try {
      const files = await fs.promises.readdir(regulationPath);
      const partFiles = files.filter(f => f.startsWith(`${part}.`) && f.endsWith('.html'));

      for (const file of partFiles) {
        const clauseNumber = file.replace('.html', '');
        const clauseContent = await this.getClauseText(regulation, clauseNumber);
        
        if (clauseContent) {
          results.push(clauseContent);
        }
      }
    } catch (error) {
      console.error(`Error getting clauses for ${regulation} Part ${part}:`, error);
    }

    return results.sort((a, b) => a.section.localeCompare(b.section, undefined, { numeric: true }));
  }

  /**
   * Extract all provisions (solicitation clauses) from Part 52
   */
  async getAllProvisions(regulation: string = 'FAR'): Promise<RegulationContent[]> {
    const part52Clauses = await this.getClausesByPart(regulation, '52');
    
    // Provisions typically have titles containing "Provision" or are in specific ranges
    return part52Clauses.filter(clause => {
      const title = clause.title.toLowerCase();
      return title.includes('provision') || 
             title.includes('notice') ||
             title.includes('instructions') ||
             title.includes('representation') ||
             title.includes('certification');
    });
  }

  /**
   * Get all contract clauses (non-provisions) from Part 52
   */
  async getAllContractClauses(regulation: string = 'FAR'): Promise<RegulationContent[]> {
    const part52Clauses = await this.getClausesByPart(regulation, '52');
    const provisions = await this.getAllProvisions(regulation);
    const provisionNumbers = new Set(provisions.map(p => p.clauseNumber));
    
    return part52Clauses.filter(clause => !provisionNumbers.has(clause.clauseNumber));
  }

  /**
   * Validate if a clause reference exists
   */
  async validateClauseReference(regulation: string, clauseNumber: string): Promise<boolean> {
    const clause = await this.getClauseText(regulation, clauseNumber);
    return clause !== null;
  }

  /**
   * Get clause prescription (where it's prescribed in the FAR)
   */
  async getClausePrescription(regulation: string, clauseNumber: string): Promise<string | null> {
    const clause = await this.getClauseText(regulation, clauseNumber);
    
    if (!clause) return null;

    // Look for prescription in the text
    const prescriptionMatch = clause.text.match(/prescribed in ([0-9.]+)/i);
    if (prescriptionMatch) {
      return prescriptionMatch[1];
    }

    // For Part 52 clauses, check the corresponding prescription section
    if (clauseNumber.startsWith('52.')) {
      const prescriptionSection = clauseNumber.replace('52.2', '').replace('52.', '');
      const prescriptionClause = await this.getClauseText(regulation, prescriptionSection);
      
      if (prescriptionClause) {
        return prescriptionSection;
      }
    }

    return null;
  }

  /**
   * Extract fill-in requirements from clause text
   */
  extractFillIns(clauseContent: RegulationContent): string[] {
    const fillIns: string[] = [];
    const text = clauseContent.text;

    // Common patterns for fill-ins
    const patterns = [
      /\[([A-Z_\s]+)\]/g,                    // [CONTRACTING OFFICER]
      /_{3,}/g,                              // _______
      /\(Insert[^)]+\)/gi,                   // (Insert ...)
      /\bContracting Officer shall insert\b/gi,
      /\binsert the following\b/gi
    ];

    patterns.forEach(pattern => {
      const matches = text.matchAll(pattern);
      for (const match of matches) {
        if (match[1]) {
          fillIns.push(match[1]);
        }
      }
    });

    // Remove duplicates
    return [...new Set(fillIns)];
  }

  /**
   * Get related clauses (cross-references)
   */
  async getRelatedClauses(clauseContent: RegulationContent): Promise<string[]> {
    const relatedClauses: string[] = [];
    const text = clauseContent.text;

    // Pattern to match clause references (e.g., 52.217-8, 252.225-7001)
    const clausePattern = /\b(52\.\d{3}-\d+|252\.\d{3}-\d{4})\b/g;
    const matches = text.matchAll(clausePattern);

    for (const match of matches) {
      if (match[1] !== clauseContent.clauseNumber) {
        relatedClauses.push(match[1]);
      }
    }

    return [...new Set(relatedClauses)];
  }

  /**
   * Build a clause dependency tree
   */
  async buildClauseDependencyTree(
    regulation: string, 
    clauseNumber: string, 
    maxDepth: number = 3
  ): Promise<any> {
    const visited = new Set<string>();
    
    const buildTree = async (clauseNum: string, depth: number): Promise<any> => {
      if (depth > maxDepth || visited.has(clauseNum)) {
        return null;
      }
      
      visited.add(clauseNum);
      
      const clause = await this.getClauseText(regulation, clauseNum);
      if (!clause) return null;

      const relatedClauses = await this.getRelatedClauses(clause);
      const children = [];

      for (const related of relatedClauses) {
        const child = await buildTree(related, depth + 1);
        if (child) {
          children.push(child);
        }
      }

      return {
        clauseNumber: clauseNum,
        title: clause.title,
        prescription: clause.prescription,
        children
      };
    };

    return buildTree(clauseNumber, 0);
  }

  /**
   * Clear the cache
   */
  clearCache(): void {
    this.cache.clear();
  }
}

// Export singleton instance
export const regulationParser = new RegulationParser();