/**
 * Clause Selection Engine for AIKO
 * Automatically selects FAR/DFAR clauses based on contract attributes
 */

import clauseDatabase from './ClauseDatabase.json';

// Contract attribute interfaces
export interface ContractAttributes {
  // Basic Information
  contractType: 'FIXED_PRICE' | 'COST_REIMBURSEMENT' | 'TIME_AND_MATERIALS' | 'LABOR_HOUR' | 'INDEFINITE_DELIVERY';
  contractValue: number;
  requirementType: 'SUPPLIES' | 'SERVICES' | 'CONSTRUCTION' | 'ARCHITECT_ENGINEERING' | 'INFORMATION_TECHNOLOGY' | 'RESEARCH_DEVELOPMENT';
  agency: string;
  
  // Contract Details
  performancePeriod: number; // in days
  placeOfPerformance: string;
  commercialItem: boolean;
  smallBusinessSetAside: boolean;
  isSmallBusiness: boolean;
  
  // Special Conditions
  hasOptions: boolean;
  optionPeriods?: number;
  optionNotificationDays?: number;
  governmentPropertyProvided: boolean;
  internationalTransport: boolean;
  workPerformedInUS: boolean;
  subcontractingExpected: boolean;
  certifiedCostPricingDataRequired: boolean;
  
  // Additional Flags
  requiresSecurityClearance: boolean;
  involvesIT: boolean;
  hasPersonalData: boolean;
  exportControlled: boolean;
  serviceType?: string;
  includesCoveredDefenseInfo?: boolean;
  oceanTransportRequired?: boolean;
  fullyFunded?: boolean;
}

export interface ClauseSelectionResult {
  mandatoryClauses: string[];
  conditionalClauses: string[];
  optionalClauses: string[];
  excludedClauses: string[];
  fillInRequirements: Record<string, any>;
  validationErrors: string[];
  validationWarnings: string[];
}

export class ClauseSelectionEngine {
  private database: any;
  private selectedClauses: Set<string>;
  private excludedClauses: Set<string>;
  private fillInRequirements: Record<string, any>;
  private validationErrors: string[];
  private validationWarnings: string[];

  constructor() {
    this.database = clauseDatabase;
    this.selectedClauses = new Set();
    this.excludedClauses = new Set();
    this.fillInRequirements = {};
    this.validationErrors = [];
    this.validationWarnings = [];
  }

  /**
   * Main method to select clauses based on contract attributes
   */
  selectClauses(attributes: ContractAttributes): ClauseSelectionResult {
    // Reset for new selection
    this.reset();

    // Step 1: Add universal mandatory clauses
    this.addUniversalClauses();

    // Step 2: Add threshold-based clauses
    this.addThresholdBasedClauses(attributes);

    // Step 3: Add contract type specific clauses
    this.addContractTypeSpecificClauses(attributes);

    // Step 4: Add requirement type specific clauses
    this.addRequirementTypeSpecificClauses(attributes);

    // Step 5: Add conditional clauses
    this.addConditionalClauses(attributes);

    // Step 6: Handle commercial item rules
    if (attributes.commercialItem) {
      this.applyCommercialItemRules();
    }

    // Step 7: Add agency-specific clauses
    this.addAgencySpecificClauses(attributes);

    // Step 8: Process fill-in requirements
    this.processFillInRequirements(attributes);

    // Step 9: Validate selection
    this.validateSelection(attributes);

    // Return categorized results
    return this.categorizeResults();
  }

  private reset(): void {
    this.selectedClauses.clear();
    this.excludedClauses.clear();
    this.fillInRequirements = {};
    this.validationErrors = [];
    this.validationWarnings = [];
  }

  private addUniversalClauses(): void {
    // Clauses that apply to all contracts
    const universalClauses = [
      '52.202-1',  // Definitions
      '52.203-3',  // Gratuities
      '52.232-33', // Payment by EFT
      '52.233-1',  // Disputes
      '52.233-4',  // Applicable Law
      '52.252-2',  // Clauses Incorporated by Reference
      '52.223-18', // Encouraging Contractor Policies to Ban Text Messaging
      '52.222-50', // Combating Trafficking in Persons
      '52.232-17', // Interest
      '52.244-6',  // Subcontracts for Commercial Products
      '52.225-13'  // Restrictions on Certain Foreign Purchases
    ];

    universalClauses.forEach(clause => this.selectedClauses.add(clause));
  }

