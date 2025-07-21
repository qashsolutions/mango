import SwiftUI

@MainActor
struct DietEntryDetailView: View {
    let entryId: String
    @State private var viewModel = DietEntryDetailViewModel()
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let navigationManager = NavigationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let dietEntry = viewModel.dietEntry {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                        // Header Card
                        headerCard(dietEntry)
                        
                        // Nutrition Info
                        nutritionSection(dietEntry)
                        
                        // Allergens Section
                        if !dietEntry.allergies.isEmpty {
                            allergensSection(Set(dietEntry.allergies))
                        }
                        
                        // Notes Section
                        if let notes = dietEntry.notes, !notes.isEmpty {
                            notesSection(notes)
                        }
                        
                        // Medication Timing
                        medicationTimingSection(dietEntry.mealType)
                        
                        // Actions Section
                        actionsSection()
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    AppStrings.Common.dietEntryNotFound,
                    systemImage: AppIcons.food,
                    description: Text(AppStrings.Common.dietEntryNotFoundDescription)
                )
            }
        }
        .navigationTitle(viewModel.dietEntry?.foodItems ?? AppStrings.Common.dietEntry)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                editButton
            }
        }
        .alert(
            AppStrings.Common.deleteConfirmationTitle,
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button(AppStrings.Common.cancel, role: .cancel) { }
            Button(AppStrings.Common.delete, role: .destructive) {
                Task {
                    await deleteDietEntryAction()
                }
            }
        } message: {
            Text(AppStrings.Common.deleteDietEntryConfirmation)
        }
        .task {
            await viewModel.loadDietEntry(id: entryId)
        }
    }
    
    // MARK: - Header Card
    @ViewBuilder
    private func headerCard(_ dietEntry: DietEntryModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(dietEntry.foodItems)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    HStack {
                        Label(dietEntry.mealType.displayName, systemImage: dietEntry.mealType.icon)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text(dietEntry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Calorie Badge
                if dietEntry.totalCalories > 0 {
                    VStack {
                        Text("\(dietEntry.totalCalories)")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primary)
                        Text(AppStrings.Common.calories)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(AppTheme.Colors.primaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Colors.shadow, radius: AppTheme.ShadowRadius.small)
    }
    
    // MARK: - Nutrition Section
    @ViewBuilder
    private func nutritionSection(_ dietEntry: DietEntryModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Common.nutritionInfo)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                nutritionCard(
                    title: AppStrings.Common.calories,
                    value: Double(dietEntry.totalCalories),
                    unit: "cal",
                    color: AppTheme.Colors.success
                )
            }
        }
    }
    
    // MARK: - Nutrition Card
    @ViewBuilder
    private func nutritionCard(title: String, value: Double, unit: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", value))
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(color)
                Text(unit)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Allergens Section
    @ViewBuilder
    private func allergensSection(_ allergens: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Image(systemName: AppIcons.warning)
                    .foregroundColor(AppTheme.Colors.warning)
                Text(AppStrings.Common.allergens)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
            }
            
            FlowLayout(spacing: AppTheme.Spacing.small) {
                ForEach(Array(allergens), id: \.self) { allergen in
                    allergenChip(allergen)
                }
            }
            .padding()
            .background(AppTheme.Colors.warning.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Allergen Chip
    @ViewBuilder
    private func allergenChip(_ allergen: String) -> some View {
        Text(allergen)
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Colors.warning)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.xSmall)
            .background(AppTheme.Colors.warning.opacity(0.2))
            .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    // MARK: - Notes Section
    @ViewBuilder
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(AppStrings.Common.notes)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text(notes)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Medication Timing Section
    @ViewBuilder
    private func medicationTimingSection(_ mealType: MealType) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Common.medicationTiming)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            if viewModel.isLoadingMedications {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(AppStrings.Common.loading)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    if !viewModel.medicationsForMeal.isEmpty {
                        ForEach(viewModel.medicationsForMeal) { medication in
                            medicationRow(medication)
                        }
                    }
                    
                    if !viewModel.supplementsForMeal.isEmpty {
                        ForEach(viewModel.supplementsForMeal) { supplement in
                            supplementRow(supplement)
                        }
                    }
                    
                    if viewModel.medicationsForMeal.isEmpty && viewModel.supplementsForMeal.isEmpty {
                        HStack {
                            Image(systemName: AppIcons.info)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(AppStrings.Common.noMedicationsForMeal)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    // MARK: - Medication Row
    @ViewBuilder
    private func medicationRow(_ medication: MedicationModel) -> some View {
        HStack {
            Image(systemName: AppIcons.medication)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.text)
                Text(medication.dosage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            if medication.takeWithFood {
                Label(AppStrings.Common.withFood, systemImage: AppIcons.checkmark)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.success)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
    
    // MARK: - Supplement Row
    @ViewBuilder
    private func supplementRow(_ supplement: SupplementModel) -> some View {
        HStack {
            Image(systemName: AppIcons.supplement)
                .foregroundColor(AppTheme.Colors.info)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.text)
                Text(supplement.dosage)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            if supplement.isTakenWithFood {
                Label(AppStrings.Common.withFood, systemImage: AppIcons.checkmark)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.success)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
    
    // MARK: - Actions Section
    @ViewBuilder
    private func actionsSection() -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Delete Button
            Button(role: .destructive, action: { viewModel.showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: AppIcons.trash)
                    Text(AppStrings.Common.deleteDietEntry)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .foregroundColor(AppTheme.Colors.error)
            .disabled(viewModel.isUpdating)
        }
        .padding(.top)
    }
    
    // MARK: - Helper Views
    private var editButton: some View {
        Button(AppStrings.Common.edit) {
            navigationManager.presentSheet(.editDietEntry(id: entryId))
        }
    }
    
    // MARK: - Actions
    private func deleteDietEntryAction() async {
        await viewModel.deleteDietEntry()
        if viewModel.dietEntry == nil {
            dismiss()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width > proposal.width ?? 0 {
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            totalWidth = max(totalWidth, lineWidth)
        }
        
        totalHeight += lineHeight
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for index in subviews.indices {
            if x + sizes[index].width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            
            subviews[index].place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(sizes[index])
            )
            
            x += sizes[index].width + spacing
            lineHeight = max(lineHeight, sizes[index].height)
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class DietEntryDetailViewModel {
    // State
    var dietEntry: DietEntryModel?
    var medicationsForMeal: [MedicationModel] = []
    var supplementsForMeal: [SupplementModel] = []
    var isLoading = false
    var isLoadingMedications = false
    var isUpdating = false
    var showDeleteConfirmation = false
    var error: Error?
    
    // Dependencies
    private let coreDataManager = CoreDataManager.shared
    private let analyticsManager = AnalyticsManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Load Diet Entry
    func loadDietEntry(id: String) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = firebaseManager.currentUser?.id else {
            error = AppError.userNotAuthenticated
            return
        }
        
        do {
            dietEntry = try await coreDataManager.fetchDietEntry(id: id, userId: userId)
            
            // Load medications for this meal time
            if let mealType = dietEntry?.mealType {
                await loadMedicationsForMeal(mealType: mealType, userId: userId)
            }
            
            // Track view
            analyticsManager.trackEvent(
                "diet_entry_viewed",
                parameters: [
                    "meal_type": dietEntry?.mealType.rawValue ?? "unknown",
                    "calories": dietEntry?.totalCalories ?? 0
                ]
            )
        } catch {
            self.error = error
            print("Error loading diet entry: \(error)")
        }
    }
    
    // MARK: - Load Medications for Meal
    private func loadMedicationsForMeal(mealType: MealType, userId: String) async {
        isLoadingMedications = true
        defer { isLoadingMedications = false }
        
        do {
            // Get medications for this meal time
            medicationsForMeal = try await coreDataManager.fetchMedicationsForTime(
                userId: userId,
                mealTime: mealType
            )
            
            // Get supplements for this meal time
            supplementsForMeal = try await coreDataManager.fetchSupplementsForTime(
                userId: userId,
                mealTime: mealType
            )
        } catch {
            print("Error loading medications for meal: \(error)")
        }
    }
    
    // MARK: - Delete Diet Entry
    func deleteDietEntry() async {
        guard let dietEntry = dietEntry else { return }
        
        isUpdating = true
        defer { isUpdating = false }
        
        do {
            try await coreDataManager.deleteDietEntry(dietEntry.id)
            
            // Track deletion
            analyticsManager.trackEvent(
                "diet_entry_deleted",
                parameters: [
                    "meal_type": dietEntry.mealType.rawValue,
                    "had_allergens": !dietEntry.allergies.isEmpty
                ]
            )
            
            // Clear the entry to indicate deletion
            self.dietEntry = nil
        } catch {
            self.error = error
            print("Error deleting diet entry: \(error)")
        }
    }
}


#Preview {
    NavigationStack {
        DietEntryDetailView(entryId: "preview-id")
    }
}