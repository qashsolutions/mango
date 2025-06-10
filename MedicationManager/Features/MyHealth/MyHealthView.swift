import SwiftUI

struct MyHealthView: View {
    @StateObject private var viewModel = MyHealthViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var showingAddMenu: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.large) {
                    // Sync Status Header
                    SyncStatusHeader()
                    
                    // Today's Schedule Section
                    TodaysScheduleSection(
                        medications: viewModel.todaysMedications,
                        supplements: viewModel.todaysSupplements,
                        onMedicationTaken: { medication in
                            Task {
                                await viewModel.markMedicationTaken(medication)
                            }
                        },
                        onSupplementTaken: { supplement in
                            Task {
                                await viewModel.markSupplementTaken(supplement)
                            }
                        }
                    )
                    
                    // Medications Section
                    MedicationsSection(
                        medications: viewModel.medications,
                        onMedicationTap: { medication in
                            navigationManager.navigate(to: .medicationDetail(id: medication.id))
                        },
                        onEditMedication: { medication in
                            navigationManager.presentSheet(.editMedication(id: medication.id))
                        },
                        onAddMedication: {
                            navigationManager.presentSheet(.addMedication(voiceText: nil))
                        }
                    )
                    
                    // Supplements Section
                    SupplementsSection(
                        supplements: viewModel.supplements,
                        onSupplementTap: { supplement in
                            navigationManager.navigate(to: .supplementDetail(id: supplement.id))
                        },
                        onEditSupplement: { supplement in
                            navigationManager.presentSheet(.editSupplement(id: supplement.id))
                        },
                        onAddSupplement: {
                            navigationManager.presentSheet(.addSupplement(voiceText: nil))
                        }
                    )
                    
                    // Diet Section
                    DietSection(
                        dietEntries: viewModel.todaysDietEntries,
                        onDietEntryTap: { entry in
                            navigationManager.navigate(to: .dietEntryDetail(id: entry.id))
                        },
                        onAddDietEntry: {
                            navigationManager.presentSheet(.addDietEntry(voiceText: nil))
                        }
                    )
                    
                    // Quick Actions Section
                    QuickActionsSection()
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationTitle(AppStrings.Tabs.myHealth)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        SyncActionButton()
                        
                        Button(action: { showingAddMenu.toggle() }) {
                            Image(systemName: AppIcons.plus)
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                }
            }
            .confirmationDialog(AppStrings.MyHealth.addNewItem, isPresented: $showingAddMenu) {
                Button(AppStrings.Medications.addMedication) {
                    navigationManager.presentSheet(.addMedication(voiceText: nil))
                }
                
                Button(AppStrings.Supplements.addSupplement) {
                    navigationManager.presentSheet(.addSupplement(voiceText: nil))
                }
                
                Button(AppStrings.Diet.addDietEntry) {
                    navigationManager.presentSheet(.addDietEntry(voiceText: nil))
                }
                
                Button(AppStrings.Common.cancel, role: .cancel) {}
            }
        }
        .task {
            await viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await viewModel.refreshData()
            }
        }
    }
}

// MARK: - Sync Status Header
struct SyncStatusHeader: View {
    @StateObject private var dataSync = DataSyncManager.shared
    
    var body: some View {
        if !dataSync.isOnline || dataSync.syncError != nil {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: dataSync.isOnline ? "exclamationmark.triangle.fill" : "wifi.slash")
                    .font(.system(size: 14))
                    .foregroundColor(dataSync.isOnline ? AppTheme.Colors.warning : AppTheme.Colors.error)
                
                Text(dataSync.isOnline ? AppStrings.Sync.syncIssues : AppStrings.Sync.offline)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Spacer()
                
                SyncStatusView()
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.warningBackground)
            )
        }
    }
}

