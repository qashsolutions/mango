import SwiftUI

struct MedicationCard: View {
    let medication: MedicationModel
    let onTap: () -> Void
    let onTakeAction: (() -> Void)?
    let onEditAction: (() -> Void)?
    
    @State private var showingTakeConfirmation: Bool = false
    @State private var showingMenu: Bool = false
    
    init(
        medication: MedicationModel,
        onTap: @escaping () -> Void,
        onTakeAction: (() -> Void)? = nil,
        onEditAction: (() -> Void)? = nil
    ) {
        self.medication = medication
        self.onTap = onTap
        self.onTakeAction = onTakeAction
        self.onEditAction = onEditAction
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header Row
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                        Text(medication.name)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.onSurface)
                            .lineLimit(1)
                        
                        Text("\(medication.dosage) • \(medication.frequency.displayName)")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        if medication.voiceEntryUsed {
                            Image(systemName: AppIcons.voice)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.info)
                        }
                        
                        statusIndicator(medication: medication)
                        
                        menuButton()
                    }
                }
                
                // Schedule Information
                if !medication.schedule.isEmpty {
                    scheduleRow(schedule: medication.schedule)
                }
                
                // Quick Actions
                if medication.isActive {
                    actionButtons()
                }
                
                // Additional Info
                if let notes = medication.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(
                color: AppTheme.Shadow.medium.color,
                radius: AppTheme.Shadow.medium.radius,
                x: AppTheme.Shadow.medium.x,
                y: AppTheme.Shadow.medium.y
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuContent()
        }
        .alert(AppStrings.Medications.confirmTake, isPresented: $showingTakeConfirmation) {
            Button(AppStrings.Common.confirm) {
                onTakeAction?()
                AnalyticsManager.shared.trackMedicationTaken(onTime: true)
            }
            Button(AppStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.Medications.confirmTakeMessage(medication.name))
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func statusIndicator(medication: MedicationModel) -> some View {
        Circle()
            .fill(statusColor)
            .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
            .overlay(
                Circle()
                    .stroke(statusBorderColor, lineWidth: 1)
            )
    }
    
    @ViewBuilder
    private func menuButton() -> some View {
        Button(action: { showingMenu.toggle() }) {
            Image(systemName: "ellipsis")
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func scheduleRow(schedule: [MedicationSchedule]) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: AppIcons.schedule)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
            
            Text(scheduleText)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                .lineLimit(1)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            if let onTakeAction = onTakeAction {
                Button(action: {
                    // First call the parent callback
                    onTakeAction()
                    // Then show user confirmation
                    showingTakeConfirmation = true
                }) {
                    HStack(spacing: AppTheme.Spacing.extraSmall) {
                        Image(systemName: AppIcons.success)
                            .font(AppTheme.Typography.caption)
                        Text(AppStrings.Medications.markTaken)
                            .font(AppTheme.Typography.caption1)
                    }
                    .foregroundColor(AppTheme.Colors.success)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.extraSmall)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(AppTheme.Colors.success.opacity(AppTheme.Opacity.low))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            nextDoseInfo()
        }
    }
    
    @ViewBuilder
    private func nextDoseInfo() -> some View {
        if let nextDose = getNextDoseTime() {
            HStack(spacing: AppTheme.Spacing.extraSmall) {
                Image(systemName: AppIcons.schedule)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                
                Text(AppStrings.Medications.nextDose(formattedNextDoseTime(nextDose)))
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
            }
        }
    }
    
    @ViewBuilder
    private func notesSection(notes: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.extraSmall) {
            Image(systemName: AppIcons.info)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                .padding(.top, 2)
            
            Text(notes)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                .lineLimit(2)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func contextMenuContent() -> some View {
        if let onTakeAction = onTakeAction {
            Button(action: onTakeAction) {
                Label(AppStrings.Medications.markTaken, systemImage: AppIcons.success)
            }
        }
        
        if let onEditAction = onEditAction {
            Button(action: onEditAction) {
                Label(AppStrings.Common.edit, systemImage: AppIcons.edit)
            }
        }
        
        Button(action: {
            AnalyticsManager.shared.trackFeatureUsed("medication_share")
        }) {
            Label(AppStrings.Common.share, systemImage: AppIcons.add) // Using available icon
        }
    }
    
    // MARK: - Computed Properties
    private var statusColor: Color {
        if !medication.isActive {
            // Inactive medications show gray status
            return AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.low)
        } else if hasUpcomingDose {
            // Upcoming dose within 1 hour shows warning color
            return AppTheme.Colors.warning
        } else {
            // Normal active medication shows success color
            return AppTheme.Colors.success
        }
    }
    
    private var statusBorderColor: Color {
        statusColor.opacity(AppTheme.Opacity.low)
    }
    
    private var borderColor: Color {
        if !medication.isActive {
            // Inactive medications have more prominent border
            return AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.low)
        } else {
            // Active medications have subtle border
            return AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.low)
        }
    }
    
    private var borderWidth: CGFloat {
        medication.isActive ? 1.0 : 1.5
    }
    
    private var scheduleText: String {
        if medication.schedule.isEmpty {
            return AppStrings.Medications.noScheduleSet
        }
        
        // Filter for active schedule items using schema logic: !isCompleted && !skipped
        let activeTimes = medication.schedule.filter { !$0.isCompleted && !$0.skipped }
        if activeTimes.isEmpty {
            return AppStrings.Medications.noActiveTimes
        }
        
        if activeTimes.count == 1, let firstTime = activeTimes.first {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return AppStrings.Medications.nextAt(formatter.string(from: firstTime.time))
        } else {
            return AppStrings.Medications.multipleTimesPerDay(activeTimes.count)
        }
    }
    
    private var hasUpcomingDose: Bool {
        guard let nextDose = getNextDoseTime() else { return false }
        let timeUntilDose = nextDose.timeIntervalSinceNow
        return timeUntilDose <= 3600 && timeUntilDose > 0 // Within 1 hour
    }
    
    // MARK: - Helper Methods
    private func getNextDoseTime() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter for active schedule items using schema logic: !isCompleted && !skipped
        let activeTimes = medication.schedule.filter { !$0.isCompleted && !$0.skipped }
        guard !activeTimes.isEmpty else { return nil }
        
        var nextTimes: [Date] = []
        
        for scheduleItem in activeTimes {
            // Get today's dose time
            if let todayDose = calendar.date(
                bySettingHour: calendar.component(.hour, from: scheduleItem.time),
                minute: calendar.component(.minute, from: scheduleItem.time),
                second: 0,
                of: now
            ) {
                if todayDose > now {
                    nextTimes.append(todayDose)
                } else {
                    // Add tomorrow's dose
                    if let tomorrowDose = calendar.date(byAdding: .day, value: 1, to: todayDose) {
                        nextTimes.append(tomorrowDose)
                    }
                }
            }
        }
        
        return nextTimes.min()
    }
    
    private func formattedNextDoseTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Medication Card
