import SwiftUI

struct VoiceQueryView: View {
    let onAnalyze: (String) -> Void
    
    @State private var queryText: String = ""
    @State private var selectedExample: String?
    @State private var showingExamples: Bool = true
    @Environment(\.dismiss) private var dismiss
    private let analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Voice Input Section
                voiceInputSection()
                
                // Examples Section
                if showingExamples && queryText.isEmpty {
                    examplesSection()
                }
                
                // Query Preview
                if !queryText.isEmpty {
                    queryPreviewSection()
                }
                
                Spacer()
                
                // Action Buttons
                actionButtons()
            }
            .navigationTitle(AppStrings.Voice.askQuestion)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppStrings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Voice Input Section
    @ViewBuilder
    private func voiceInputSection() -> some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Instruction Text
            Text(AppStrings.Voice.voiceQueryInstructions)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.top, AppTheme.Spacing.medium)
            
            // Voice Input
            VoiceFirstInputView(
                text: $queryText,
                placeholder: AppStrings.Voice.askAnything,
                voiceContext: .conflictQuery,
                onSubmit: {
                    if !queryText.isEmpty {
                        handleSubmit()
                    }
                }
            )
            .padding(.horizontal, AppTheme.Spacing.large)
        }
    }
    
    // MARK: - Examples Section
    @ViewBuilder
    private func examplesSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Voice.exampleQueriesTitle)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
                .padding(.horizontal, AppTheme.Spacing.large)
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(exampleQueries, id: \.self) { example in
                        ExampleQueryCard(
                            query: example,
                            isSelected: selectedExample == example,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedExample = example
                                    queryText = example
                                }
                                analyticsManager.trackFeatureUsed("voice_query_example_selected")
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            }
        }
        .padding(.top, AppTheme.Spacing.large)
    }
    
    // MARK: - Query Preview Section
    @ViewBuilder
    private func queryPreviewSection() -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(AppStrings.Voice.yourQuery)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Button(AppStrings.Common.clear) {
                    withAnimation {
                        queryText = ""
                        selectedExample = nil
                    }
                }
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.error)
            }
            
            Text(queryText)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)
                .padding(AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.top, AppTheme.Spacing.large)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private func actionButtons() -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Analyze Button
            Button(action: handleSubmit) {
                HStack {
                    Image(systemName: AppIcons.ai)
                        .font(AppTheme.Typography.callout)
                    Text(AppStrings.AI.analyzeWithClaude)
                        .font(AppTheme.Typography.headline)
                }
                .foregroundColor(AppTheme.Colors.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Layout.buttonHeight)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .disabled(queryText.isEmpty)
            
            // Info Text
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: AppIcons.info)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Text(AppStrings.AI.queryDisclaimer)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Helpers
    private func handleSubmit() {
        guard !queryText.isEmpty else { return }
        
        analyticsManager.trackFeatureUsed("voice_query_submitted")
        analyticsManager.trackVoiceQuery(
            queryType: "conflict_check",
            success: true
        )
        analyticsManager.trackVoiceInput(
            context: selectedExample != nil ? "example" : "custom",
            duration: 0,
            wordCount: queryText.split(separator: " ").count
        )
        
        onAnalyze(queryText)
        dismiss()
    }
    
    private var exampleQueries: [String] {
        [
            AppStrings.Voice.exampleQuery1,
            AppStrings.Voice.exampleQuery2,
            AppStrings.Voice.exampleQuery3,
            AppStrings.Voice.exampleQuery4,
            AppStrings.Voice.exampleQuery5
        ]
    }
}

// MARK: - Example Query Card
struct ExampleQueryCard: View {
    let query: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: AppIcons.voice)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                
                Text(query)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: AppIcons.success)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? AppTheme.Colors.primaryBackground : AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        isSelected ? AppTheme.Colors.primary : AppTheme.Colors.cardBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Voice Query View
struct CompactVoiceQueryView: View {
    @Binding var queryText: String
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Title
            HStack {
                Image(systemName: AppIcons.voiceInput)
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.voiceActive)
                
                Text(AppStrings.Voice.askQuestion)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
            }
            
            // Compact Voice Input
            CompactVoiceInput(
                text: $queryText,
                placeholder: AppStrings.Voice.askAnything,
                onSubmit: onAnalyze
            )
            
            // Quick Examples
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(quickExamples, id: \.self) { example in
                        QuickExampleChip(
                            text: example,
                            onTap: {
                                queryText = example
                                onAnalyze()
                            }
                        )
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    private var quickExamples: [String] {
        [
            AppStrings.Voice.quickExample1,
            AppStrings.Voice.quickExample2,
            AppStrings.Voice.quickExample3
        ]
    }
}

// MARK: - Quick Example Chip
struct QuickExampleChip: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(AppTheme.Colors.primaryBackground)
                .cornerRadius(AppTheme.CornerRadius.pill)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VoiceQueryView(onAnalyze: { _ in })
}