// MARK: - Today's Schedule Section
struct TodaysScheduleSection: View {
    let medications: [Medication]
    let supplements: [Supplement]
    let onMedicationTaken: (Medication) -> Void
    let onSupplementTaken: (Supplement) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.MyHealth.todaysSchedule)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            if medications.isEmpty && supplements.isEmpty {
                CompactEmptyState(
                    icon: AppIcons.schedule,
                    message: AppStrings.MyHealth.noScheduleToday
                )
            } else {
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
    
    private func getNextDoseTime(for medication: Medication) -> Date? {
        medication.schedule.first?.time
    }
    
    private func getNextDoseTime(for supplement: Supplement) -> Date? {
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
                .frame(width: 24, height: 24)
            
            // Content
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
            
            Spacer()
            
            // Completion Button
            Button(action: onMarkCompleted) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isCompleted ? AppTheme.Colors.success : AppTheme.Colors.tertiaryText)
            }
            .disabled(isCompleted)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(isCompleted ? AppTheme.Colors.successBackground : AppTheme.Colors.background)
        )
        .opacity(isCompleted ? 0.7 : 1.0)
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

// MARK: - Medications Section
struct MedicationsSection: View {
    let medications: [Medication]
    let onMedicationTap: (Medication) -> Void
    let onEditMedication: (Medication) -> Void
    let onAddMedication: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(
                title: AppStrings.Medications.medications,
                subtitle: AppStrings.Medications.medicationCount(medications.count),
                onAdd: onAddMedication
            )
            
            if medications.isEmpty {
                MedicationEmptyState(onAddMedication: onAddMedication)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(medications.prefix(5), id: \.id) { medication in
                        MedicationCard(
                            medication: medication,
                            onTap: { onMedicationTap(medication) },
                            onTakeAction: {
                                // Handle take action
                            },
                            onEditAction: { onEditMedication(medication) }
                        )
                    }
                    
                    if medications.count > 5 {
                        Button(AppStrings.Common.viewAllCount(medications.count - 5)) {
                            // Navigate to full medications list
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
            }
        }
    }
}

// MARK: - Supplements Section
struct SupplementsSection: View {
    let supplements: [Supplement]
    let onSupplementTap: (Supplement) -> Void
    let onEditSupplement: (Supplement) -> Void
    let onAddSupplement: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(
                title: AppStrings.Supplements.supplements,
                subtitle: AppStrings.Supplements.supplementCount(supplements.count),
                onAdd: onAddSupplement
            )
            
            if supplements.isEmpty {
                SupplementEmptyState(onAddSupplement: onAddSupplement)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(supplements.prefix(3), id: \.id) { supplement in
                        SupplementCard(
                            supplement: supplement,
                            onTap: { onSupplementTap(supplement) },
                            onTakeAction: {
                                // Handle take action
                            },
                            onEditAction: { onEditSupplement(supplement) }
                        )
                    }
                    
                    if supplements.count > 3 {
                        Button(AppStrings.Common.viewAllCount(supplements.count - 3)) {
                            // Navigate to full supplements list
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
            }
        }
    }
}

// MARK: - Diet Section
struct DietSection: View {
    let dietEntries: [DietEntry]
    let onDietEntryTap: (DietEntry) -> Void
    let onAddDietEntry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            SectionHeader(
                title: AppStrings.Diet.todaysNutrition,
                subtitle: AppStrings.Diet.mealCount(dietEntries.count),
                onAdd: onAddDietEntry
            )
            
            if dietEntries.isEmpty {
                DietEmptyState(onAddEntry: onAddDietEntry)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    // Calorie Summary
                    CalorieSummaryCard(dietEntries: dietEntries)
                    
                    // Recent Meals
                    ForEach(dietEntries.prefix(3), id: \.id) { entry in
                        DietEntryCard(
                            dietEntry: entry,
                            onTap: { onDietEntryTap(entry) }
                        )
                    }
                    
                    if dietEntries.count > 3 {
                        Button(AppStrings.Common.viewAllCount(dietEntries.count - 3)) {
                            // Navigate to full diet list
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @StateObject private var navigationManager = NavigationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.MyHealth.quickActions)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppTheme.Spacing.medium) {
                QuickActionCard(
                    icon: AppIcons.conflicts,
                    title: AppStrings.Conflicts.checkConflicts,
                    subtitle: AppStrings.Conflicts.checkConflictsSubtitle,
                    color: AppTheme.Colors.warning
                ) {
                    navigationManager.presentSheet(.medicationConflictCheck)
                }
                
                QuickActionCard(
                    icon: AppIcons.voiceInput,
                    title: AppStrings.Voice.quickEntry,
                    subtitle: AppStrings.Voice.quickEntrySubtitle,
                    color: AppTheme.Colors.voiceActive
                ) {
                    navigationManager.presentSheet(.voiceInput(context: .general))
                }
                
                QuickActionCard(
                    icon: AppIcons.doctors,
                    title: AppStrings.Doctors.contactDoctor,
                    subtitle: AppStrings.Doctors.contactDoctorSubtitle,
                    color: AppTheme.Colors.secondary
                ) {
                    navigationManager.selectTab(.doctorList)
                }
                
                QuickActionCard(
                    icon: AppIcons.caregivers,
                    title: AppStrings.Caregivers.manageAccess,
                    subtitle: AppStrings.Caregivers.manageAccessSubtitle,
                    color: AppTheme.Colors.primary
                ) {
                    navigationManager.selectTab(.groups)
                }
            }
        }
    }
}

