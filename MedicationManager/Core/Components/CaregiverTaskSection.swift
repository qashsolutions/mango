import SwiftUI

struct CaregiverTaskSection: View {
    let date: Date
    // iOS 18/Swift 6: Direct reference to @Observable singletons
    private let taskManager = CaregiverTaskManager.shared
    private let userModeManager = UserModeManager.shared
    @State private var showingCompletionSheet = false
    @State private var selectedTask: CaregiverTask?
    @State private var expandedSections: Set<TaskType> = []
    
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            sectionHeader
            
            if taskManager.isLoading {
                loadingView
            } else if taskManager.todayTasks.isEmpty && taskManager.completedTasks.isEmpty {
                emptyStateView
            } else {
                // Group tasks by type
                let groupedTasks = Dictionary(grouping: allTasks) { $0.type }
                
                ForEach(TaskType.allCases, id: \.self) { taskType in
                    if let tasks = groupedTasks[taskType], !tasks.isEmpty {
                        taskTypeSection(type: taskType, tasks: tasks)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCompletionSheet) {
            if let task = selectedTask {
                TaskCompletionSheet(
                    task: task,
                    onComplete: { note in
                        Task {
                            await completeTask(task, note: note)
                        }
                    }
                )
            }
        }
        .task {
            await loadTasks()
        }
        .refreshable {
            await loadTasks()
        }
    }
    
    // MARK: - Computed Properties
    
    private var allTasks: [CaregiverTask] {
        let userId = firebaseManager.currentUser?.id ?? ""
        let allTasks = taskManager.todayTasks + taskManager.completedTasks
        
        if userModeManager.currentMode == .caregiver {
            return taskManager.filterTasksForCaregiver(allTasks, caregiverId: userId)
        }
        return allTasks
    }
    
    private var pendingTasksCount: Int {
        taskManager.todayTasks.count
    }
    
    private var overdueTasksCount: Int {
        taskManager.getOverdueTasks().count
    }
    
    // MARK: - Views
    
    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(dateTitle)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                if userModeManager.currentMode == .caregiver {
                    Text(AppStrings.Tasks.todayOnlyNotice)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Task summary badges
            HStack(spacing: AppTheme.Spacing.small) {
                if overdueTasksCount > 0 {
                    taskBadge(
                        count: overdueTasksCount,
                        label: AppStrings.Common.overdue,
                        color: AppTheme.Colors.error
                    )
                }
                
                taskBadge(
                    count: pendingTasksCount,
                    label: AppStrings.Common.pending,
                    color: AppTheme.Colors.warning
                )
                
                taskBadge(
                    count: taskManager.completedTasks.count,
                    label: AppStrings.Common.completed,
                    color: AppTheme.Colors.success
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func taskBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(AppTheme.Typography.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppTheme.Typography.caption2)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.success)
            
            Text(AppStrings.Tasks.noTasksToday)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(AppStrings.Tasks.allCaughtUp)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .padding(.horizontal)
    }
    
    private func taskTypeSection(type: TaskType, tasks: [CaregiverTask]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Section header
            Button(action: { toggleSection(type) }) {
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(iconColor(for: type))
                    
                    Text(type.displayName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                    
                    Text("\(tasks.count)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.xSmall)
                        .background(AppTheme.Colors.neutralBackground)
                        .cornerRadius(AppTheme.CornerRadius.extraSmall)
                    
                    Image(systemName: expandedSections.contains(type) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal)
                .padding(.vertical, AppTheme.Spacing.small)
            }
            .buttonStyle(.plain)
            
            if expandedSections.contains(type) {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(tasks.sorted(by: { $0.scheduledTime < $1.scheduledTime })) { task in
                        TaskCard(
                            task: task,
                            canComplete: userModeManager.canCompleteTask(task),
                            onTap: {
                                if userModeManager.canCompleteTask(task) && !task.isCompleted {
                                    selectedTask = task
                                    showingCompletionSheet = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var dateTitle: String {
        if Calendar.current.isDateInToday(date) {
            return AppStrings.Common.today
        } else {
            return date.formatted(date: .complete, time: .omitted)
        }
    }
    
    private func iconColor(for type: TaskType) -> Color {
        switch type {
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
    
    private func toggleSection(_ type: TaskType) {
        withAnimation(.spring(response: 0.3)) {
            if expandedSections.contains(type) {
                expandedSections.remove(type)
            } else {
                expandedSections.insert(type)
            }
        }
    }
    
    private func loadTasks() async {
        guard let userId = userModeManager.primaryUserId ?? firebaseManager.currentUser?.id else { return }
        
        do {
            try await taskManager.loadTasks(for: userId, date: date)
            
            // Auto-expand sections with pending tasks
            let pendingTypes = Set(taskManager.todayTasks.map { $0.type })
            expandedSections = expandedSections.union(pendingTypes)
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    private func completeTask(_ task: CaregiverTask, note: String?) async {
        guard let userId = firebaseManager.currentUser?.id,
              let userName = userModeManager.caregiverInfo?.displayName ?? firebaseManager.currentUser?.displayName else { return }
        
        do {
            try await taskManager.completeTask(
                task,
                completedBy: userId,
                caregiverName: userName,
                note: note
            )
            
            // Haptic feedback
            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        } catch {
            print("Error completing task: \(error)")
        }
    }
}

// MARK: - Task Card
struct TaskCard: View {
    let task: CaregiverTask
    let canComplete: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Status indicator
                statusIndicator
                
                // Task info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text(task.title)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.text)
                        .strikethrough(task.isCompleted)
                    
                    HStack {
                        Text(task.displayTime)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(timeColor)
                        
                        if task.isCompleted, let completedBy = task.completedByName {
                            Text("• \(completedBy)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        
                        if task.isOverdue && !task.isCompleted {
                            Label(AppStrings.Common.overdue, systemImage: "exclamationmark.circle.fill")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.error)
                        }
                    }
                    
                    if let description = task.description {
                        Text(description)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Action indicator
                if canComplete && !task.isCompleted {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: task.isOverdue && !task.isCompleted ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canComplete || task.isCompleted)
    }
    
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .stroke(indicatorColor, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            if task.isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(indicatorColor)
            }
        }
    }
    
    private var indicatorColor: Color {
        if task.isCompleted {
            return AppTheme.Colors.success
        } else if task.isOverdue {
            return AppTheme.Colors.error
        } else if task.isInWindow {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.inactive
        }
    }
    
    private var timeColor: Color {
        if task.isCompleted {
            return AppTheme.Colors.success
        } else if task.isOverdue {
            return AppTheme.Colors.error
        } else if task.isInWindow {
            return AppTheme.Colors.warning
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
    
    private var backgroundColor: Color {
        if task.isCompleted {
            return AppTheme.Colors.success.opacity(0.05)
        } else if task.isOverdue {
            return AppTheme.Colors.error.opacity(0.05)
        } else {
            return AppTheme.Colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        task.isOverdue && !task.isCompleted ? AppTheme.Colors.error.opacity(0.3) : Color.clear
    }
}

#Preview {
    ScrollView {
        CaregiverTaskSection(date: Date())
            .padding()
    }
}
