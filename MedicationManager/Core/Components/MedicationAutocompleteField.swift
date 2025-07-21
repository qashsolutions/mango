import SwiftUI

/// A text field with medical terminology autocomplete functionality
struct MedicationAutocompleteField: View {
    // MARK: - Properties
    @Binding var text: String
    let placeholder: String
    let medicationType: MedicationType
    let onCommit: () -> Void
    
    // MARK: - Private State
    @State private var suggestions: [String] = []
    @State private var showingSuggestions = false
    @State private var selectedSuggestionIndex = -1
    @FocusState private var isFocused: Bool
    
    // MARK: - Medical Vocabulary Helper
    private let vocabularyHelper = MedicalVocabularyHelper.shared
    
    enum MedicationType {
        case medication
        case supplement
        case both
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Field
            HStack {
                Image(systemName: medicationType == .supplement ? AppIcons.supplement : AppIcons.medication)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primary)
                
                TextField(placeholder, text: $text)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        updateSuggestions(for: newValue)
                    }
                    .onSubmit {
                        if selectedSuggestionIndex >= 0 && selectedSuggestionIndex < suggestions.count {
                            selectSuggestion(suggestions[selectedSuggestionIndex])
                        } else {
                            onCommit()
                        }
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        suggestions = []
                        showingSuggestions = false
                    }) {
                        Image(systemName: AppIcons.clear)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(AppTheme.Colors.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        isFocused ? AppTheme.Colors.primary : AppTheme.Colors.border,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            
            // Validation Indicator
            if !text.isEmpty && !isValidMedication() {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: AppIcons.info)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.warning)
                    
                    Text(AppStrings.MedicalTerminology.notRecognized)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.warning)
                }
                .padding(.top, AppTheme.Spacing.extraSmall)
                .padding(.horizontal, AppTheme.Spacing.small)
            }
            
            // Suggestions List
            if showingSuggestions && !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                            SuggestionRow(
                                suggestion: suggestion,
                                isSelected: index == selectedSuggestionIndex,
                                onTap: {
                                    selectSuggestion(suggestion)
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.cardBackground)
                        .shadow(
                            color: AppTheme.Colors.shadow,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                .padding(.top, AppTheme.Spacing.extraSmall)
            }
        }
        .onTapGesture {
            // Tap outside suggestions to dismiss
            if showingSuggestions {
                showingSuggestions = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSuggestions(for query: String) {
        guard !query.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }
        
        // Get suggestions based on medication type
        let allSuggestions: [String]
        switch medicationType {
        case .medication:
            allSuggestions = vocabularyHelper.getSuggestions(for: query)
        case .supplement:
            allSuggestions = vocabularyHelper.getSuggestions(for: query).filter { suggestion in
                vocabularyHelper.isValidSupplement(suggestion)
            }
        case .both:
            allSuggestions = vocabularyHelper.getSuggestions(for: query)
        }
        
        suggestions = Array(allSuggestions.prefix(5))
        showingSuggestions = !suggestions.isEmpty && isFocused
        selectedSuggestionIndex = -1
        
        // Track autocomplete usage
        if !suggestions.isEmpty {
            AnalyticsManager.shared.trackFeatureUsed("medication_autocomplete")
        }
    }
    
    private func selectSuggestion(_ suggestion: String) {
        text = suggestion
        suggestions = []
        showingSuggestions = false
        isFocused = false
        onCommit()
        
        // Track suggestion selection
        AnalyticsManager.shared.trackFeatureUsed("autocomplete_suggestion_selected")
    }
    
    private func isValidMedication() -> Bool {
        switch medicationType {
        case .medication:
            return vocabularyHelper.isValidMedication(text)
        case .supplement:
            return vocabularyHelper.isValidSupplement(text)
        case .both:
            return vocabularyHelper.isValidMedication(text)
        }
    }
}

// MARK: - Suggestion Row
private struct SuggestionRow: View {
    let suggestion: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(suggestion)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: AppIcons.chevronRight)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                isSelected ? AppTheme.Colors.primary.opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview("Medication Field") {
    VStack(spacing: AppTheme.Spacing.large) {
        MedicationAutocompleteField(
            text: .constant(""),
            placeholder: AppStrings.MedicalTerminology.enterMedicationName,
            medicationType: .medication,
            onCommit: {}
        )
        
        MedicationAutocompleteField(
            text: .constant("Vita"),
            placeholder: AppStrings.MedicalTerminology.enterSupplementName,
            medicationType: .supplement,
            onCommit: {}
        )
    }
    .padding()
}