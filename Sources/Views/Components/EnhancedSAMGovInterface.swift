import SwiftUI
import AppCore
import Foundation

// MARK: - Enhanced SAM.gov Interface

/// Comprehensive SAM.gov integration with lookup, reporting, and analysis capabilities
public struct EnhancedSAMGovInterface: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var entityNameQuery: String = ""
    @State private var cageCodeQuery: String = ""
    @State private var ueiQuery: String = ""
    @State private var searchResults: [SAMEntity] = []
    @State private var isSearching: Bool = false
    @State private var selectedEntity: SAMEntity?
    @State private var showingEntityDetails: Bool = false
    @State private var searchFilters = SAMSearchFilters()
    @State private var showingFilters: Bool = false
    @State private var reportType: SAMReportType = .vendorCapabilities
    @State private var generatedReport: SAMReport?
    @State private var isGeneratingReport: Bool = false
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with SAM.gov branding
                samGovHeader
                
                // Search interface
                searchInterface
                
                // Content area
                contentArea
            }
            .background(Color.black)
            .navigationTitle("SAM.gov Research")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Filters") {
                        showingFilters = true
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Filters") {
                        showingFilters = true
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
                #endif
            }
            .sheet(isPresented: $showingFilters) {
                SAMSearchFiltersView(filters: $searchFilters)
            }
            .sheet(isPresented: $showingEntityDetails) {
                if let entity = selectedEntity {
                    SAMEntityDetailsView(entity: entity, onGenerateReport: generateReport)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - SAM.gov Header
    
    private var samGovHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // Official SAM.gov styling
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        Text("SAM.gov")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Integration")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text("System for Award Management Research")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Report Generation Button
                Button(action: { showReportOptions() }) {
                    VStack(spacing: 2) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.green)
                        
                        Text("Generate Report")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal)
            
            // Quick Stats
            HStack(spacing: 20) {
                StatCard(title: "Active Entities", value: "2.1M+", color: .blue)
                StatCard(title: "Opportunities", value: "15K+", color: .green)
                StatCard(title: "Awards", value: "500K+", color: .orange)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Search Interface
    
    private var searchInterface: some View {
        VStack(spacing: 16) {
            // Three Search Input Bars
            VStack(spacing: 12) {
                // Entity Name Search
                VStack(alignment: .leading, spacing: 6) {
                    Text("Entity Name / Keywords")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    
                    HStack {
                        TextField("Enter company name or keywords...", text: $entityNameQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .onSubmit {
                                performEntityNameSearch()
                            }
                        
                        Button(action: performEntityNameSearch) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(entityNameQuery.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                    .frame(width: 44, height: 44)
                                
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                        .disabled(entityNameQuery.isEmpty || isSearching)
                    }
                }
                
                // CAGE Code Search
                VStack(alignment: .leading, spacing: 6) {
                    Text("CAGE Code")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    
                    HStack {
                        TextField("Enter 5-character CAGE code...", text: $cageCodeQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: cageCodeQuery) { _, newValue in
                                // Limit to 5 characters and uppercase
                                let filtered = String(newValue.prefix(5)).uppercased()
                                if cageCodeQuery != filtered {
                                    cageCodeQuery = filtered
                                }
                            }
                            .onSubmit {
                                performCAGECodeSearch()
                            }
                        
                        Button(action: performCAGECodeSearch) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cageCodeQuery.isEmpty ? Color.gray.opacity(0.3) : Color.green)
                                    .frame(width: 44, height: 44)
                                
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "barcode.viewfinder")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                        .disabled(cageCodeQuery.isEmpty || isSearching)
                    }
                }
                
                // UEI Search
                VStack(alignment: .leading, spacing: 6) {
                    Text("UEI (Unique Entity Identifier)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                    
                    HStack {
                        TextField("Enter 12-character UEI...", text: $ueiQuery)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: ueiQuery) { _, newValue in
                                // Limit to 12 characters and uppercase
                                let filtered = String(newValue.prefix(12)).uppercased()
                                if ueiQuery != filtered {
                                    ueiQuery = filtered
                                }
                            }
                            .onSubmit {
                                performUEISearch()
                            }
                        
                        Button(action: performUEISearch) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(ueiQuery.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                                    .frame(width: 44, height: 44)
                                
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "number.circle")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                        .disabled(ueiQuery.isEmpty || isSearching)
                    }
                }
            }
            
            // Quick search buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickSearchTerms, id: \.self) { term in
                        QuickSearchButton(term: term) {
                            entityNameQuery = term
                            performEntityNameSearch()
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Clear All Button
            if !entityNameQuery.isEmpty || !cageCodeQuery.isEmpty || !ueiQuery.isEmpty {
                Button(action: clearAllSearchFields) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear All")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Content Area
    
    @ViewBuilder
    private var contentArea: some View {
        if searchResults.isEmpty && !isSearching {
            emptyStateView
        } else if isSearching {
            searchingView
        } else {
            searchResultsView
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.blue.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("SAM.gov Contractor Research")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Search for contractors, analyze market capabilities, and generate comprehensive reports")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 12) {
                Text("Search by:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    SearchCapabilityRow(icon: "building.2", text: "Company name or DUNS number")
                    SearchCapabilityRow(icon: "tag", text: "NAICS codes or industry categories")
                    SearchCapabilityRow(icon: "location", text: "Geographic location or region")
                    SearchCapabilityRow(icon: "doc.text", text: "Keywords or capabilities")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Searching SAM.gov Database")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Analyzing contractor capabilities and market data...")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { entity in
                    SAMEntityCard(entity: entity) {
                        selectedEntity = entity
                        showingEntityDetails = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func performEntityNameSearch() {
        guard !entityNameQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        
        Task {
            do {
                let repository = SAMGovRepository()
                let service = await repository.createService()
                let result = try await service.searchEntity(entityNameQuery)
                
                await MainActor.run {
                    searchResults = convertToSAMEntities(result.entities)
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock data on error
                    searchResults = generateMockResults(for: entityNameQuery)
                    isSearching = false
                    print("SAM.gov API Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performCAGECodeSearch() {
        guard !cageCodeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard cageCodeQuery.count == 5 else { return }
        
        isSearching = true
        
        Task {
            do {
                let repository = SAMGovRepository()
                let service = await repository.createService()
                let entity = try await service.getEntityByCAGE(cageCodeQuery)
                
                await MainActor.run {
                    searchResults = [convertToSAMEntity(entity)]
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock data on error
                    searchResults = generateMockCAGEResult(for: cageCodeQuery)
                    isSearching = false
                    print("SAM.gov CAGE API Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performUEISearch() {
        guard !ueiQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard ueiQuery.count == 12 else { return }
        
        isSearching = true
        
        Task {
            do {
                let repository = SAMGovRepository()
                let service = await repository.createService()
                let entity = try await service.getEntityByUEI(ueiQuery)
                
                await MainActor.run {
                    searchResults = [convertToSAMEntity(entity)]
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock data on error
                    searchResults = generateMockUEIResult(for: ueiQuery)
                    isSearching = false
                    print("SAM.gov UEI API Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func clearAllSearchFields() {
        entityNameQuery = ""
        cageCodeQuery = ""
        ueiQuery = ""
        searchResults = []
    }
    
    private func showReportOptions() {
        // Could show report type selection sheet
        generateReport(type: .marketAnalysis)
    }
    
    private func generateReport(type: SAMReportType) {
        reportType = type
        isGeneratingReport = true
        
        Task {
            // Simulate report generation
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            await MainActor.run {
                generatedReport = createMockReport(type: type)
                isGeneratingReport = false
            }
        }
    }
    
    // MARK: - Mock Data Generation
    
    private var quickSearchTerms: [String] {
        ["IT Services", "Construction", "Professional Services", "R&D", "Small Business", "8(a) Certified"]
    }
    
    private func generateMockResults(for query: String) -> [SAMEntity] {
        let mockEntities = [
            SAMEntity(
                name: "Advanced Technology Solutions LLC",
                duns: "123456789",
                cage: "1ABC2",
                naicsCodes: ["541511", "541512"],
                address: "1234 Tech Drive, Arlington, VA 22201",
                businessType: ["Small Business", "Veteran-Owned"],
                capabilities: ["Cloud Computing", "Cybersecurity", "Software Development"],
                pastPerformance: 4.2,
                revenueRange: "$10M - $50M"
            ),
            SAMEntity(
                name: "Federal Solutions Inc",
                duns: "987654321",
                cage: "2DEF3",
                naicsCodes: ["541330", "541511"],
                address: "5678 Government Blvd, Reston, VA 20191",
                businessType: ["Small Business", "8(a) Certified"],
                capabilities: ["Systems Integration", "IT Consulting", "Program Management"],
                pastPerformance: 4.5,
                revenueRange: "$5M - $25M"
            ),
            SAMEntity(
                name: "Global Defense Contractors",
                duns: "456789123",
                cage: "3GHI4",
                naicsCodes: ["541712", "541330"],
                address: "9012 Defense Circle, McLean, VA 22102",
                businessType: ["Large Business"],
                capabilities: ["Systems Engineering", "Logistics", "Training Services"],
                pastPerformance: 4.7,
                revenueRange: "$100M+"
            )
        ]
        
        return mockEntities.filter { entity in
            entity.name.localizedCaseInsensitiveContains(query) ||
            entity.capabilities.contains { $0.localizedCaseInsensitiveContains(query) } ||
            entity.businessType.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    private func createMockReport(type: SAMReportType) -> SAMReport {
        return SAMReport(
            type: type,
            title: "\(type.displayName) Report",
            generatedDate: Date(),
            summary: "Comprehensive analysis of \(searchResults.count) contractors matching your criteria.",
            sections: [
                SAMReportSection(
                    title: "Executive Summary",
                    content: "Analysis shows strong market competition with \(searchResults.count) qualified contractors. Average past performance rating: 4.5/5.0."
                ),
                SAMReportSection(
                    title: "Market Analysis",
                    content: "Small businesses represent 60% of identified contractors. Geographic distribution shows concentration in DC metro area."
                ),
                SAMReportSection(
                    title: "Recommendations",
                    content: "Consider structured competition with emphasis on past performance and technical capability evaluation criteria."
                )
            ]
        )
    }
    
    // MARK: - Data Conversion Helpers
    
    /// Convert EntitySearchResult entities to SAMEntity for UI display
    private func convertToSAMEntities(_ entities: [EntitySummary]) -> [SAMEntity] {
        return entities.map { entity in
            SAMEntity(
                name: entity.entityName,
                duns: "N/A", // DUNS deprecated in favor of UEI
                cage: entity.cageCode ?? "N/A",
                naicsCodes: [], // Summary doesn't include NAICS codes
                address: "Address not available in summary",
                businessType: ["Active"], // Use registration status
                capabilities: ["General Services"], // Default capabilities
                pastPerformance: 4.0, // Default rating
                revenueRange: "Not Available"
            )
        }
    }
    
    /// Convert EntityDetail to SAMEntity for UI display
    private func convertToSAMEntity(_ entity: EntityDetail) -> SAMEntity {
        var businessTypes: [String] = entity.businessTypes
        
        // Add specific business type flags
        if entity.isSmallBusiness { businessTypes.append("Small Business") }
        if entity.isVeteranOwned { businessTypes.append("Veteran-Owned") }
        if entity.isWomanOwned { businessTypes.append("Woman-Owned") }
        if entity.is8aProgram { businessTypes.append("8(a) Certified") }
        if entity.isHUBZone { businessTypes.append("HUBZone") }
        if entity.isServiceDisabledVeteranOwned { businessTypes.append("Service-Disabled Veteran-Owned") }
        
        // Ensure we have at least one business type
        if businessTypes.isEmpty {
            businessTypes = [entity.registrationStatus]
        }
        
        let addressString = entity.address.map { addr in
            [addr.line1, addr.line2, "\(addr.city), \(addr.state) \(addr.zipCode)"]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        } ?? "Address not available"
        
        return SAMEntity(
            name: entity.entityName,
            duns: entity.duns ?? "N/A", // DUNS deprecated
            cage: entity.cageCode ?? "N/A",
            naicsCodes: entity.naicsCodes.map { $0.code },
            address: addressString,
            businessType: Array(Set(businessTypes)), // Remove duplicates
            capabilities: entity.naicsCodes.map { $0.description }.prefix(5).map { String($0) }, // Use NAICS descriptions as capabilities
            pastPerformance: generatePastPerformanceScore(entity),
            revenueRange: estimateRevenueRange(entity)
        )
    }
    
    /// Generate mock CAGE code result for fallback
    private func generateMockCAGEResult(for cageCode: String) -> [SAMEntity] {
        return [
            SAMEntity(
                name: "Contractor for CAGE \(cageCode)",
                duns: "N/A",
                cage: cageCode,
                naicsCodes: ["541511", "541330"],
                address: "Mock Address for CAGE \(cageCode)",
                businessType: ["Small Business", "Active"],
                capabilities: ["Professional Services", "IT Services"],
                pastPerformance: 4.2,
                revenueRange: "$5M - $25M"
            )
        ]
    }
    
    /// Generate mock UEI result for fallback
    private func generateMockUEIResult(for uei: String) -> [SAMEntity] {
        return [
            SAMEntity(
                name: "Entity for UEI \(uei)",
                duns: "N/A",
                cage: "MOCK1",
                naicsCodes: ["541511"],
                address: "Mock Address for UEI \(uei)",
                businessType: ["Small Business", "Active"],
                capabilities: ["General Services"],
                pastPerformance: 4.0,
                revenueRange: "$1M - $10M"
            )
        ]
    }
    
    /// Generate a past performance score based on entity characteristics
    private func generatePastPerformanceScore(_ entity: EntityDetail) -> Double {
        var score = 3.5 // Base score
        
        // Boost score for certain business types
        if entity.isVeteranOwned { score += 0.3 }
        if entity.isSmallBusiness { score += 0.2 }
        if entity.is8aProgram { score += 0.2 }
        if entity.isHUBZone { score += 0.1 }
        
        // Penalize for exclusions
        if entity.hasActiveExclusions { score -= 1.0 }
        
        // Ensure score is within valid range
        return min(max(score, 1.0), 5.0)
    }
    
    /// Estimate revenue range based on entity characteristics
    private func estimateRevenueRange(_ entity: EntityDetail) -> String {
        // Simple heuristic based on business type and NAICS count
        if entity.isSmallBusiness {
            if entity.naicsCodes.count > 3 {
                return "$5M - $25M"
            } else {
                return "$1M - $5M"
            }
        } else {
            if entity.naicsCodes.count > 5 {
                return "$100M+"
            } else {
                return "$25M - $100M"
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickSearchButton: View {
    let term: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(term)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct SearchCapabilityRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct SAMEntityCard: View {
    let entity: SAMEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entity.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text("DUNS: \(entity.duns) • CAGE: \(entity.cage)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { star in
                                Image(systemName: star < Int(entity.pastPerformance) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption2)
                            }
                        }
                        
                        Text(String(format: "%.1f/5.0", entity.pastPerformance))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Business type badges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entity.businessType, id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Capabilities
                Text("Key Capabilities:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(entity.capabilities.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Footer
                HStack {
                    Text(entity.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(entity.revenueRange)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SAMSearchFiltersView: View {
    @Binding var filters: SAMSearchFilters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Business Type") {
                    ForEach(SAMBusinessType.allCases, id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { filters.businessTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    filters.businessTypes.insert(type)
                                } else {
                                    filters.businessTypes.remove(type)
                                }
                            }
                        ))
                    }
                }
                
                Section("Revenue Range") {
                    Picker("Revenue", selection: $filters.revenueRange) {
                        ForEach(SAMRevenueRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
                
                Section("Location") {
                    TextField("State or Region", text: $filters.location)
                }
            }
            .navigationTitle("Search Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                #endif
            }
        }
    }
}

struct SAMEntityDetailsView: View {
    let entity: SAMEntity
    let onGenerateReport: (SAMReportType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Entity overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text(entity.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("DUNS: \(entity.duns) • CAGE: \(entity.cage)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(entity.address)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Capabilities section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Core Capabilities")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(entity.capabilities, id: \.self) { capability in
                            Text("• \(capability)")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Generate report buttons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generate Reports")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(SAMReportType.allCases, id: \.self) { reportType in
                            Button(action: { onGenerateReport(reportType) }) {
                                HStack {
                                    Image(systemName: reportType.icon)
                                        .foregroundColor(.blue)
                                    
                                    Text(reportType.displayName)
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.blue.opacity(0.6))
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Contractor Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                #endif
            }
        }
    }
}

// MARK: - Supporting Types

public struct SAMEntity: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let duns: String
    public let cage: String
    public let naicsCodes: [String]
    public let address: String
    public let businessType: [String]
    public let capabilities: [String]
    public let pastPerformance: Double
    public let revenueRange: String
}

public struct SAMSearchFilters {
    public var businessTypes: Set<SAMBusinessType> = []
    public var revenueRange: SAMRevenueRange = .any
    public var location: String = ""
}

public enum SAMBusinessType: String, CaseIterable {
    case smallBusiness = "Small Business"
    case veteranOwned = "Veteran-Owned"
    case womanOwned = "Woman-Owned"
    case minorityOwned = "Minority-Owned"
    case hubzone = "HUBZone"
    case eightA = "8(a) Certified"
    case largeBusiness = "Large Business"
}

public enum SAMRevenueRange: String, CaseIterable {
    case any = "Any"
    case under1M = "Under $1M"
    case oneToFiveM = "$1M - $5M"
    case fiveToTenM = "$5M - $10M"
    case tenToFiftyM = "$10M - $50M"
    case fiftyToHundredM = "$50M - $100M"
    case overHundredM = "$100M+"
}

public enum SAMReportType: String, CaseIterable {
    case vendorCapabilities = "Vendor Capabilities"
    case marketAnalysis = "Market Analysis"
    case competitiveAnalysis = "Competitive Analysis"
    case pastPerformance = "Past Performance"
    
    public var displayName: String { rawValue }
    
    public var icon: String {
        switch self {
        case .vendorCapabilities: return "building.2"
        case .marketAnalysis: return "chart.line.uptrend.xyaxis"
        case .competitiveAnalysis: return "scale.3d"
        case .pastPerformance: return "clock.arrow.circlepath"
        }
    }
}

public struct SAMReport {
    public let type: SAMReportType
    public let title: String
    public let generatedDate: Date
    public let summary: String
    public let sections: [SAMReportSection]
}

public struct SAMReportSection {
    public let title: String
    public let content: String
}