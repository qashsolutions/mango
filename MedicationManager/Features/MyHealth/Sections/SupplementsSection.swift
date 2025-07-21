import SwiftUI

// MARK: - Supplements Section
struct SupplementsSection: View {
    let supplements: [SupplementModel]
    let onSupplementTap: (SupplementModel) -> Void
    let onEditSupplement: (SupplementModel) -> Void
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
                supplementsList
            }
        }
    }
    
    @ViewBuilder
    private var supplementsList: some View {
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
                viewAllButton
            }
        }
    }
    
    @ViewBuilder
    private var viewAllButton: some View {
        Button(AppStrings.Common.viewAllCount(supplements.count - 3)) {
            // Navigate to full supplements list
        }
        .font(AppTheme.Typography.caption1)
        .foregroundColor(AppTheme.Colors.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - Supplement Card
struct SupplementCard: View {
    let supplement: SupplementModel
    let onTap: () -> Void
    let onTakeAction: () -> Void
    let onEditAction: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                supplementIcon
                supplementInfo
                Spacer()
                actionSection
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
                Label(AppStrings.Common.markAsTaken, systemImage: AppIcons.success)
            }
            
            Button(action: onEditAction) {
                Label(AppStrings.Common.edit, systemImage: AppIcons.edit)
            }
        }
    }
    
    @ViewBuilder
    private var supplementIcon: some View {
        Image(systemName: AppIcons.supplements)
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.secondary)
            .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.extraLarge)
    }
    
    @ViewBuilder
    private var supplementInfo: some View {
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
    }
    
    @ViewBuilder
    private var actionSection: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.extraSmall) {
            if let nextDose = supplement.nextDose {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(AppStrings.Common.next)
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    
                    Text(nextDose.time.formatted(.dateTime.hour().minute()))
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            Button(action: onTakeAction) {
                Image(systemName: supplement.isDueToday ? "circle" : "checkmark.circle.fill")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(supplement.isDueToday ? AppTheme.Colors.secondary : AppTheme.Colors.success)
            }
        }
    }
}