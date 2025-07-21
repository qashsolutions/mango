import SwiftUI

struct MyHealthMainContent: View {
    var viewModel: MyHealthViewModel
    var navigationManager: NavigationManager
    
    var body: some View {
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
}