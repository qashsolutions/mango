import SwiftUI
import Observation

@MainActor
struct EditDietEntryView: View {
    let entryId: String
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditDietEntryViewModel
    
    // Form state
    @State private var foodName = ""
    @State private var selectedMealType: MealType = .lunch
    @State private var calories = ""
    @State private var notes = ""
    @State private var entryDate = Date()
    @State private var containsAllergens = false
    @State private var selectedAllergens: Set<String> = []
    
    // UI state
    @State private var showingError = false
    @State private var showingDeleteAlert = false
    @State private var showingAllergenPicker = false
    @State private var isDeleting = false
    
    init(entryId: String) {
        self.entryId = entryId
        self._viewModel = State(initialValue: EditDietEntryViewModel(entryId: entryId))
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    dietDetailsSection
                    mealInfoSection
                    nutritionSection
                    allergenSection
                    notesSection
                    deleteSection
                }
                .navigationTitle(AppStrings.Actions.editDietEntry)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(AppStrings.Common.cancel) {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(AppStrings.Common.save) {
                            saveChanges()
                        }
                        .disabled(!isFormValid || !hasChanges)
                    }
                }
                .alert(AppStrings.Common.error, isPresented: $showingError) {
                    Button(AppStrings.Common.ok) { }
                } message: {
                    Text(viewModel.errorMessage ?? AppStrings.Common.error)
                }
                .alert(AppStrings.Common.confirmDelete, isPresented: $showingDeleteAlert) {
                    Button(AppStrings.Common.cancel, role: .cancel) { }
                    Button(AppStrings.Common.delete, role: .destructive) {
                        deleteDietEntry()
                    }
                } message: {
                    Text(NSLocalizedString("diet.edit.deleteConfirmation", value: "Are you sure you want to delete this diet entry? This action cannot be undone.", comment: "Delete diet entry confirmation"))
                }
                .sheet(isPresented: $showingAllergenPicker) {
                    AllergenPickerView(selectedAllergens: $selectedAllergens)
                }
                .onAppear {
                    loadDietEntryData()
                    AnalyticsManager.shared.trackScreenViewed("edit_diet_entry")
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var dietDetailsSection: some View {
        Section {
            // Food Name with Voice Input
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("diet.foodName", value: "Food Item", comment: "Food name label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $foodName,
                    placeholder: NSLocalizedString("diet.foodPlaceholder", value: "What did you eat?", comment: "Food placeholder"),
                    voiceContext: .foodName,
                    onSubmit: {}
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            
            // Date Picker
            DatePicker(
                NSLocalizedString("diet.entryDate", value: "Date", comment: "Entry date label"),
                selection: $entryDate,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
        } header: {
            Text(AppStrings.Common.details)
        }
    }
    
    private var mealInfoSection: some View {
        Section {
            // Meal Type Picker
            Picker(NSLocalizedString("diet.mealType", value: "Meal", comment: "Meal type label"), selection: $selectedMealType) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    Text(mealType.displayName).tag(mealType)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text(NSLocalizedString("diet.mealInfo", value: "Meal Information", comment: "Meal info section"))
        }
    }
    
    private var nutritionSection: some View {
        Section {
            // Calories
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(NSLocalizedString("diet.calories", value: "Calories", comment: "Calories label"))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField(
                    NSLocalizedString("diet.caloriesPlaceholder", value: "Optional", comment: "Calories placeholder"),
                    text: $calories
                )
                .keyboardType(.numberPad)
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(NSLocalizedString("diet.nutritionInfo", value: "Nutrition Information", comment: "Nutrition section"))
        } footer: {
            Text(AppStrings.Common.optional)
                .font(AppTheme.Typography.caption2)
        }
    }
    
    private var allergenSection: some View {
        Section {
            Toggle(NSLocalizedString("diet.containsAllergens", value: "Contains Allergens", comment: "Contains allergens toggle"), isOn: $containsAllergens)
            
            if containsAllergens {
                Button(action: { showingAllergenPicker = true }) {
                    HStack {
                        Text(NSLocalizedString("diet.selectAllergens", value: "Select Allergens", comment: "Select allergens button"))
                        Spacer()
                        if selectedAllergens.isEmpty {
                            Text(AppStrings.Common.none)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        } else {
                            Text("\(selectedAllergens.count)")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        Image(systemName: "chevron.right")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                .buttonStyle(.plain)
                
                if !selectedAllergens.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(Array(selectedAllergens).sorted(), id: \.self) { allergen in
                            HStack {
                                Image(systemName: AppIcons.warning)
                                    .foregroundColor(AppTheme.Colors.warning)
                                    .font(AppTheme.Typography.caption)
                                Text(allergen)
                                    .font(AppTheme.Typography.caption)
                            }
                        }
                    }
                    .padding(.top, AppTheme.Spacing.extraSmall)
                }
            }
        } header: {
            Text(NSLocalizedString("diet.allergenInfo", value: "Allergen Information", comment: "Allergen section"))
        } footer: {
            if containsAllergens && !selectedAllergens.isEmpty {
                Text(NSLocalizedString("diet.allergenWarning", value: "This information helps track potential food interactions with medications", comment: "Allergen warning"))
                    .font(AppTheme.Typography.caption2)
            }
        }
    }
    
    private var notesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(AppStrings.Common.notes)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                VoiceFirstInputView(
                    text: $notes,
                    placeholder: NSLocalizedString("diet.notesPlaceholder", value: "Any additional notes", comment: "Notes placeholder"),
                    voiceContext: .notes,
                    onSubmit: {}
                )
            }
            .padding(.vertical, AppTheme.Spacing.extraSmall)
        } header: {
            Text(AppStrings.Common.additionalInfo)
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(NSLocalizedString("diet.delete", value: "Delete Diet Entry", comment: "Delete diet entry button"))
                    }
                    Spacer()
                }
            }
            .disabled(isDeleting)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasChanges: Bool {
        guard let original = viewModel.originalEntry else { return false }
        
        let currentCalories = calories.isEmpty ? nil : Int(calories)
        let currentAllergens = containsAllergens ? Array(selectedAllergens).sorted() : nil
        let originalAllergens = original.allergies.sorted()
        
        // Get original food name and calories from first food item
        let originalFoodName = original.foods.first?.name ?? ""
        let originalCalories = original.foods.first?.calories
        
        return foodName != originalFoodName ||
               selectedMealType != original.mealType ||
               currentCalories != originalCalories ||
               notes != (original.notes ?? "") ||
               entryDate != (original.scheduledTime ?? original.date) ||
               currentAllergens != originalAllergens
    }
    
    private func loadDietEntryData() {
        Task {
            await viewModel.loadDietEntry()
            
            if let entry = viewModel.originalEntry {
                // Load food name and calories from first food item
                if let firstFood = entry.foods.first {
                    foodName = firstFood.name
                    if let cal = firstFood.calories {
                        calories = String(cal)
                    }
                }
                
                selectedMealType = entry.mealType
                notes = entry.notes ?? ""
                entryDate = entry.scheduledTime ?? entry.date
                
                if !entry.allergies.isEmpty {
                    containsAllergens = true
                    selectedAllergens = Set(entry.allergies)
                }
            } else {
                showingError = true
            }
        }
    }
    
    private func saveChanges() {
        Task {
            await viewModel.updateDietEntry(
                foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
                mealType: selectedMealType,
                calories: calories.isEmpty ? nil : Int(calories),
                allergens: containsAllergens ? Array(selectedAllergens) : nil,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                entryDate: entryDate
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
    
    private func deleteDietEntry() {
        isDeleting = true
        
        Task {
            await viewModel.deleteDietEntry()
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
                isDeleting = false
            }
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class EditDietEntryViewModel {
    private let entryId: String
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var originalEntry: DietEntryModel?
    var isLoading = true
    var errorMessage: String?
    
    init(entryId: String) {
        self.entryId = entryId
    }
    
    func loadDietEntry() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.userNotAuthenticated
            return
        }
        
        do {
            let dietEntries = try await coreDataManager.fetchDietEntries(for: userId)
            originalEntry = dietEntries.first(where: { $0.id == entryId })
            
            if originalEntry == nil {
                errorMessage = AppStrings.Errors.genericErrorMessage
            }
        } catch {
            errorMessage = error.localizedDescription
            let appError = error as? AppError ?? AppError.data(.unknown)
            AnalyticsManager.shared.trackError(
                appError,
                context: "EditDietEntryViewModel.loadDietEntry"
            )
        }
    }
    
    func updateDietEntry(
        foodName: String,
        mealType: MealType,
        calories: Int?,
        allergens: [String]?,
        notes: String?,
        entryDate: Date
    ) async {
        guard var entry = originalEntry else {
            errorMessage = AppStrings.Errors.genericErrorMessage
            return
        }
        
        // Update entry properties
        // Create or update the food item
        if entry.foods.isEmpty {
            let foodItem = FoodItem(
                name: foodName,
                calories: calories
            )
            entry.foods = [foodItem]
        } else {
            entry.foods[0].name = foodName
            entry.foods[0].calories = calories
        }
        
        entry.mealType = mealType
        entry.allergies = allergens ?? []
        entry.notes = notes
        // Note: date is immutable in DietEntryModel, only scheduledTime/actualTime can be updated
        entry.scheduledTime = entryDate
        entry.updatedAt = Date()
        entry.needsSync = true
        
        do {
            try await coreDataManager.saveDietEntry(entry)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "diet_entry_updated",
                parameters: [
                    "entry_id": entryId,
                    "meal_type": mealType.rawValue
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            let appError = error as? AppError ?? AppError.data(.unknown)
            AnalyticsManager.shared.trackError(
                appError,
                context: "EditDietEntryViewModel.updateDietEntry"
            )
        }
    }
    
    func deleteDietEntry() async {
        guard var entry = originalEntry else {
            errorMessage = AppStrings.Errors.genericErrorMessage
            return
        }
        
        do {
            // Mark as deleted
            entry.isDeletedFlag = true
            entry.updatedAt = Date()
            entry.needsSync = true
            
            try await coreDataManager.saveDietEntry(entry)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "diet_entry_deleted",
                parameters: ["entry_id": entryId]
            )
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsManager.shared.trackError(
                error,
                context: "EditDietEntryViewModel.deleteDietEntry"
            )
        }
    }
}

// MARK: - Allergen Picker View (Reused from AddDietEntryView)
private struct AllergenPickerView: View {
    @Binding var selectedAllergens: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    private let allergens = [
        "Dairy", "Eggs", "Fish", "Shellfish", "Tree Nuts",
        "Peanuts", "Wheat", "Soy", "Sesame", "Corn",
        "Gluten", "Lactose", "Sulfites"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allergens, id: \.self) { allergen in
                    HStack {
                        Text(allergen)
                        Spacer()
                        if selectedAllergens.contains(allergen) {
                            Image(systemName: AppIcons.success)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedAllergens.contains(allergen) {
                            selectedAllergens.remove(allergen)
                        } else {
                            selectedAllergens.insert(allergen)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("diet.selectAllergens", value: "Select Allergens", comment: "Select allergens title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditDietEntryView(entryId: "preview-id")
}