// MARK: - Helper Components
struct SectionHeader: View {
    let title: String
    let subtitle: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: AppIcons.plus)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
}

// MARK: - Dedicated Supplement Card
struct SupplementCard: View {
    let supplement: Supplement
    let onTap: () -> Void
    let onTakeAction: () -> Void
    let onEditAction: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Supplement Icon
                Image(systemName: AppIcons.supplements)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppTheme.Colors.secondary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(20)
                
                // Supplement Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(supplement.name)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        Text(supplement.dosage)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Text("•")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                        
                        Text(supplement.displayFrequency)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    if let purpose = supplement.purpose {
                        Text(purpose)
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Next dose indicator and action button
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
                    if let nextDose = supplement.nextDose {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next")
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                            
                            Text(nextDose.time.formatted(.dateTime.hour().minute()))
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                    }
                    
                    Button(action: onTakeAction) {
                        Image(systemName: supplement.isDueToday ? "circle" : "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(supplement.isDueToday ? AppTheme.Colors.secondary : AppTheme.Colors.success)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onTakeAction) {
                Label("Mark as Taken", systemImage: "checkmark.circle")
            }
            
            Button(action: onEditAction) {
                Label("Edit Supplement", systemImage: "pencil")
            }
        }
    }
}

// MARK: - Enhanced Diet Entry Card
struct DietEntryCard: View {
    let dietEntry: DietEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Meal Type Icon
                Image(systemName: dietEntry.mealType.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.primaryBackground)
                    .cornerRadius(18)
                
                // Meal Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(dietEntry.mealType.displayName)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    HStack(spacing: AppTheme.Spacing.small) {
                        Text("\(dietEntry.totalCalories) calories")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Text("•")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                        
                        Text("\(dietEntry.foods.count) items")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    // Show first few foods
                    if !dietEntry.foods.isEmpty {
                        Text(dietEntry.foods.prefix(2).map { $0.name }.joined(separator: ", "))
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
                    if let time = dietEntry.actualTime ?? dietEntry.scheduledTime {
                        Text(time.formatted(.dateTime.hour().minute()))
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Calorie Summary Card
struct CalorieSummaryCard: View {
    let dietEntries: [DietEntry]
    
    private var totalCalories: Int {
        dietEntries.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var mealBreakdown: [(String, Int)] {
        let grouped = Dictionary(grouping: dietEntries) { $0.mealType }
        return grouped.compactMap { (type, entries) in
            let calories = entries.reduce(0) { $0 + $1.totalCalories }
            return (type.displayName, calories)
        }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Main calorie info
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(AppStrings.Diet.totalCalories)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Text("\(totalCalories)")
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
                    Text(AppStrings.Diet.mealsLogged)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Text("\(dietEntries.count)")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .fontWeight(.medium)
                }
            }
            
            // Meal breakdown
            if !mealBreakdown.isEmpty {
                Divider()
                
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(mealBreakdown.prefix(3), id: \.0) { meal, calories in
                        HStack {
                            Text(meal)
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            
                            Spacer()
                            
                            Text("\(calories) cal")
                                .font(AppTheme.Typography.caption1)
                                .foregroundColor(AppTheme.Colors.primaryText)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.successBackground)
        )
    }
}

// MARK: - Enhanced Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .frame(height: 100)
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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MyHealthView()
}