  private addThresholdBasedClauses(attributes: ContractAttributes): void {
    const { contractValue } = attributes;
    const thresholds = this.database.clauseLogic.thresholds;

    // Over micro-purchase threshold
    if (contractValue > thresholds.microPurchase) {
      this.selectedClauses.add('52.204-7');   // SAM
      this.selectedClauses.add('52.222-21');  // Prohibition of Segregated Facilities
      this.selectedClauses.add('52.222-26');  // Equal Opportunity
      this.selectedClauses.add('52.222-40');  // Notification of Employee Rights
      this.selectedClauses.add('52.223-6');   // Drug-Free Workplace
    }

    // Over $15,000
    if (contractValue > 15000) {
      this.selectedClauses.add('52.222-36');  // Equal Opportunity for Workers with Disabilities
    }

    // Over $30,000
    if (contractValue > 30000) {
      this.selectedClauses.add('52.204-10');  // Reporting Executive Compensation
      
      if (!attributes.commercialItem) {
        this.selectedClauses.add('52.233-3'); // Protest After Award
      }
    }

    // Over $35,000
    if (contractValue > 35000) {
      this.selectedClauses.add('52.209-6');   // Protecting Government's Interest (Debarment)
    }

    // Over simplified acquisition threshold
    if (contractValue > thresholds.simplifiedAcquisition) {
      this.selectedClauses.add('52.203-5');   // Covenant Against Contingent Fees
      this.selectedClauses.add('52.203-6');   // Restrictions on Subcontractor Sales
      this.selectedClauses.add('52.203-7');   // Anti-Kickback Procedures
      this.selectedClauses.add('52.203-12');  // Limitation on Payments to Influence
      this.selectedClauses.add('52.222-35');  // Equal Opportunity for Veterans
      this.selectedClauses.add('52.222-37');  // Employment Reports on Veterans
      this.selectedClauses.add('52.219-28');  // Post-Award Small Business Program

      if (!attributes.smallBusinessSetAside) {
        this.selectedClauses.add('52.219-8'); // Utilization of Small Business Concerns
      }

      // Employment Eligibility Verification
      if (attributes.workPerformedInUS && attributes.performancePeriod > 120) {
        this.selectedClauses.add('52.222-54');
      }
    }

    // Over $750,000
    if (contractValue > 750000 && !attributes.isSmallBusiness && attributes.subcontractingExpected) {
      this.selectedClauses.add('52.219-9');   // Small Business Subcontracting Plan
    }

    // Over $2 million
    if (contractValue > thresholds.truthInNegotiations) {
      if (attributes.certifiedCostPricingDataRequired) {
        this.selectedClauses.add('52.215-10'); // Price Reduction for Defective Cost Data
        this.selectedClauses.add('52.215-12'); // Subcontractor Cost or Pricing Data
      }
    }

    // Cost Accounting Standards
    if (contractValue > thresholds.costAccountingStandards && !attributes.commercialItem) {
      this.selectedClauses.add('52.230-2');   // Cost Accounting Standards
    }
  }

