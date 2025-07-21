import SwiftUI

struct TaskCompletionSheet: View {
    let task: CaregiverTask
    let onComplete: (String?) -> Void
    
    @State private var completionNote = ""
    @State private var showPhotoOption = false
    @State private var capturedImage: UIImage?
    @State private var isCompleting = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Task Details
                    taskDetailsSection
                    
                    // Completion Options
                    completionOptionsSection
                    
                    // Optional Note
                    noteSection
                    
                    // Photo Evidence (if enabled)
                    if showPhotoOption {
                        photoSection
                    }
                    
                    // Important Reminders
                    remindersSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(AppStrings.Tasks.completeTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(isCompleting)
        }
    }
    
    // MARK: - Task Details Section
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Task Type Badge
            HStack {
                Image(systemName: task.type.icon)
                    .foregroundColor(iconColor)
                Text(task.type.displayName)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                // Time Info
                VStack(alignment: .trailing, spacing: 2) {
                    Text(task.displayTime)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    if task.isOverdue {
                        Text(AppStrings.Common.overdue)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.error)
                    }
                }
            }
            
            // Task Title
            Text(task.title)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.text)
            
            // Task Description
            if let description = task.description {
                Text(description)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.neutralBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            // Time Window
            HStack {
                Image(systemName: AppIcons.time)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(AppStrings.Tasks.timeWindow)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(task.windowDisplay)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.text)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    // MARK: - Completion Options Section
    
    private var completionOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Tasks.confirmationRequired)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            // Completion Checklist
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                completionCheckItem(
                    text: confirmationText(for: task.type),
                    icon: "checkmark.circle"
                )
                
                if task.type == .medication || task.type == .criticalMedication {
                    completionCheckItem(
                        text: AppStrings.Tasks.correctDosageGiven,
                        icon: "pills"
                    )
                    
                    completionCheckItem(
                        text: AppStrings.Tasks.noAdverseReaction,
                        icon: "heart"
                    )
                }
                
                if task.type == .meal {
                    completionCheckItem(
                        text: AppStrings.Tasks.mealConsumed,
                        icon: "checkmark.circle"
                    )
                }
            }
            .padding()
            .background(AppTheme.Colors.success.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private func completionCheckItem(text: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.success)
                .frame(width: 20)
            
            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.text)
        }
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Tasks.addNote)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(AppStrings.Tasks.noteOptional)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            TextField(AppStrings.Tasks.notePlaceholder, text: $completionNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Tasks.photoEvidence)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.text)
            
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                Button(action: capturePhoto) {
                    HStack {
                        Image(systemName: "camera")
                        Text(AppStrings.Tasks.takePhoto)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.Colors.neutralBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Reminders Section
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: AppIcons.info)
                    .foregroundColor(AppTheme.Colors.warning)
                Text(AppStrings.Tasks.importantReminders)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                reminderItem(getReminder(for: task.type))
                
                if task.type == .medication || task.type == .criticalMedication {
                    reminderItem(AppStrings.Tasks.checkAllergies)
                }
                
                reminderItem(AppStrings.Tasks.contactPrimaryUser)
            }
            .padding()
            .background(AppTheme.Colors.warning.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    private func reminderItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Text("•")
                .foregroundColor(AppTheme.Colors.warning)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.text)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Complete Button
            Button(action: completeTask) {
                HStack {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(AppStrings.Tasks.markComplete)
                }
                .frame(maxWidth: .infinity)
                .font(AppTheme.Typography.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCompleting)
            
            // Skip Button (if allowed)
            if task.type != .criticalMedication {
                Button(action: skipTask) {
                    Text(AppStrings.Tasks.skipTask)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .disabled(isCompleting)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Helper Methods
    
    private var iconColor: Color {
        switch task.type {
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
    
    private func confirmationText(for type: TaskType) -> String {
        switch type {
        case .medication, .criticalMedication:
            return AppStrings.Tasks.medicationGiven
        case .supplement:
            return AppStrings.Tasks.supplementGiven
        case .meal:
            return AppStrings.Tasks.mealServed
        case .hydration:
            return AppStrings.Tasks.hydrationCompleted
        case .exercise:
            return AppStrings.Tasks.exerciseCompleted
        case .appointment:
            return AppStrings.Tasks.appointmentAttended
        case .other:
            return AppStrings.Tasks.taskCompleted
        }
    }
    
    private func getReminder(for type: TaskType) -> String {
        switch type {
        case .medication, .criticalMedication:
            return AppStrings.Tasks.medicationReminder
        case .meal:
            return AppStrings.Tasks.mealReminder
        default:
            return AppStrings.Tasks.generalReminder
        }
    }
    
    // MARK: - Actions
    
    private func completeTask() {
        isCompleting = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Add small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete(completionNote.isEmpty ? nil : completionNote)
            dismiss()
        }
    }
    
    private func skipTask() {
        // In a real implementation, this would mark the task as skipped
        dismiss()
    }
    
    private func capturePhoto() {
        // In a real implementation, this would open the camera
        // For now, just toggle the option
        showPhotoOption = true
    }
}

#Preview {
    TaskCompletionSheet(
        task: CaregiverTask.sampleMedicationTask,
        onComplete: { _ in }
    )
}
