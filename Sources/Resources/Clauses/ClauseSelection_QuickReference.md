# CLAUSE SELECTION - QUICK REFERENCE GUIDE

## Contract Attributes Checklist

**STEP 1: Basic Information**
- [ ] Contract Type: Fixed-Price / Cost-Reimbursement / T&M / Labor-Hour / IDIQ
- [ ] Contract Value: $__________
- [ ] Requirement Type: Supplies / Services / Construction / A&E / IT / R&D
- [ ] Agency: __________ (e.g., DOD, GSA, NASA)

**STEP 2: Contract Details**
- [ ] Performance Period: _____ days
- [ ] Place of Performance: __________
- [ ] Commercial Item: Yes / No
- [ ] Small Business Set-Aside: Yes / No

**STEP 3: Special Conditions**
- [ ] Has Options: Yes / No
- [ ] Government Property Provided: Yes / No
- [ ] International Transport Required: Yes / No
- [ ] Work Performed in US: Yes / No
- [ ] Subcontracting Expected: Yes / No
- [ ] Certified Cost/Pricing Data Required: Yes / No

---

## Automatic Clause Triggers

### By Dollar Threshold

**Over $10,000 (Micro-Purchase)**
- 52.204-7 - System for Award Management
- 52.222-21 - Prohibition of Segregated Facilities
- 52.222-26 - Equal Opportunity
- 52.222-40 - Notification of Employee Rights

**Over $15,000**
- 52.222-36 - Equal Opportunity for Workers with Disabilities

**Over $30,000**
- 52.204-10 - Reporting Executive Compensation
- 52.223-6 - Drug-Free Workplace

**Over $35,000**
- 52.209-6 - Protecting Government's Interest (Debarment)

**Over $150,000 (SAT)**
- 52.203-5 - Covenant Against Contingent Fees
- 52.203-6 - Restrictions on Subcontractor Sales
- 52.203-7 - Anti-Kickback Procedures
- 52.203-12 - Limitation on Payments to Influence
- 52.219-8 - Utilization of Small Business
- 52.222-35 - Equal Opportunity for Veterans
- 52.222-37 - Employment Reports on Veterans
- 52.222-54 - Employment Eligibility (if >120 days in US)

**Over $750,000**
- 52.219-9 - Small Business Subcontracting Plan (if not small business)

**Over $2,000,000**
- 52.215-10 - Price Reduction for Defective Cost Data
- 52.215-12 - Subcontractor Cost or Pricing Data
- 52.230-2 - Cost Accounting Standards

### By Contract Type

**Fixed-Price Contracts**
- 52.232-25 - Prompt Payment
- 52.243-1 - Changes - Fixed-Price
- 52.246-2 - Inspection of Supplies (if supplies)
- 52.246-4 - Inspection of Services (if services)
- 52.249-2 - Termination for Convenience
- 52.249-8 - Default (if over SAT)

**Cost-Reimbursement Contracts**
- 52.216-7 - Allowable Cost and Payment
- 52.232-20 - Limitation of Cost (fully funded)
- 52.232-22 - Limitation of Funds (incrementally funded)
- 52.244-2 - Subcontracts

**Time & Materials / Labor-Hour**
- 52.232-7 - Payments under T&M and LH Contracts
- 52.244-2 - Subcontracts

### By Requirement Type

**Construction**
- 52.236-2 - Differing Site Conditions
- 52.236-3 - Site Investigation
- 52.236-5 - Material and Workmanship
- 52.236-7 - Permits and Responsibilities
- 52.236-13 - Accident Prevention
- 52.236-15 - Schedules for Construction

**Services**
- 52.222-41 - Service Contract Labor Standards (if >$2,500)

**R&D**
- 52.227-14 - Rights in Data - General

### Special Conditions

**If Has Options**
- 52.217-8 - Option to Extend Services
- 52.217-9 - Option to Extend Term

**If Government Property**
- 52.245-1 - Government Property
- 52.245-9 - Use and Charges

