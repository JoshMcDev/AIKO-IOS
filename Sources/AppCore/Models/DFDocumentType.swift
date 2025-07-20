import Foundation

public enum DFDocumentType: String, CaseIterable, Identifiable, Codable, Sendable {
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
        case .eightASoleSource: "8a_Sole_Source"
        case .brandNameOrEqual: "Brand_Name_or_Equal"
        case .jaOtherThanFullOpenCompetition: "JA_Other_Than_Full_Open_Competition"
        case .limitedSourceJustification: "Limited_Source_Justification"
        // Contract Types & Modifications
        case .bridgeContract: "Bridge_Contract"
        case .contractModification: "Contract_Modification"
        case .costPlusContractType: "Cost_Plus_Contract_Type"
        case .idiq: "IDIQ"
        case .optionsExercise: "Options_Exercise"
        case .timeExtension: "Time_Extension"
        // Small Business & Set-Asides
        case .hubZoneSetAside: "HUBZone_Set_Aside"
        case .smallBusinessSetAside: "Small_Business_Set_Aside"
        case .subcontractingPlan: "Subcontracting_Plan"
        // Special Authorities & Procedures
        case .commercialItemDetermination: "Commercial_Item_Determination"
        case .costPricingDataWaiver: "Cost_Pricing_Data_Waiver"
        case .emergencyUrgentCompelling: "Emergency_Urgent_Compelling"
        case .inherentlyGovernmental: "Inherently_Governmental_Functions_Personal_Services"
        case .interagencyAgreement: "Interagency_Agreement"
        case .lptaDetermination: "LPTA_Determination_and_Findings_Template"
        case .otherTransactionAuthority: "Other_Transaction_Authority"
        case .simplifiedAcquisitionProcedures: "Simplified_Acquisition_Procedures"
        }
    }

    public var shortName: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: "8(a)"
        case .brandNameOrEqual: "Brand Name"
        case .jaOtherThanFullOpenCompetition: "J&A"
        case .limitedSourceJustification: "Limited Source"
        // Contract Types & Modifications
        case .bridgeContract: "Bridge"
        case .contractModification: "In-Scope Modification"
        case .costPlusContractType: "Cost Plus"
        case .idiq: "IDIQ"
        case .optionsExercise: "Options"
        case .timeExtension: "Extension"
        // Small Business & Set-Asides
        case .hubZoneSetAside: "HUBZone"
        case .smallBusinessSetAside: "Small Biz"
        case .subcontractingPlan: "Subcontracting"
        // Special Authorities & Procedures
        case .commercialItemDetermination: "Commercial"
        case .costPricingDataWaiver: "Cost Waiver"
        case .emergencyUrgentCompelling: "Emergency"
        case .inherentlyGovernmental: "IGF & Personal Services"
        case .interagencyAgreement: "Interagency"
        case .lptaDetermination: "LPTA"
        case .otherTransactionAuthority: "OTA"
        case .simplifiedAcquisitionProcedures: "SAP"
        }
    }

    public var description: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: "8(a) small business sole source award justification"
        case .brandNameOrEqual: "Justification for brand name or equal specifications"
        case .jaOtherThanFullOpenCompetition: "Justification for other than full and open competition"
        case .limitedSourceJustification: "Justification for limiting sources"
        // Contract Types & Modifications
        case .bridgeContract: "Bridge contract justification and approval"
        case .contractModification: "Contract modification determination"
        case .costPlusContractType: "Cost-plus contract type determination"
        case .idiq: "IDIQ contract establishment"
        case .optionsExercise: "Contract options exercise determination"
        case .timeExtension: "Contract time extension justification"
        // Small Business & Set-Asides
        case .hubZoneSetAside: "HUBZone small business set-aside determination"
        case .smallBusinessSetAside: "Small business set-aside determination"
        case .subcontractingPlan: "Subcontracting plan requirement determination"
        // Special Authorities & Procedures
        case .commercialItemDetermination: "Commercial item determination"
        case .costPricingDataWaiver: "Cost or pricing data waiver"
        case .emergencyUrgentCompelling: "Emergency or urgent and compelling circumstances"
        case .inherentlyGovernmental: "Determination for inherently governmental functions"
        case .interagencyAgreement: "Interagency agreement determination"
        case .lptaDetermination: "Lowest Price Technically Acceptable determination"
        case .otherTransactionAuthority: "Other Transaction Authority determination"
        case .simplifiedAcquisitionProcedures: "Simplified acquisition procedures authorization"
        }
    }

    public var icon: String {
        switch self {
        case .eightASoleSource, .smallBusinessSetAside, .hubZoneSetAside:
            "building.2"
        case .brandNameOrEqual, .commercialItemDetermination:
            "tag"
        case .limitedSourceJustification, .jaOtherThanFullOpenCompetition:
            "person.2.slash"
        case .bridgeContract, .timeExtension:
            "calendar.badge.clock"
        case .contractModification, .optionsExercise:
            "doc.badge.gearshape"
        case .costPlusContractType, .costPricingDataWaiver:
            "dollarsign.square"
        case .idiq:
            "rectangle.stack"
        case .subcontractingPlan:
            "person.3"
        case .emergencyUrgentCompelling:
            "exclamationmark.triangle"
        case .interagencyAgreement:
            "building.2.crop.circle"
        case .lptaDetermination:
            "chart.line.downtrend.xyaxis"
        case .otherTransactionAuthority:
            "sparkles"
        case .simplifiedAcquisitionProcedures:
            "hare"
        case .inherentlyGovernmental:
            "person.badge.shield.checkmark"
        }
    }

    public var farReference: String {
        switch self {
        // Sole Source & Competition
        case .eightASoleSource: "FAR 19.804-2, 19.805-1, 19.808"
        case .brandNameOrEqual: "FAR 11.104, 11.107, 6.302-1(c)"
        case .jaOtherThanFullOpenCompetition: "FAR 6.303, 6.304, 6.302"
        case .limitedSourceJustification: "FAR 13.106-1(b), 13.104, 13.501"
        // Contract Types & Modifications
        case .bridgeContract: "FAR 16.505(a)(10), 6.302-1, 17.207"
        case .contractModification: "FAR 43.203, 43.204, 43.205"
        case .costPlusContractType: "FAR 16.301-3, 16.103, 16.104"
        case .idiq: "FAR 16.504, 16.505, 16.501-2"
        case .optionsExercise: "FAR 17.207, 17.206, 17.208"
        case .timeExtension: "FAR 43.204, 43.103, 52.243"
        // Small Business & Set-Asides
        case .hubZoneSetAside: "FAR 19.1305, 19.1306, 19.1307"
        case .smallBusinessSetAside: "FAR 19.502, 19.503, 19.505"
        case .subcontractingPlan: "FAR 19.702, 19.704, 19.705"
        // Special Authorities & Procedures
        case .commercialItemDetermination: "FAR 2.101, 12.102, 10.002"
        case .costPricingDataWaiver: "FAR 15.403-1, 15.403-4, 15.406-2"
        case .emergencyUrgentCompelling: "FAR 6.302-2, 6.303-2, 18.125"
        case .inherentlyGovernmental: "FAR 7.503, 7.500, 37.104"
        case .interagencyAgreement: "FAR 17.502-2, 17.503, 17.504"
        case .lptaDetermination: "FAR 15.101-2, 15.304, 15.404"
        case .otherTransactionAuthority: "10 U.S.C. 2371b, 10 U.S.C. 2371"
        case .simplifiedAcquisitionProcedures: "FAR 13.003, 13.106, 13.201"
        }
    }

    public var category: DFCategory {
        switch self {
        case .eightASoleSource, .brandNameOrEqual, .jaOtherThanFullOpenCompetition, .limitedSourceJustification:
            .competitionAndSoleSource
        case .bridgeContract, .contractModification, .costPlusContractType, .idiq, .optionsExercise, .timeExtension:
            .contractTypesAndModifications
        case .hubZoneSetAside, .smallBusinessSetAside, .subcontractingPlan:
            .smallBusinessSetAsides
        case .commercialItemDetermination, .costPricingDataWaiver, .emergencyUrgentCompelling,
             .inherentlyGovernmental, .interagencyAgreement, .lptaDetermination, .otherTransactionAuthority,
             .simplifiedAcquisitionProcedures:
            .specialAuthoritiesAndProcedures
        }
    }

    public var isProFeature: Bool {
        false // All features unlocked
    }

    /// Get comprehensive FAR reference information
    public var comprehensiveFARReference: ComprehensiveFARReference? {
        // Platform implementations will provide actual FAR reference service
        // For now, return nil - this will be overridden in platform-specific code
        nil
    }

    /// Get formatted FAR/DFAR references for display
    public var formattedFARReferences: String {
        // Platform implementations will provide actual FAR reference formatting
        // For now, return the basic farReference
        farReference
    }
}

public enum DFCategory: String, CaseIterable {
    case competitionAndSoleSource = "Competition & Sole Source"
    case contractTypesAndModifications = "Contract Types & Modifications"
    case smallBusinessSetAsides = "Small Business Set-Asides"
    case specialAuthoritiesAndProcedures = "Special Authorities & Procedures"

    public var icon: String {
        switch self {
        case .competitionAndSoleSource: "person.2.slash"
        case .contractTypesAndModifications: "doc.badge.gearshape"
        case .smallBusinessSetAsides: "building.2"
        case .specialAuthoritiesAndProcedures: "sparkles"
        }
    }
}

// Note: GeneratedDocument now supports DFDocumentType directly through its initializer
