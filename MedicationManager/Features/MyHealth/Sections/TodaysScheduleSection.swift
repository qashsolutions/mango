import SwiftUI

// MARK: - Today's Schedule Section
struct TodaysScheduleSection: View {
    let medications: [MedicationModel]
    let supplements: [SupplementModel]
    let onMedicationTaken: (MedicationModel) -> Void
    let onSupplementTaken: (SupplementModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            sectionHeader
            
            if medications.isEmpty && supplements.isEmpty {
                emptyState
            } else {
                scheduleContent
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(
            color: AppTheme.Shadow.large.color,
            radius: AppTheme.Shadow.large.radius,
            x: AppTheme.Shadow.large.x,
            y: AppTheme.Shadow.large.y
        )
    }
    
    @ViewBuilder
    private var sectionHeader: some View {
        HStack {
            Text(AppStrings.MyHealth.todaysSchedule)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Spacer()
            
            Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        CompactEmptyState(
            icon: AppIcons.schedule,
            message: AppStrings.MyHealth.noScheduleToday
        )
    }
    
    @ViewBuilder
    private var scheduleContent: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(medications, id: \.id) { medication in
                TodaysScheduleCard(
                    title: medication.name,
                    subtitle: medication.dosage,
                    type: .medication,
                    isCompleted: false, // TODO: Check if taken today
                    nextTime: getNextDoseTime(for: medication),
                    onMarkCompleted: {
                        onMedicationTaken(medication)
                    }
                )
            }
            
            ForEach(supplements, id: \.id) { supplement in
                TodaysScheduleCard(
                    title: supplement.name,
                    subtitle: supplement.dosage,
                    type: .supplement,
                    isCompleted: false, // TODO: Check if taken today
                    nextTime: getNextDoseTime(for: supplement),
                    onMarkCompleted: {
                        onSupplementTaken(supplement)
                    }
                )
            }
        }
    }
    
    private func getNextDoseTime(for medication: MedicationModel) -> Date? {
        medication.schedule.first?.time
    }
    
    private func getNextDoseTime(for supplement: SupplementModel) -> Date? {
        supplement.schedule.first?.time
    }
}

// MARK: - Today's Schedule Card
struct TodaysScheduleCard: View {
    let title: String
    let subtitle: String
    let type: ScheduleItemType
    let isCompleted: Bool
    let nextTime: Date?
    let onMarkCompleted: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Type Icon
            Image(systemName: type.icon)
                .font(AppTheme.Typography.body)
                .foregroundColor(type.color)
                .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
            
            // Content
            contentView
            
            Spacer()
            
            // Completion Button
            completionButton
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(isCompleted ? AppTheme.Colors.successBackground : AppTheme.Colors.background)
        )
        .opacity(isCompleted ? 0.7 : 1.0)
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(1)
            
            HStack(spacing: AppTheme.Spacing.small) {
                Text(subtitle)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                if let nextTime = nextTime {
                    Text("•")
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    
                    Text(nextTime.formatted(.dateTime.hour().minute()))
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
    }
    
    @ViewBuilder
    private var completionButton: some View {
        Button(action: onMarkCompleted) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(AppTheme.Typography.headline)
                .foregroundColor(isCompleted ? AppTheme.Colors.success : AppTheme.Colors.tertiaryText)
        }
        .disabled(isCompleted)
    }
}

enum ScheduleItemType {
    case medication
    case supplement
    
    var icon: String {
        switch self {
        case .medication:
            return AppIcons.medications
        case .supplement:
            return AppIcons.supplements
        }
    }
    
    var color: Color {
        switch self {
        case .medication:
            return AppTheme.Colors.primary
        case .supplement:
            return AppTheme.Colors.secondary
        }
    }
}