**If International Transport**
- 52.247-63 - Preference for US-Flag Air Carriers
- 52.247-64 - Preference for US-Flag Vessels

**If Commercial Item**
- USE: 52.212-4 and 52.212-5
- EXCLUDE: Most standard FAR clauses

**If DOD Contract**
- 252.203-7001 - Prohibition on Fraud (if >SAT)
- 252.204-7012 - Cyber Security
- 252.225-7001 - Buy American Balance of Payments
- 252.232-7003 - Electronic Payment Submission
- 252.247-7023 - Transportation of Supplies by Sea

---

## Common Clause Combinations

### Small Purchase (Under SAT)
```
Base Set:
- 52.202-1 - Definitions
- 52.203-3 - Gratuities
- 52.232-33 - EFT Payment
- 52.233-1 - Disputes
- 52.233-4 - Applicable Law
```

### Standard Services Contract
```
All Base Clauses PLUS:
- 52.222-41 - Service Contract Labor Standards
- 52.237-3 - Continuity of Services
- Options clauses if applicable
- Equal opportunity clauses
```

### Construction Contract
```
All Base Clauses PLUS:
- All 52.236-X construction clauses
- Davis-Bacon wage clauses
- Safety and accident prevention
- Miller Act payment/performance bonds (if >$150K)
```

### Commercial Item Contract
```
ONLY:
- 52.212-4 - Contract Terms (Commercial)
- 52.212-5 - Required Clauses (Commercial)
- 52.252-2 - Clauses Incorporated by Reference
- Minimal addenda clauses
```

---

## Fill-In Requirements

**Common Fill-Ins Needed:**

1. **Options (52.217-8/9)**
   - Option period length
   - Days notice required (default: 30)

2. **Service Contract (52.222-41)**
   - Wage Determination Number from DOL

3. **Small Business Plan (52.219-9)**
   - Percentage goals by category

4. **Data Rights (52.227-14)**
   - Which alternate (I, II, III, IV, V)

5. **Changes (52.243-1)**
   - Which alternate based on type

---

## Quick Decision Tree

```
START → Commercial Item? 
  YES → Use 52.212-4/5 only
  NO ↓
  
Value > $10K?
  NO → Minimal clauses
  YES ↓
  
Contract Type?
  → Fixed-Price: Add FP clauses
  → Cost-Reimb: Add CR clauses
  → T&M: Add T&M clauses
  
Requirement Type?
  → Construction: Add 52.236-X
  → Services: Add 52.222-41
  → Supplies: Add inspection
  
Special Conditions?
  → Check each condition
  → Add applicable clauses
  
Agency = DOD?
  YES → Add DFARS clauses
  NO → Continue
  
DONE → Validate selection
```

---

## Validation Checklist

**Before Finalizing:**
- [ ] All threshold clauses included?
- [ ] Contract type clauses correct?
- [ ] No commercial/non-commercial conflicts?
- [ ] All fill-ins identified?
- [ ] Agency-specific clauses added?
- [ ] Options clauses if has options?
- [ ] Property clauses if GFP?
- [ ] Labor standards if services?

**Red Flags:**
- Missing mandatory clauses
- Commercial + non-commercial mix
- Both 52.232-20 and 52.232-22
- Missing wage determination
- No payment clause

---

## Common Mistakes to Avoid

1. **Forgetting Service Contract Act**
   - Required for ALL service contracts >$2,500

2. **Missing EEO Clauses**
   - Required based on various thresholds

3. **Wrong Termination Clause**
   - Different for construction vs. supplies/services

4. **Commercial Item Confusion**
   - Don't mix commercial and non-commercial clauses

5. **Missing DOD Clauses**
   - Cyber, ITAR, specialty metals, etc.

6. **Wrong Cost Clause**
   - Limitation of Cost vs. Funds

7. **Missing Small Business Plan**
   - Required >$750K if not small business

---

*Remember: When in doubt, check the prescription in the FAR/DFARS!*