  private addContractTypeSpecificClauses(attributes: ContractAttributes): void {
    switch (attributes.contractType) {
      case 'FIXED_PRICE':
        this.selectedClauses.add('52.232-25'); // Prompt Payment
        this.selectedClauses.add('52.243-1');  // Changes - Fixed-Price
        this.selectedClauses.add('52.249-2');  // Termination for Convenience
        
        if (attributes.contractValue > this.database.clauseLogic.thresholds.simplifiedAcquisition) {
          this.selectedClauses.add('52.249-8'); // Default
        }
        break;

      case 'COST_REIMBURSEMENT':
        this.selectedClauses.add('52.216-7');  // Allowable Cost and Payment
        this.selectedClauses.add('52.244-2');  // Subcontracts
        this.selectedClauses.add('52.215-2');  // Audit and Records - Negotiation
        
        if (attributes.fullyFunded) {
          this.selectedClauses.add('52.232-20'); // Limitation of Cost
        } else {
          this.selectedClauses.add('52.232-22'); // Limitation of Funds
        }
        break;

      case 'TIME_AND_MATERIALS':
      case 'LABOR_HOUR':
        this.selectedClauses.add('52.232-7');  // Payments under T&M and LH Contracts
        this.selectedClauses.add('52.244-2');  // Subcontracts
        break;

      case 'INDEFINITE_DELIVERY':
        // Add IDIQ specific clauses
        this.selectedClauses.add('52.216-18'); // Ordering
        this.selectedClauses.add('52.216-19'); // Order Limitations
        this.selectedClauses.add('52.216-22'); // Indefinite Quantity
        break;
    }
  }

  private addRequirementTypeSpecificClauses(attributes: ContractAttributes): void {
    switch (attributes.requirementType) {
      case 'CONSTRUCTION':
        const constructionClauses = [
          '52.236-2',  // Differing Site Conditions
          '52.236-3',  // Site Investigation
          '52.236-5',  // Material and Workmanship
          '52.236-7',  // Permits and Responsibilities
          '52.236-13', // Accident Prevention
          '52.236-15'  // Schedules for Construction
        ];
        constructionClauses.forEach(clause => this.selectedClauses.add(clause));
        break;

      case 'SERVICES':
        if (attributes.contractValue > 2500) {
          this.selectedClauses.add('52.222-41'); // Service Contract Labor Standards
        }
        
        if (attributes.contractType === 'FIXED_PRICE') {
          this.selectedClauses.add('52.246-4'); // Inspection of Services - Fixed Price
        }
        break;

      case 'SUPPLIES':
        if (attributes.contractType === 'FIXED_PRICE') {
          this.selectedClauses.add('52.246-2'); // Inspection of Supplies - Fixed Price
        }
        
        if (!attributes.commercialItem) {
          this.selectedClauses.add('52.225-1'); // Buy American - Supplies
        }
        break;

      case 'RESEARCH_DEVELOPMENT':
        this.selectedClauses.add('52.227-14'); // Rights in Data - General
        break;

      case 'INFORMATION_TECHNOLOGY':
        if (attributes.hasPersonalData) {
          this.selectedClauses.add('52.224-1'); // Privacy Act Notification
          this.selectedClauses.add('52.224-2'); // Privacy Act
        }
        break;
    }
  }

  private addConditionalClauses(attributes: ContractAttributes): void {
    // Options
    if (attributes.hasOptions) {
      if (attributes.requirementType === 'SERVICES') {
        this.selectedClauses.add('52.217-8'); // Option to Extend Services
      }
      this.selectedClauses.add('52.217-9');   // Option to Extend Term
    }

    // Government Property
    if (attributes.governmentPropertyProvided) {
      this.selectedClauses.add('52.245-1');   // Government Property
      this.selectedClauses.add('52.245-9');   // Use and Charges
    }

    // Transportation
    if (attributes.internationalTransport) {
      this.selectedClauses.add('52.247-63');  // Preference for U.S.-Flag Air Carriers
    }
    
    if (attributes.oceanTransportRequired) {
      this.selectedClauses.add('52.247-64');  // Preference for U.S.-Flag Vessels
    }

    // Stop-Work Order
    if (attributes.contractValue > this.database.clauseLogic.thresholds.simplifiedAcquisition) {
      this.selectedClauses.add('52.242-13');  // Stop-Work Order
    }

    // Value Engineering
    if (attributes.contractValue > this.database.clauseLogic.thresholds.simplifiedAcquisition) {
      this.selectedClauses.add('52.248-1');   // Value Engineering
    }

    // Availability of Funds
    if (!attributes.fullyFunded) {
      this.selectedClauses.add('52.232-18');  // Availability of Funds
    }
  }

