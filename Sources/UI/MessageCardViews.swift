import SwiftUI
import Charts
#if os(iOS)
import UIKit
#endif

// MARK: - Message Card Container
public struct MessageCardView: View {
    let card: MessageCard
    
    public init(card: MessageCard) {
        self.card = card
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card header
            HStack {
                Image(systemName: cardIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.aikoAccent)
                
                Text(card.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Share button
                ShareButton(
                    content: generateCardShareContent(),
                    fileName: DocumentShareHelper.generateFileName(for: .messageCard),
                    buttonStyle: .icon
                )
                .scaleEffect(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Card content
            Group {
                switch card.data {
                case .vendors(let vendors):
                    VendorComparisonCard(vendors: vendors)
                case .timeline(let timeline):
                    TimelineCard(timeline: timeline)
                case .compliance(let compliance):
                    ComplianceCard(compliance: compliance)
                case .metrics(let metrics):
                    MetricsCard(metrics: metrics)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.aikoSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var cardIcon: String {
        switch card.type {
        case .vendorComparison:
            return "building.2.fill"
        case .timeline:
            return "calendar"
        case .compliance:
            return "checkmark.shield.fill"
        case .metrics:
            return "chart.bar.fill"
        }
    }
    
    private func generateCardShareContent() -> String {
        var content = """
        \(card.title)
        Generated: \(Date().formatted())
        
        """
        
        switch card.data {
        case .vendors(let vendors):
            content += "VENDOR COMPARISON:\n\n"
            for vendor in vendors {
                content += """
                \(vendor.name):
                - Capability: \(vendor.capability)
                - Compliance: \(vendor.compliance)
                - Pricing: \(vendor.pricing)
                
                """
            }
            
        case .timeline(let timeline):
            content += "PROJECT TIMELINE:\n\n"
            content += "Milestones:\n"
            for milestone in timeline.milestones {
                let status = milestone.isCompleted ? "✓" : "○"
                content += "\(status) \(milestone.title) - \(milestone.date.formatted())\n"
            }
            
        case .compliance(let compliance):
            content += "COMPLIANCE STATUS:\n\n"
            content += "Score: \(Int(compliance.score * 100))%\n"
            if !compliance.issues.isEmpty {
                content += "\nIssues:\n"
                for issue in compliance.issues {
                    content += "- \(issue)\n"
                }
            }
            if !compliance.recommendations.isEmpty {
                content += "\nRecommendations:\n"
                for recommendation in compliance.recommendations {
                    content += "- \(recommendation)\n"
                }
            }
            
        case .metrics(let metrics):
            content += "PROJECT METRICS:\n\n"
            for metric in metrics {
                content += "- \(metric.name): \(Int(metric.value))/\(Int(metric.target)) \(metric.unit)\n"
            }
        }
        
        return content
    }
}

// MARK: - Vendor Comparison Card
struct VendorComparisonCard: View {
    let vendors: [VendorInfo]
    @State private var selectedVendor: VendorInfo?
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(vendors.indices, id: \.self) { index in
                VendorRow(vendor: vendors[index], isSelected: selectedVendor?.name == vendors[index].name)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedVendor = selectedVendor?.name == vendors[index].name ? nil : vendors[index]
                        }
                    }
                
                if index < vendors.count - 1 {
                    Divider()
                }
            }
            
            // Selected vendor details
            if let vendor = selectedVendor {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack {
                        Label("Capability", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(vendor.capability)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Label("Compliance", systemImage: "checkmark.shield")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(vendor.compliance)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Label("Pricing", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(vendor.pricing)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

struct VendorRow: View {
    let vendor: VendorInfo
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Theme.Colors.aikoAccent : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(vendor.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(vendor.capability)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isSelected ? 90 : 0))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Timeline Card
struct TimelineCard: View {
    let timeline: TimelineData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(timeline.milestones.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline indicator
                    VStack(spacing: 0) {
                        Circle()
                            .fill(timeline.milestones[index].isCompleted ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(timeline.milestones[index].isCompleted ? Color.green : Color.gray, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            )
                        
                        if index < timeline.milestones.count - 1 {
                            Rectangle()
                                .fill(timeline.milestones[index].isCompleted ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                                .frame(width: 2)
                                .frame(height: 40)
                        }
                    }
                    
                    // Milestone content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeline.milestones[index].title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(timeline.milestones[index].isCompleted ? .primary : .secondary)
                        
                        Text(timeline.milestones[index].date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if index < timeline.milestones.count - 1 {
                            Spacer(minLength: 20)
                        }
                    }
                    
                    Spacer()
                    
                    if timeline.milestones[index].isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

// MARK: - Compliance Card
struct ComplianceCard: View {
    let compliance: ComplianceData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compliance score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compliance Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(compliance.score * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                // Visual score indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: compliance.score)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: compliance.score)
                }
            }
            
            if !compliance.issues.isEmpty {
                Divider()
                
                // Issues
                VStack(alignment: .leading, spacing: 6) {
                    Label("Issues", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    ForEach(compliance.issues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 4, height: 4)
                                .padding(.top, 5)
                            
                            Text(issue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !compliance.recommendations.isEmpty {
                Divider()
                
                // Recommendations
                VStack(alignment: .leading, spacing: 6) {
                    Label("Recommendations", systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    ForEach(compliance.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                                .padding(.top, 5)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var scoreColor: Color {
        if compliance.score >= 0.8 {
            return .green
        } else if compliance.score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Metrics Card
struct MetricsCard: View {
    let metrics: [MetricData]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(metrics, id: \.name) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(metric.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(metric.value)) / \(Int(metric.target)) \(metric.unit)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(metric.value >= metric.target ? .green : .orange)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(metric.value >= metric.target ? Color.green : Color.orange)
                                .frame(width: min(geometry.size.width * (metric.value / metric.target), geometry.size.width), height: 8)
                                .animation(.easeInOut(duration: 0.5), value: metric.value)
                        }
                    }
                    .frame(height: 8)
                }
                
                if metric.name != metrics.last?.name {
                    Divider()
                }
            }
        }
    }
}