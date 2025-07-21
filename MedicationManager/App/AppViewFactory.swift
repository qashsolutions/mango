import SwiftUI

/// Concrete implementation of ViewFactoryProtocol that creates all views in the application.
/// This implementation lives in the App layer and has access to both Core and Features layers,
/// allowing it to bridge the gap while maintaining clean architecture.
@MainActor
final class AppViewFactory: ViewFactoryProtocol {
    
    // MARK: - Tab Views
    
    func createTabView(for tab: MainTab) -> AnyView {
        switch tab {
        case .myHealth:
            return AnyView(MyHealthView())
        case .doctorList:
            return AnyView(DoctorListView())
        case .groups:
            return AnyView(GroupsView())
        case .conflicts:
            return AnyView(ConflictsView())
        }
    }
    
    // MARK: - Detail Views
    
    func createDetailView(for destination: NavigationDestination) -> AnyView {
        switch destination {
        case .medicationDetail(let id):
            return AnyView(MedicationDetailView(medicationId: id))
        case .supplementDetail(let id):
            return AnyView(SupplementDetailView(supplementId: id))
        case .dietEntryDetail(let id):
            return AnyView(DietEntryDetailView(entryId: id))
        case .doctorDetail(let id):
            return AnyView(DoctorDetailView(doctorId: id))
        case .conflictDetail(let id):
            return AnyView(ConflictDetailView(conflictId: id))
        case .caregiverSettings:
            return AnyView(SettingsView()) // Assuming caregiver settings is part of settings
        case .userProfile:
            return AnyView(EditUserProfileView())
        case .appSettings:
            return AnyView(SettingsView())
        case .privacySettings:
            return AnyView(SettingsView()) // Can be replaced with specific privacy view
        case .notificationSettings:
            return AnyView(SettingsView()) // Can be replaced with specific notification view
        case .syncSettings:
            return AnyView(SettingsView()) // Can be replaced with specific sync view
        case .aboutApp:
            return AnyView(SettingsView()) // Can be replaced with specific about view
        }
    }
    
    // MARK: - Sheet Views
    
    func createSheetView(for sheet: SheetDestination) -> AnyView {
        switch sheet {
        case .addMedication(let voiceText):
            return AnyView(AddMedicationView(initialVoiceText: voiceText))
        case .editMedication(let id):
            return AnyView(EditMedicationView(medicationId: id))
        case .addSupplement(let voiceText):
            return AnyView(AddSupplementView(initialVoiceText: voiceText))
        case .editSupplement(let id):
            return AnyView(EditSupplementView(supplementId: id))
        case .addDietEntry(let voiceText):
            return AnyView(AddDietEntryView(initialVoiceText: voiceText))
        case .editDietEntry(let id):
            return AnyView(EditDietEntryView(entryId: id))
        case .addDoctor(let contact):
            return AnyView(AddDoctorView(initialContact: contact))
        case .editDoctor(let id):
            return AnyView(EditDoctorView(doctorId: id))
        case .caregiverInvitation(_):
            // Assuming this is handled in GroupsView or a specific invitation view
            return AnyView(GroupsView())
        case .inviteCaregiver:
            // Assuming this is handled in GroupsView
            return AnyView(GroupsView())
        case .voiceInput(let context):
            return AnyView(VoiceInputSheet(context: context))
        case .medicationConflictCheck:
            return AnyView(ConflictsView())
        case .userProfileEdit:
            return AnyView(EditUserProfileView())
        }
    }
    
    // MARK: - Full Screen Cover Views
    
    func createFullScreenView(for cover: FullScreenDestination) -> AnyView {
        switch cover {
        case .authentication:
            return AnyView(LoginView())
        case .onboarding:
            return AnyView(OnboardingView())
        case .caregiverOnboarding:
            return AnyView(CaregiverOnboardingView())
        }
    }
}