  private applyCommercialItemRules(): void {
    // For commercial items, use simplified clauses
    this.selectedClauses.add('52.212-4');     // Contract Terms - Commercial
    this.selectedClauses.add('52.212-5');     // Required Clauses - Commercial

    // Exclude many standard clauses
    const commercialExclusions = [
      '52.203-3',   // Gratuities
      '52.222-3',   // Convict Labor
      '52.215-2',   // Audit and Records
      '52.223-6',   // Drug-Free Workplace (under SAT)
      '52.233-3'    // Protest After Award
    ];

    commercialExclusions.forEach(clause => {
      this.selectedClauses.delete(clause);
      this.excludedClauses.add(clause);
    });
  }

  private addAgencySpecificClauses(attributes: ContractAttributes): void {
    if (attributes.agency === 'DOD') {
      // Basic DOD clauses
      this.selectedClauses.add('252.232-7003'); // Electronic Submission of Payment

      if (attributes.contractValue > this.database.clauseLogic.thresholds.simplifiedAcquisition) {
        this.selectedClauses.add('252.203-7001'); // Prohibition on Persons Convicted
      }

      if (attributes.includesCoveredDefenseInfo || attributes.involvesIT) {
        this.selectedClauses.add('252.204-7012'); // Safeguarding Covered Defense Info
      }

      if (attributes.requirementType === 'SUPPLIES') {
        this.selectedClauses.add('252.225-7001'); // Buy American Balance of Payments
        this.selectedClauses.add('252.225-7002'); // Qualifying Country Sources
      }

      if (attributes.oceanTransportRequired) {
        this.selectedClauses.add('252.247-7023'); // Transportation of Supplies by Sea
      }
    }
  }

  private processFillInRequirements(attributes: ContractAttributes): void {
    this.selectedClauses.forEach(clauseNumber => {
      const clauseData = this.database.clauses[clauseNumber] || 
                        this.database.commercialItemClauses[clauseNumber] ||
                        this.database.constructionClauses[clauseNumber] ||
                        this.database.dfarClauses[clauseNumber];

      if (clauseData && clauseData.fillIns && clauseData.fillIns.length > 0) {
        this.fillInRequirements[clauseNumber] = this.generateFillIns(clauseNumber, attributes);
      }
    });
  }

  private generateFillIns(clauseNumber: string, attributes: ContractAttributes): any {
    const fillIns: any = {};

    switch (clauseNumber) {
      case '52.217-8': // Option to Extend Services
      case '52.217-9': // Option to Extend Term
        fillIns.OPTION_PERIOD = attributes.optionPeriods || '1 year';
        fillIns.NOTIFICATION_DAYS = attributes.optionNotificationDays || 30;
        break;

      case '52.222-41': // Service Contract Labor Standards
        fillIns.WAGE_DETERMINATION_NUMBER = `${attributes.placeOfPerformance}-${attributes.serviceType || 'GENERAL'}-${new Date().getFullYear()}`;
        fillIns.WAGE_DETERMINATION_DATE = new Date().toISOString().split('T')[0];
        break;

      case '52.219-9': // Small Business Subcontracting Plan
        fillIns.SMALL_BUSINESS_GOAL = '23%';
        fillIns.SMALL_DISADVANTAGED_GOAL = '5%';
        fillIns.WOSB_GOAL = '5%';
        fillIns.HUBZONE_GOAL = '3%';
        fillIns.VETERAN_GOAL = '3%';
        fillIns.SDVOSB_GOAL = '3%';
        break;

      case '52.227-14': // Rights in Data - General
        // Determine appropriate alternate based on requirement type
        if (attributes.requirementType === 'RESEARCH_DEVELOPMENT') {
          fillIns.ALTERNATE = 'IV';
        } else {
          fillIns.ALTERNATE = 'I';
        }
        break;

      case '52.243-1': // Changes - Fixed-Price
        // Select alternate based on requirement type
        if (attributes.requirementType === 'SUPPLIES') {
          fillIns.ALTERNATE = 'I';
        } else if (attributes.requirementType === 'SERVICES') {
          fillIns.ALTERNATE = 'II';
        } else if (attributes.requirementType === 'CONSTRUCTION') {
          fillIns.ALTERNATE = 'IV';
        }
        break;
    }

    return fillIns;
  }

