import SwiftUI

// MARK: - Medications Section
struct MedicationsSection: View {
    let medications: [MedicationModel]
    let onMedicationTap: (MedicationModel) -> Void
    let onEditMedication: (MedicationModel) -> Void
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
                medicationsList
            }
        }
    }
    
    @ViewBuilder
    private var medicationsList: some View {
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
                viewAllButton
            }
        }
    }
    
    @ViewBuilder
    private var viewAllButton: some View {
        Button(AppStrings.Common.viewAllCount(medications.count - 5)) {
            // Navigate to full medications list
        }
        .font(AppTheme.Typography.caption1)
        .foregroundColor(AppTheme.Colors.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

// MARK: - Section Header
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
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
}