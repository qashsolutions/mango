import SwiftUI
import Observation

@MainActor
struct AddDietEntryView: View {
    let initialVoiceText: String?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddDietEntryViewModel()
    
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
    @State private var showingAllergenPicker = false
    
    private let commonAllergens = [
        "Dairy", "Eggs", "Fish", "Shellfish", "Tree Nuts",
        "Peanuts", "Wheat", "Soy", "Sesame"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                dietDetailsSection
                mealInfoSection
                nutritionSection
                allergenSection
                notesSection
            }
            .navigationTitle(AppStrings.Actions.addDietEntry)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppStrings.Common.save) {
                        saveDietEntry()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(AppStrings.Common.error, isPresented: $showingError) {
                Button(AppStrings.Common.ok) { }
            } message: {
                Text(viewModel.errorMessage ?? AppStrings.Common.error)
            }
            .sheet(isPresented: $showingAllergenPicker) {
                AllergenPickerView(selectedAllergens: $selectedAllergens)
            }
            .onAppear {
                setupInitialData()
                AnalyticsManager.shared.trackScreenViewed("add_diet_entry")
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
            Text(AppStrings.Common.notes)
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupInitialData() {
        if let voiceText = initialVoiceText {
            parseVoiceInput(voiceText)
        }
    }
    
    private func parseVoiceInput(_ text: String) {
        // Simple parsing for voice input
        let lowercased = text.lowercased()
        
        // Extract meal type
        if lowercased.contains("breakfast") {
            selectedMealType = .breakfast
        } else if lowercased.contains("lunch") {
            selectedMealType = .lunch
        } else if lowercased.contains("dinner") {
            selectedMealType = .dinner
        } else if lowercased.contains("snack") {
            selectedMealType = .snack
        }
        
        // Extract food name (use the whole text if no meal type found)
        var foodText = text
        for mealType in MealType.allCases {
            foodText = foodText.replacingOccurrences(of: mealType.displayName.lowercased(), with: "", options: .caseInsensitive)
        }
        foodName = foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for common allergens
        for allergen in commonAllergens {
            if lowercased.contains(allergen.lowercased()) {
                containsAllergens = true
                selectedAllergens.insert(allergen)
            }
        }
    }
    
    private func saveDietEntry() {
        Task {
            await viewModel.saveDietEntry(
                foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
                mealType: selectedMealType,
                calories: calories.isEmpty ? nil : Int(calories),
                allergens: containsAllergens ? Array(selectedAllergens) : nil,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
                entryDate: entryDate,
                voiceEntryUsed: initialVoiceText != nil
            )
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
}

// MARK: - Allergen Picker View
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

// MARK: - View Model
@MainActor
@Observable
final class AddDietEntryViewModel {
    private let coreDataManager = CoreDataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    var errorMessage: String?
    
    func saveDietEntry(
        foodName: String,
        mealType: MealType,
        calories: Int?,
        allergens: [String]?,
        notes: String?,
        entryDate: Date,
        voiceEntryUsed: Bool
    ) async {
        guard let userId = firebaseManager.currentUser?.id else {
            errorMessage = AppStrings.Errors.authenticationRequired
            return
        }
        
        let foodItem = FoodItem(
            id: UUID().uuidString,
            name: foodName,
            quantity: nil,
            calories: calories,
            notes: nil
        )
        
        let dietEntry = DietEntryModel(
            id: UUID().uuidString,
            userId: userId,
            mealType: mealType,
            foods: [foodItem],
            allergies: allergens ?? [],
            notes: notes,
            scheduledTime: entryDate,
            actualTime: nil,
            date: entryDate,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: voiceEntryUsed,
            needsSync: true,
            isDeletedFlag: false
        )
        
        do {
            try await coreDataManager.saveDietEntry(dietEntry)
            
            // Track analytics
            AnalyticsManager.shared.trackEvent(
                "diet_entry_added",
                parameters: [
                    "meal_type": mealType.rawValue,
                    "has_calories": calories != nil,
                    "has_allergens": allergens != nil,
                    "voice_used": voiceEntryUsed
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            let appError = error as? AppError ?? AppError.data(.unknown)
            AnalyticsManager.shared.trackError(
                appError,
                context: "AddDietEntryViewModel.saveDietEntry"
            )
        }
    }
}

#Preview {
    AddDietEntryView(initialVoiceText: nil)
}