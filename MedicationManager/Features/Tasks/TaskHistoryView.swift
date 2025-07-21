import SwiftUI

@MainActor
struct TaskHistoryView: View {
    @State private var viewModel = TaskHistoryViewModel()
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedDateRange: DateRange = .week
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Summary Cards
                    summarySection
                    
                    // Filters
                    filterSection
                    
                    // History List
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredCompletions.isEmpty {
                        emptyStateView
                    } else {
                        historyList
                    }
                }
                .padding()
            }
            .navigationTitle(AppStrings.Tasks.taskHistory)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    exportButton
                }
            }
            .task {
                await viewModel.loadHistory(days: selectedDateRange.days)
            }
            .onChange(of: selectedDateRange) { _, newRange in
                Task {
                    await viewModel.loadHistory(days: newRange.days)
                }
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.medium) {
                SummaryCard(
                    title: AppStrings.Tasks.totalCompleted,
                    value: "\(viewModel.totalCompleted)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.success
                )
                
                SummaryCard(
                    title: AppStrings.Tasks.onTimeRate,
                    value: "\(viewModel.onTimePercentage)%",
                    icon: "clock.fill",
                    color: AppTheme.Colors.info
                )
                
                SummaryCard(
                    title: AppStrings.Tasks.averageDelay,
                    value: viewModel.averageDelayText,
                    icon: "timer",
                    color: AppTheme.Colors.warning
                )
                
                if viewModel.mostActiveCaregiver != nil {
                    SummaryCard(
                        title: AppStrings.Tasks.mostActive,
                        value: viewModel.mostActiveCaregiver ?? "",
                        icon: "person.fill",
                        color: AppTheme.Colors.primary
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Date Range Picker
            Picker(AppStrings.Common.dateRange, selection: $selectedDateRange) {
                ForEach(DateRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            // Task Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    FilterChip(
                        title: AppStrings.Common.all,
                        isSelected: selectedFilter == .all,
                        action: { selectedFilter = .all }
                    )
                    
                    ForEach(TaskType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            icon: type.icon,
                            isSelected: selectedFilter == .type(type),
                            action: { selectedFilter = .type(type) }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        LazyVStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(viewModel.groupedCompletions), id: \.key) { (date, completions) in
                Section {
                    ForEach(completions) { completion in
                        CompletionRow(completion: completion)
                    }
                } header: {
                    HStack {
                        Text(formatSectionDate(date))
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Spacer()
                        
                        Text("\(completions.count) \(AppStrings.Tasks.tasks)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top)
                    .padding(.bottom, AppTheme.Spacing.xSmall)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            Text(AppStrings.Common.loading)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.neutral)
            
            Text(AppStrings.Tasks.noHistoryFound)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(AppStrings.Tasks.noTasksCompleted)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var exportButton: some View {
        Menu {
            Button(action: { Task { await viewModel.exportHistory(format: .pdf) } }) {
                Label(AppStrings.Export.pdf, systemImage: "doc.fill")
            }
            
            Button(action: { Task { await viewModel.exportHistory(format: .csv) } }) {
                Label(AppStrings.Export.csv, systemImage: "tablecells.fill")
            }
        } label: {
            Image(systemName: AppIcons.share)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatSectionDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return AppStrings.Common.today
        } else if Calendar.current.isDateInYesterday(date) {
            return AppStrings.Common.yesterday
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding()
        .frame(minWidth: 120)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(AppTheme.Typography.caption)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .foregroundColor(isSelected ? .white : AppTheme.Colors.text)
            .background(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.neutralBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completion Row
struct CompletionRow: View {
    let completion: TaskCompletionRecord
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Task Type Icon
            Image(systemName: completion.taskType.icon)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            // Task Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(completion.taskTitle)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.text)
                
                HStack {
                    Text(completion.completedByName)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text(completion.completedAt.formatted(date: .omitted, time: .shortened))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    if completion.wasLate {
                        Label("\(completion.minutesLate) min late", systemImage: "clock.badge.exclamationmark")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
                
                if let note = completion.note {
                    Text(note)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Status
            if completion.wasLate {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                    .font(.caption)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.success)
                    .font(.caption)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    private var iconColor: Color {
        switch completion.taskType {
        case .criticalMedication:
            return AppTheme.Colors.error
        case .medication:
            return AppTheme.Colors.primary
        case .supplement:
            return AppTheme.Colors.info
        case .meal:
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.textSecondary
        }
    }
}

// MARK: - Supporting Types
enum HistoryFilter: Equatable {
    case all
    case type(TaskType)
}

enum DateRange: String, CaseIterable, Identifiable {
    case today = "today"
    case week = "week"
    case month = "month"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .today:
            return AppStrings.Common.today
        case .week:
            return AppStrings.Common.lastWeek
        case .month:
            return AppStrings.Common.lastMonth
        }
    }
    
    var days: Int {
        switch self {
        case .today:
            return 1
        case .week:
            return 7
        case .month:
            return 30
        }
    }
}

// MARK: - Task Completion Record
struct TaskCompletionRecord: Identifiable {
    let id: String
    let taskId: String
    let taskTitle: String
    let taskType: TaskType
    let completedAt: Date
    let completedBy: String
    let completedByName: String
    let wasLate: Bool
    let minutesLate: Int
    let note: String?
    
    init(from completion: TaskCompletion, task: CaregiverTask) {
        self.id = "\(completion.taskId)_\(completion.completedAt.timeIntervalSince1970)"
        self.taskId = completion.taskId
        self.taskTitle = task.title
        self.taskType = task.type
        self.completedAt = completion.completedAt
        self.completedBy = completion.completedBy
        self.completedByName = completion.completedByName
        self.wasLate = completion.wasLate
        self.minutesLate = completion.minutesLate ?? 0
        self.note = completion.note
    }
}

// MARK: - View Model
@MainActor
@Observable
final class TaskHistoryViewModel {
    // State
    var completions: [TaskCompletionRecord] = []
    var isLoading = false
    var error: Error?
    
    // Computed Properties
    var filteredCompletions: [TaskCompletionRecord] {
        completions // In real implementation, apply filters
    }
    
    var groupedCompletions: [(key: Date, value: [TaskCompletionRecord])] {
        let grouped = Dictionary(grouping: filteredCompletions) { completion in
            Calendar.current.startOfDay(for: completion.completedAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var totalCompleted: Int {
        completions.count
    }
    
    var onTimePercentage: Int {
        guard !completions.isEmpty else { return 100 }
        let onTime = completions.filter { !$0.wasLate }.count
        return Int((Double(onTime) / Double(completions.count)) * 100)
    }
    
    var averageDelayText: String {
        let lateCompletions = completions.filter { $0.wasLate }
        guard !lateCompletions.isEmpty else { return "0 min" }
        
        let totalMinutes = lateCompletions.reduce(0) { $0 + $1.minutesLate }
        let average = totalMinutes / lateCompletions.count
        return "\(average) min"
    }
    
    var mostActiveCaregiver: String? {
        let caregiverCounts = Dictionary(grouping: completions) { $0.completedByName }
            .mapValues { $0.count }
        return caregiverCounts.max { $0.value < $1.value }?.key
    }
    
    // Dependencies
    private let taskManager = CaregiverTaskManager.shared
    private let userModeManager = UserModeManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Load History
    
    func loadHistory(days: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = userModeManager.primaryUserId ?? firebaseManager.currentUser?.id else { return }
        
        do {
            let taskCompletions = try await taskManager.loadTaskHistory(for: userId, days: days)
            
            // Convert to display records
            // In a real implementation, we'd also fetch the task details
            completions = taskCompletions.map { completion in
                // Create a dummy task for display (in real app, fetch actual task)
                let dummyTask = CaregiverTask(
                    primaryUserId: userId,
                    type: .medication,
                    title: "Task \(completion.taskId)",
                    scheduledTime: completion.completedAt
                )
                return TaskCompletionRecord(from: completion, task: dummyTask)
            }
        } catch {
            self.error = error
            print("Error loading task history: \(error)")
        }
    }
    
    // MARK: - Export
    
    func exportHistory(format: ExportFormat) async {
        // In a real implementation, use ExportManager to create PDF/CSV
        print("Exporting history as \(format.rawValue)")
    }
}

#Preview {
    TaskHistoryView()
}
