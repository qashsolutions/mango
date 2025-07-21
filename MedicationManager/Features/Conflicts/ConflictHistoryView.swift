import SwiftUI

struct ConflictHistoryView: View {
    let analysisHistory: [ConflictDetectionManager.MedicationConflictAnalysis]
    let onSelectAnalysis: (ConflictDetectionManager.MedicationConflictAnalysis) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedTimeFilter: TimeFilter = .all
    @State private var selectedSeverityFilter: SeverityFilter = .all
    @State private var showingClearConfirmation: Bool = false
    @State private var showingExportOptions: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    private let analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Header
            customNavigationHeader
            
            // Search Bar
            searchBar
            
            // Filters Section
            searchAndFiltersSection
            
            // Content
            if filteredHistory.isEmpty {
                emptyHistoryView
            } else {
                historyList
            }
        }
        .background(AppTheme.Colors.background)
        .alert(AppStrings.Conflicts.History.clearHistory, isPresented: $showingClearConfirmation) {
            Button(AppStrings.Common.clear, role: .destructive) {
                clearHistory()
            }
            Button(AppStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.Common.confirmDeleteMessage)
        }
        .sheet(isPresented: $showingExportOptions) {
            HistoryExportView(analysisHistory: filteredHistory)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            analyticsManager.trackFeatureUsed("conflict_history_viewed")
        }
    }
    
    
    // MARK: - Custom Navigation Header
    @ViewBuilder
    private var customNavigationHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Text(AppStrings.Common.done)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: { showingExportOptions = true }) {
                        Label(AppStrings.Common.export, systemImage: AppIcons.download)
                    }
                    
                    Button(role: .destructive, action: { showingClearConfirmation = true }) {
                        Label(AppStrings.Conflicts.History.clearHistory, systemImage: AppIcons.delete)
                    }
                    .disabled(analysisHistory.isEmpty)
                } label: {
                    Image(systemName: AppIcons.more)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, AppTheme.Spacing.small)
            
            Text(AppStrings.Conflicts.History.exportHistory)
                .font(AppTheme.Typography.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.small)
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: AppIcons.search)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            TextField(AppStrings.Common.search, text: $searchText)
                .font(AppTheme.Typography.body)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: AppIcons.close)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .font(AppTheme.Typography.caption)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.small)
        .padding(.horizontal)
        .padding(.bottom, AppTheme.Spacing.small)
    }
    
    // MARK: - Search and Filters
    @ViewBuilder
    private var searchAndFiltersSection: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    // Time Filter
                    FilterMenu(
                        title: selectedTimeFilter.displayName,
                        icon: AppIcons.schedule,
                        options: TimeFilter.allCases,
                        selection: $selectedTimeFilter
                    )
                    
                    // Severity Filter
                    FilterMenu(
                        title: selectedSeverityFilter.displayName,
                        icon: AppIcons.warning,
                        options: SeverityFilter.allCases,
                        selection: $selectedSeverityFilter
                    )
                    
                    // Results Count
                    if !filteredHistory.isEmpty {
                        ResultsCountPill(count: filteredHistory.count)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .padding(.vertical, AppTheme.Spacing.small)
            
            Divider()
        }
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - History List
    @ViewBuilder
    private var historyList: some View {
        let sortedDates = groupedHistory.keys.sorted(by: >)
        List {
            ForEach(sortedDates, id: \.self) { date in
                Section {
                    ForEach(groupedHistory[date] ?? [], id: \.self) { analysis in
                        HistoryRow(
                            analysis: analysis,
                            onTap: {
                                onSelectAnalysis(analysis)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Text(formatSectionDate(date))
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Empty History
    @ViewBuilder
    private var emptyHistoryView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            if searchText.isEmpty && selectedTimeFilter == .all && selectedSeverityFilter == .all {
                EmptyStateView(
                    icon: AppIcons.history,
                    title: AppStrings.Conflicts.History.noHistory,
                    message: AppStrings.Conflicts.History.noHistoryMessage
                )
            } else {
                SearchEmptyState(searchTerm: searchText)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
    
    // MARK: - Computed Properties
    private var filteredHistory: [ConflictDetectionManager.MedicationConflictAnalysis] {
        analysisHistory.filter { analysis in
            // Search filter
            let matchesSearch = searchText.isEmpty || 
                analysis.summary.localizedCaseInsensitiveContains(searchText) ||
                analysis.medicationsAnalyzed.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            // Time filter
            let matchesTime = selectedTimeFilter.matches(analysis.timestamp)
            
            // Severity filter
            let matchesSeverity = selectedSeverityFilter.matches(ConflictSeverity(rawValue: analysis.severity.rawValue) ?? .low)
            
            return matchesSearch && matchesTime && matchesSeverity
        }
    }
    
    private var groupedHistory: [Date: [ConflictDetectionManager.MedicationConflictAnalysis]] {
        Dictionary(grouping: filteredHistory) { analysis in
            Calendar.current.startOfDay(for: analysis.timestamp)
        }
    }
    
    // MARK: - Actions
    private func clearHistory() {
        // This would be handled by the parent view/view model
        analyticsManager.trackFeatureUsed("conflict_history_cleared")
        dismiss()
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return AppStrings.Common.today
        } else if calendar.isDateInYesterday(date) {
            return AppStrings.Common.yesterday
        } else {
            return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        }
    }
}

// MARK: - Filter Types
enum TimeFilter: String, CaseIterable {
    case all
    case today
    case week
    case month
    
    var displayName: String {
        switch self {
        case .all: return AppStrings.Common.all
        case .today: return AppStrings.Common.today
        case .week: return AppStrings.Common.lastWeek
        case .month: return AppStrings.Common.lastMonth
        }
    }
    
    func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        }
    }
}

enum SeverityFilter: String, CaseIterable {
    case all
    case critical
    case high
    case medium
    case low
    
    var displayName: String {
        switch self {
        case .all: return AppStrings.Common.all
        case .critical: return ConflictSeverity.critical.displayName
        case .high: return ConflictSeverity.high.displayName
        case .medium: return ConflictSeverity.medium.displayName
        case .low: return ConflictSeverity.low.displayName
        }
    }
    
    func matches(_ severity: ConflictSeverity) -> Bool {
        switch self {
        case .all:
            return true
        case .critical:
            return severity == .critical
        case .high:
            return severity == .high
        case .medium:
            return severity == .medium
        case .low:
            return severity == .low || severity == .none
        }
    }
}

// MARK: - Supporting Components
struct FilterMenu<T: CaseIterable & RawRepresentable>: View where T.RawValue == String, T: CustomStringConvertible {
    let title: String
    let icon: String
    let options: [T]
    @Binding var selection: T
    
    var body: some View {
        Menu {
            ForEach(options, id: \.rawValue) { option in
                Button(action: { selection = option }) {
                    if selection == option {
                        Label(option.description, systemImage: AppIcons.success)
                    } else {
                        Text(option.description)
                    }
                }
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.extraSmall) {
                Image(systemName: icon)
                    .font(AppTheme.Typography.caption)
                Text(title)
                    .font(AppTheme.Typography.caption1)
                Image(systemName: AppIcons.chevronDown)
                    .font(AppTheme.Typography.caption)
            }
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.Colors.primaryBackground)
            .cornerRadius(AppTheme.CornerRadius.pill)
        }
    }
}

extension TimeFilter: CustomStringConvertible {
    var description: String { displayName }
}

extension SeverityFilter: CustomStringConvertible {
    var description: String { displayName }
}

struct ResultsCountPill: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(AppTheme.Typography.caption1)
            .foregroundColor(AppTheme.Colors.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.pill)
    }
}

struct HistoryRow: View {
    let analysis: ConflictDetectionManager.MedicationConflictAnalysis
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Severity Indicator
                ConflictSeverityBadge(
                    severity: ConflictSeverity(rawValue: analysis.severity.rawValue) ?? .low,
                    size: .small,
                    showLabel: false
                )
                
                // Content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(analysis.summary)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .lineLimit(2)
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        // Time
                        Text(analysis.timestamp.formatted(.dateTime.hour().minute()))
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        // Separator
                        Text("•")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                        
                        // Conflicts count
                        if analysis.conflictCount > 0 {
                            ConflictCountBadge(
                                count: analysis.conflictCount,
                                severity: ConflictSeverity(rawValue: analysis.overallSeverity.rawValue)
                            )
                        } else {
                            Text(AppStrings.Conflicts.noConflicts)
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(AppTheme.Colors.success)
                        }
                        
                        // Cache indicator
                        if analysis.fromCache {
                            CacheBadge()
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: AppIcons.chevronRight)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - History Export View
struct HistoryExportView: View {
    let analysisHistory: [ConflictDetectionManager.MedicationConflictAnalysis]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .pdf
    @State private var includeDetails: Bool = true
    @State private var isExporting: Bool = false
    
    enum ExportFormat: String, CaseIterable {
        case pdf
        case csv
        case text
        
        var displayName: String {
            switch self {
            case .pdf: return AppStrings.Export.pdf
            case .csv: return AppStrings.Export.csv
            case .text: return AppStrings.Common.exportText
            }
        }
        
        var icon: String {
            switch self {
            case .pdf: return AppIcons.document
            case .csv: return AppIcons.document
            case .text: return AppIcons.text
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                exportOptionsSection
                
                analysisCountSection
                
                exportButtonSection
            }
            .navigationTitle(AppStrings.Conflicts.History.exportHistory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder
    private var exportOptionsSection: some View {
        Section {
            Picker(AppStrings.Export.exportFormat, selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Label(format.displayName, systemImage: format.icon)
                        .tag(format)
                }
            }
            
            Toggle("Include Details", isOn: $includeDetails)
        } header: {
            Text(AppStrings.Export.exportOptions)
        }
    }
    
    @ViewBuilder
    private var analysisCountSection: some View {
        Section {
            HStack {
                Text(AppStrings.Conflicts.History.totalAnalyses)
                Spacer()
                Text("\(analysisHistory.count)")
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .font(AppTheme.Typography.caption1)
        }
    }
    
    @ViewBuilder
    private var exportButtonSection: some View {
        Section {
            Button(action: performExport) {
                if isExporting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        Text(AppStrings.Common.exporting)
                            .font(AppTheme.Typography.body)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(AppStrings.Common.export)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Layout.buttonHeight)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            .disabled(isExporting || analysisHistory.isEmpty)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    private func performExport() {
        isExporting = true
        
        Task {
            // Simulate export delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isExporting = false
                AnalyticsManager.shared.trackFeatureUsed("conflict_history_exported_\(exportFormat.rawValue)")
                dismiss()
            }
        }
    }
}

struct ConflictHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ConflictHistoryView(
            analysisHistory: [],
            onSelectAnalysis: { _ in }
        )
    }
}
