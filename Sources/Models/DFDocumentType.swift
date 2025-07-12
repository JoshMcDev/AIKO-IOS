import Foundation

public enum DFDocumentType: String, CaseIterable, Identifiable, Codable {
    // Sole Source & Competition (alphabetized)
    case eightASoleSource = "8(a) Sole Source"
    case brandNameOrEqual = "Brand Name or Equal"
    case jaOtherThanFullOpenCompetition = "J&A Other Than Full & Open Competition"
    case limitedSourceJustification = "Limited Source Justification"
    
    // Contract Types & Modifications (alphabetized)
    case bridgeContract = "Bridge Contract"
    case contractModification = "Contract Modification"
    case costPlusContractType = "Cost Plus Contract Type"
    case idiq = "IDIQ"
    case optionsExercise = "Options Exercise"
    case timeExtension = "Time Extension"
    
    // Small Business & Set-Asides (alphabetized)
    case hubZoneSetAside = "HUBZone Set-Aside"
    case smallBusinessSetAside = "Small Business Set-Aside"
    case subcontractingPlan = "Subcontracting Plan"
    
    // Special Authorities & Procedures (alphabetized)
    case commercialItemDetermination = "Commercial Item Determination"
    case costPricingDataWaiver = "Cost/Pricing Data Waiver"
    case emergencyUrgentCompelling = "Emergency/Urgent & Compelling"
    case inherentlyGovernmental = "Inherently Governmental Functions"
    case interagencyAgreement = "Interagency Agreement"
    case lptaDetermination = "LPTA Determination"
    case otherTransactionAuthority = "Other Transaction Authority"
    case simplifiedAcquisitionProcedures = "Simplified Acquisition Procedures"
    
    public var id: String { rawValue }
    