  private validateSelection(attributes: ContractAttributes): void {
    // Check for conflicting clauses
    if (this.selectedClauses.has('52.232-20') && this.selectedClauses.has('52.232-22')) {
      this.validationErrors.push('Cannot include both Limitation of Cost (52.232-20) and Limitation of Funds (52.232-22)');
    }

    // Check commercial item conflicts
    if (attributes.commercialItem) {
      const nonCommercialClauses = Array.from(this.selectedClauses).filter(clause => 
        this.isNonCommercialClause(clause)
      );

      if (nonCommercialClauses.length > 0) {
        this.validationWarnings.push(
          `Commercial contracts should not include: ${nonCommercialClauses.join(', ')}`
        );
      }
    }

    // Check for missing critical clauses
    if (attributes.requirementType === 'SERVICES' && 
        attributes.contractValue > 2500 && 
        !this.selectedClauses.has('52.222-41')) {
      this.validationErrors.push('Missing required Service Contract Labor Standards clause (52.222-41)');
    }

    // Validate fill-in requirements
    Object.entries(this.fillInRequirements).forEach(([clause, fillIns]) => {
      if (!fillIns || Object.keys(fillIns).length === 0) {
        this.validationWarnings.push(`Clause ${clause} requires fill-in values that need to be provided`);
      }
    });
  }

  private isNonCommercialClause(clauseNumber: string): boolean {
    const nonCommercialClauses = [
      '52.203-3', '52.222-3', '52.215-2', '52.223-6', '52.233-3',
      '52.215-10', '52.215-12', '52.230-2'
    ];
    return nonCommercialClauses.includes(clauseNumber);
  }

  private categorizeResults(): ClauseSelectionResult {
    const allClauses = Array.from(this.selectedClauses);
    const mandatoryClauses: string[] = [];
    const conditionalClauses: string[] = [];
    const optionalClauses: string[] = [];

    // Categorize clauses based on their requirements
    allClauses.forEach(clauseNumber => {
      const clauseData = this.getClauseData(clauseNumber);
      
      if (clauseData && clauseData.applicability) {
        if (clauseData.applicability.required === true) {
          mandatoryClauses.push(clauseNumber);
        } else if (clauseData.applicability.required === false) {
          optionalClauses.push(clauseNumber);
        } else {
          conditionalClauses.push(clauseNumber);
        }
      } else {
        mandatoryClauses.push(clauseNumber); // Default to mandatory if not specified
      }
    });

    return {
      mandatoryClauses: mandatoryClauses.sort(),
      conditionalClauses: conditionalClauses.sort(),
      optionalClauses: optionalClauses.sort(),
      excludedClauses: Array.from(this.excludedClauses).sort(),
      fillInRequirements: this.fillInRequirements,
      validationErrors: this.validationErrors,
      validationWarnings: this.validationWarnings
    };
  }

  private getClauseData(clauseNumber: string): any {
    return this.database.clauses[clauseNumber] || 
           this.database.commercialItemClauses[clauseNumber] ||
           this.database.constructionClauses[clauseNumber] ||
           this.database.dfarClauses[clauseNumber];
  }

  /**
   * Get clause title and prescription reference
   */
  getClauseInfo(clauseNumber: string): { title: string; prescription: string } | null {
    const clauseData = this.getClauseData(clauseNumber);
    
    if (clauseData) {
      return {
        title: clauseData.title,
        prescription: clauseData.prescription
      };
    }
    
    return null;
  }

  /**
   * Export selected clauses as formatted text
   */
  exportClausesAsText(selectedClauses: string[]): string {
    let output = 'CONTRACT CLAUSES\n\n';
    
    selectedClauses.forEach(clauseNumber => {
      const info = this.getClauseInfo(clauseNumber);
      if (info) {
        output += `${clauseNumber} ${info.title} (${info.prescription})\n`;
      }
    });
    
    return output;
  }
}

// Export a singleton instance
export const clauseEngine = new ClauseSelectionEngine();