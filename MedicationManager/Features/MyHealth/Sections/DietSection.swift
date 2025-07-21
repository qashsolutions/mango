import SwiftUI

// MARK: - Diet Section
struct DietSection: View {
    let dietEntries: [DietEntryModel]
    let onDietEntryTap: (DietEntryModel) -> Void
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
                dietContent
            }
        }
    }
    
    @ViewBuilder
    private var dietContent: some View {
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
                viewAllButton
            }
        }
    }
    
    @ViewBuilder
    private var viewAllButton: some View {
        Button(AppStrings.Common.viewAllCount(dietEntries.count - 3)) {
            // Navigate to full diet list
        }
        .font(AppTheme.Typography.caption1)
        .foregroundColor(AppTheme.Colors.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - Diet Entry Card
struct DietEntryCard: View {
    let dietEntry: DietEntryModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                mealIcon
                mealInfo
                Spacer()
                timeAndChevron
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
    
    @ViewBuilder
    private var mealIcon: some View {
        Image(systemName: dietEntry.mealType.icon)
            .font(AppTheme.Typography.callout)
            .foregroundColor(AppTheme.Colors.primary)
            .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
            .background(AppTheme.Colors.primaryBackground)
            .cornerRadius(18)
    }
    
    @ViewBuilder
    private var mealInfo: some View {
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
    }
    
    @ViewBuilder
    private var timeAndChevron: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
            if let time = dietEntry.actualTime ?? dietEntry.scheduledTime {
                Text(time.formatted(.dateTime.hour().minute()))
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.tertiaryText)
        }
    }
}

// MARK: - Calorie Summary Card
struct CalorieSummaryCard: View {
    let dietEntries: [DietEntryModel]
    
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
            mainCalorieInfo
            
            if !mealBreakdown.isEmpty {
                Divider()
                mealBreakdownView
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.successBackground)
        )
    }
    
    @ViewBuilder
    private var mainCalorieInfo: some View {
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
    }
    
    @ViewBuilder
    private var mealBreakdownView: some View {
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