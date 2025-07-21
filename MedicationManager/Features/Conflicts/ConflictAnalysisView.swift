import SwiftUI

struct ConflictAnalysisView: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    let query: String?
    let fromCache: Bool
    
    @State private var expandedSections: Set<String> = ["summary", "conflicts"]
    @State private var showingShareSheet: Bool = false
    @State private var showingExportOptions: Bool = false
    @Environment(\.dismiss) private var dismiss
    private let analyticsManager = AnalyticsManager.shared
    
    init(analysis: ClaudeAIClient.ConflictAnalysis, query: String? = nil, fromCache: Bool = false) {
        self.analysis = analysis
        self.query = query
        self.fromCache = fromCache
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Header Card
                AnalysisHeaderCard(
                    analysis: analysis,
                    query: query,
                    fromCache: fromCache
                )
                
                // Summary Section
                ExpandableSection(
                    id: "summary",
                    title: AppStrings.AI.summary,
                    isExpanded: expandedSections.contains("summary"),
                    content: {
                        SummaryContent(analysis: analysis)
                    },
                    onToggle: {
                        toggleSection("summary")
                    }
                )
                
                // Conflicts Section
                if !analysis.conflicts.isEmpty {
                    ExpandableSection(
                        id: "conflicts",
                        title: AppStrings.Conflicts.detectedConflicts,
                        badge: "\(analysis.conflictCount)",
                        badgeColor: analysis.overallSeverity.color,
                        isExpanded: expandedSections.contains("conflicts"),
                        content: {
                            ConflictsContent(analysis: analysis)
                        },
                        onToggle: {
                            toggleSection("conflicts")
                        }
                    )
                }
                
                // Recommendations Section
                if !analysis.recommendations.isEmpty {
                    ExpandableSection(
                        id: "recommendations",
                        title: AppStrings.AI.recommendations,
                        badge: "\(analysis.recommendations.count)",
                        isExpanded: expandedSections.contains("recommendations"),
                        content: {
                            RecommendationsContent(analysis: analysis)
                        },
                        onToggle: {
                            toggleSection("recommendations")
                        }
                    )
                }
                
                // Additional Information
                if let additionalInfo = analysis.additionalInfo {
                    ExpandableSection(
                        id: "additional",
                        title: AppStrings.AI.additionalInfo,
                        isExpanded: expandedSections.contains("additional"),
                        content: {
                            AdditionalInfoContent(info: additionalInfo)
                        },
                        onToggle: {
                            toggleSection("additional")
                        }
                    )
                }
                
                // Actions Section
                ActionsSection(analysis: analysis)
                
                // Footer
                AnalysisFooter()
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.large)
        }
        .navigationTitle(AppStrings.Conflicts.analysisDetails)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingShareSheet = true }) {
                        Label(AppStrings.Common.share, systemImage: AppIcons.share)
                    }
                    
                    Button(action: { showingExportOptions = true }) {
                        Label(AppStrings.Common.export, systemImage: AppIcons.download)
                    }
                } label: {
                    Image(systemName: AppIcons.more)
                        .font(AppTheme.Typography.body)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareText = generateShareText() {
                ShareSheet(items: [shareText])
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(analysis: analysis)
        }
        .onAppear {
            analyticsManager.trackFeatureUsed("conflict_analysis_viewed")
        }
    }
    
    // MARK: - Helpers
    
    private func toggleSection(_ section: String) {
        withAnimation(AppTheme.Animation.standard) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func generateShareText() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var shareText = AppStrings.AI.analysisReport + "\n"
        shareText += "\(AppStrings.Common.date): \(dateFormatter.string(from: analysis.timestamp))\n"
        
        if let query = query {
            shareText += "Query: \(query)\n"
        }
        
        shareText += "\n\(AppStrings.AI.summary):\n\(analysis.summary)\n"
        
        if !analysis.conflicts.isEmpty {
            shareText += "\n\(AppStrings.Conflicts.detectedConflicts): \(analysis.conflictCount)\n"
            for conflict in analysis.conflicts {
                shareText += "• \(conflict.drug1) + \(conflict.drug2): \(conflict.description)\n"
            }
        }
        
        if !analysis.recommendations.isEmpty {
            shareText += "\n\(AppStrings.AI.recommendations):\n"
            for (index, recommendation) in analysis.recommendations.enumerated() {
                shareText += "\(index + 1). \(recommendation)\n"
            }
        }
        
        shareText += "\n\(AppStrings.AI.disclaimer)"
        
        return shareText
    }
}

// MARK: - Supporting Views

struct AdditionalInfoContent: View {
    let info: String
    
    var body: some View {
        Text(info)
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.onBackground)
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.surface.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

struct ExportOptionsView: View {
    let analysis: ClaudeAIClient.ConflictAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ExportOptionRow(
                        title: AppStrings.Common.exportPDF,
                        icon: AppIcons.document,
                        action: { exportAsPDF() }
                    )
                    
                    ExportOptionRow(
                        title: AppStrings.Common.exportText,
                        icon: AppIcons.text,
                        action: { exportAsText() }
                    )
                    
                    ExportOptionRow(
                        title: AppStrings.Common.sendToDoctor,
                        icon: AppIcons.doctors,
                        action: { sendToDoctor() }
                    )
                } header: {
                    Text(AppStrings.Common.exportOptions)
                }
            }
            .navigationTitle(AppStrings.Common.export)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func exportAsPDF() {
        // PDF export implementation
        AnalyticsManager.shared.trackFeatureUsed("export_analysis_pdf")
        dismiss()
    }
    
    private func exportAsText() {
        // Text export implementation
        AnalyticsManager.shared.trackFeatureUsed("export_analysis_text")
        dismiss()
    }
    
    private func sendToDoctor() {
        // Send to doctor implementation
        AnalyticsManager.shared.trackFeatureUsed("send_analysis_to_doctor")
        dismiss()
    }
}

struct ExportOptionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 30)
                
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.onBackground)
                
                Spacer()
                
                Image(systemName: AppIcons.chevronRight)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct ConflictAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ConflictAnalysisView(
                analysis: ClaudeAIClient.ConflictAnalysis(
                    conflictsFound: true,
                    severity: .medium,
                    conflicts: [],
                    recommendations: ["Take medication with food", "Monitor blood pressure"],
                    confidence: 0.85,
                    summary: "Sample analysis summary",
                    timestamp: Date(),
                    medicationsAnalyzed: ["Aspirin", "Ibuprofen"]
                ),
                query: "Can I take aspirin with ibuprofen?",
                fromCache: false
            )
        }
    }
}