struct CompactMedicationCard: View {
    let medication: MedicationModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(medication.name)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.onSurface)
                        .lineLimit(1)
                    
                    Text(medication.dosage)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.high))
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.small) {
                    if medication.voiceEntryUsed {
                        Image(systemName: AppIcons.voice)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.info)
                    }
                    
                    Circle()
                        .fill(medication.isActive ? AppTheme.Colors.success : AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.low))
                        .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
                    
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.onSurface.opacity(AppTheme.Opacity.medium))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Medication List Card
struct MedicationListCard: View {
    let medications: [MedicationModel]
    let title: String
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.onSurface)
                
                Spacer()
                
                Button(AppStrings.Common.viewAll, action: onViewAll)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            if medications.isEmpty {
                EmptyStateView(
                    icon: AppIcons.medication,
                    title: AppStrings.Medications.noMedications,
                    message: AppStrings.Medications.noMedicationsMessage
                )
                .frame(maxHeight: 100)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(medications.prefix(3), id: \.id) { medication in
                        CompactMedicationCard(medication: medication) {
                            AnalyticsManager.shared.trackFeatureUsed("medication_card_tap")
                        }
                    }
                    
                    if medications.count > 3 {
                        Button(AppStrings.Common.viewAllCount(medications.count - 3)) {
                            onViewAll()
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(
            color: AppTheme.Shadow.medium.color,
            radius: AppTheme.Shadow.medium.radius,
            x: AppTheme.Shadow.medium.x,
            y: AppTheme.Shadow.medium.y
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.large) {
            MedicationCard(
                medication: MedicationModel.sampleMedication,
                onTap: {},
                onTakeAction: {},
                onEditAction: {}
            )
            
            CompactMedicationCard(
                medication: MedicationModel.sampleMedication,
                onTap: {}
            )
            
            MedicationListCard(
                medications: MedicationModel.sampleMedications,
                title: "Today's Medications",
                onViewAll: {}
            )
        }
        .padding()
    }
    .background(AppTheme.Colors.background)
}