    public var fileName: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: return "8a_Sole_Source"
        case .brandNameOrEqual: return "Brand_Name_or_Equal"
        case .jaOtherThanFullOpenCompetition: return "JA_Other_Than_Full_Open_Competition"
        case .limitedSourceJustification: return "Limited_Source_Justification"
        // Contract Types & Modifications
        case .bridgeContract: return "Bridge_Contract"
        case .contractModification: return "Contract_Modification"
        case .costPlusContractType: return "Cost_Plus_Contract_Type"
        case .idiq: return "IDIQ"
        case .optionsExercise: return "Options_Exercise"
        case .timeExtension: return "Time_Extension"
        // Small Business & Set-Asides
        case .hubZoneSetAside: return "HUBZone_Set_Aside"
        case .smallBusinessSetAside: return "Small_Business_Set_Aside"
        case .subcontractingPlan: return "Subcontracting_Plan"
        // Special Authorities & Procedures
        case .commercialItemDetermination: return "Commercial_Item_Determination"
        case .costPricingDataWaiver: return "Cost_Pricing_Data_Waiver"
        case .emergencyUrgentCompelling: return "Emergency_Urgent_Compelling"
        case .inherentlyGovernmental: return "Inherently_Governmental_Functions_Personal_Services"
        case .interagencyAgreement: return "Interagency_Agreement"
        case .lptaDetermination: return "LPTA_Determination_and_Findings_Template"
        case .otherTransactionAuthority: return "Other_Transaction_Authority"
        case .simplifiedAcquisitionProcedures: return "Simplified_Acquisition_Procedures"
        }
    }
    
    public var shortName: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: return "8(a)"
        case .brandNameOrEqual: return "Brand Name"
        case .jaOtherThanFullOpenCompetition: return "J&A"
        case .limitedSourceJustification: return "Limited Source"
        // Contract Types & Modifications
        case .bridgeContract: return "Bridge"
        case .contractModification: return "In-Scope Modification"
        case .costPlusContractType: return "Cost Plus"
        case .idiq: return "IDIQ"
        case .optionsExercise: return "Options"
        case .timeExtension: return "Extension"
        // Small Business & Set-Asides
        case .hubZoneSetAside: return "HUBZone"
        case .smallBusinessSetAside: return "Small Biz"
        case .subcontractingPlan: return "Subcontracting"
        // Special Authorities & Procedures
        case .commercialItemDetermination: return "Commercial"
        case .costPricingDataWaiver: return "Cost Waiver"
        case .emergencyUrgentCompelling: return "Emergency"
        case .inherentlyGovernmental: return "IGF & Personal Services"
        case .interagencyAgreement: return "Interagency"
        case .lptaDetermination: return "LPTA"
        case .otherTransactionAuthority: return "OTA"
        case .simplifiedAcquisitionProcedures: return "SAP"
        }
    }
    
    public var description: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: return "8(a) small business sole source award justification"
        case .brandNameOrEqual: return "Justification for brand name or equal specifications"
        case .jaOtherThanFullOpenCompetition: return "Justification for other than full and open competition"
        case .limitedSourceJustification: return "Justification for limiting sources"
        // Contract Types & Modifications
        case .bridgeContract: return "Bridge contract justification and approval"
        case .contractModification: return "Contract modification determination"
        case .costPlusContractType: return "Cost-plus contract type determination"
        case .idiq: return "IDIQ contract establishment"
        case .optionsExercise: return "Contract options exercise determination"
        case .timeExtension: return "Contract time extension justification"
        // Small Business & Set-Asides
        case .hubZoneSetAside: return "HUBZone small business set-aside determination"
        case .smallBusinessSetAside: return "Small business set-aside determination"
        case .subcontractingPlan: return "Subcontracting plan requirement determination"
        // Special Authorities & Procedures
        case .commercialItemDetermination: return "Commercial item determination"
        case .costPricingDataWaiver: return "Cost or pricing data waiver"
        case .emergencyUrgentCompelling: return "Emergency or urgent and compelling circumstances"
        case .inherentlyGovernmental: return "Determination for inherently governmental functions"
        case .interagencyAgreement: return "Interagency agreement determination"
        case .lptaDetermination: return "Lowest Price Technically Acceptable determination"
        case .otherTransactionAuthority: return "Other Transaction Authority determination"
        case .simplifiedAcquisitionProcedures: return "Simplified acquisition procedures authorization"
        }
    }
    
    public var icon: String {
        switch self {
        case .eightASoleSource, .smallBusinessSetAside, .hubZoneSetAside:
            return "building.2"
        case .brandNameOrEqual, .commercialItemDetermination:
            return "tag"
        case .limitedSourceJustification, .jaOtherThanFullOpenCompetition:
            return "person.2.slash"
        case .bridgeContract, .timeExtension:
            return "calendar.badge.clock"
        case .contractModification, .optionsExercise:
            return "doc.badge.gearshape"
        case .costPlusContractType, .costPricingDataWaiver:
            return "dollarsign.square"
        case .idiq:
            return "rectangle.stack"
        case .subcontractingPlan:
            return "person.3"
        case .emergencyUrgentCompelling:
            return "exclamationmark.triangle"
        case .interagencyAgreement:
            return "building.2.crop.circle"
        case .lptaDetermination:
            return "chart.line.downtrend.xyaxis"
        case .otherTransactionAuthority:
            return "sparkles"
        case .simplifiedAcquisitionProcedures:
            return "hare"
        case .inherentlyGovernmental:
            return "person.badge.shield.checkmark"
        }
    }
    
    public var farReference: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: return "FAR 19.804-2, 19.805-1, 19.808"
        case .brandNameOrEqual: return "FAR 11.104, 11.107, 6.302-1(c)"
        case .jaOtherThanFullOpenCompetition: return "FAR 6.303, 6.304, 6.302"
        case .limitedSourceJustification: return "FAR 13.106-1(b), 13.104, 13.501"
        // Contract Types & Modifications
        case .bridgeContract: return "FAR 16.505(a)(10), 6.302-1, 17.207"
        case .contractModification: return "FAR 43.203, 43.204, 43.205"
        case .costPlusContractType: return "FAR 16.301-3, 16.103, 16.104"
        case .idiq: return "FAR 16.504, 16.505, 16.501-2"
        case .optionsExercise: return "FAR 17.207, 17.206, 17.208"
        case .timeExtension: return "FAR 43.204, 43.103, 52.243"
        // Small Business & Set-Asides
        case .hubZoneSetAside: return "FAR 19.1305, 19.1306, 19.1307"
        case .smallBusinessSetAside: return "FAR 19.502, 19.503, 19.505"
        case .subcontractingPlan: return "FAR 19.702, 19.704, 19.705"
        // Special Authorities & Procedures
        case .commercialItemDetermination: return "FAR 2.101, 12.102, 10.002"
        case .costPricingDataWaiver: return "FAR 15.403-1, 15.403-4, 15.406-2"
        case .emergencyUrgentCompelling: return "FAR 6.302-2, 6.303-2, 18.125"
        case .inherentlyGovernmental: return "FAR 7.503, 7.500, 37.104"
        case .interagencyAgreement: return "FAR 17.502-2, 17.503, 17.504"
        case .lptaDetermination: return "FAR 15.101-2, 15.304, 15.404"
        case .otherTransactionAuthority: return "10 U.S.C. 2371b, 10 U.S.C. 2371"
        case .simplifiedAcquisitionProcedures: return "FAR 13.003, 13.106, 13.201"
        }
    }
    
    public var category: DFCategory {
        switch self {
        case .eightASoleSource, .brandNameOrEqual, .jaOtherThanFullOpenCompetition, .limitedSourceJustification:
            return .competitionAndSoleSource
        case .bridgeContract, .contractModification, .costPlusContractType, .idiq, .optionsExercise, .timeExtension:
            return .contractTypesAndModifications
        case .hubZoneSetAside, .smallBusinessSetAside, .subcontractingPlan:
            return .smallBusinessSetAsides
        case .commercialItemDetermination, .costPricingDataWaiver, .emergencyUrgentCompelling,
             .inherentlyGovernmental, .interagencyAgreement, .lptaDetermination, .otherTransactionAuthority,
             .simplifiedAcquisitionProcedures:
            return .specialAuthoritiesAndProcedures
        }
    }
    
    public var isProFeature: Bool {
        return false // All features unlocked
    }
    
    /// Get comprehensive FAR reference information
    public var comprehensiveFARReference: ComprehensiveFARReference? {
        return FARReferenceService.getFARReference(for: self.rawValue)
    }
    
    /// Get formatted FAR/DFAR references for display
    public var formattedFARReferences: String {
        return FARReferenceService.formatFARReferences(for: self.rawValue)
    }
}

public enum DFCategory: String, CaseIterable {
    case competitionAndSoleSource = "Competition & Sole Source"
    case contractTypesAndModifications = "Contract Types & Modifications"
    case smallBusinessSetAsides = "Small Business Set-Asides"
    case specialAuthoritiesAndProcedures = "Special Authorities & Procedures"
    
    public var icon: String {
        switch self {
        case .competitionAndSoleSource: return "person.2.slash"
        case .contractTypesAndModifications: return "doc.badge.gearshape"
        case .smallBusinessSetAsides: return "building.2"
        case .specialAuthoritiesAndProcedures: return "sparkles"
        }
    }
}

// Note: GeneratedDocument now supports DFDocumentType directly through its initializer