import Foundation
import SwiftUI
import Observation

#if DEBUG

// MARK: - Mock Authentication Manager

@MainActor
@Observable
final class MockAuthenticationManager: AuthenticationManagerProtocol {
    var isAuthenticated: Bool
    var currentUser: User?
    
    init(isAuthenticated: Bool = true, currentUser: User? = nil) {
        self.isAuthenticated = isAuthenticated
        self.currentUser = currentUser ?? (isAuthenticated ? MockData.user : nil)
    }
    
    func signOut() async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isAuthenticated = false
        currentUser = nil
    }
}

// MARK: - Mock Navigation Manager

@MainActor
@Observable
final class MockNavigationManager: NavigationManagerProtocol {
    var selectedTab: MainTab = .myHealth
    var presentedSheet: SheetDestination?
    var presentedFullScreenCover: FullScreenDestination?
    var navigationPath = NavigationPath()
    
    private var navigationHistory: [String] = []
    
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
        navigationHistory.append("Navigate to: \(destination)")
    }
    
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
        navigationHistory.append("Present sheet: \(destination)")
    }
    
    func presentFullScreenCover(_ destination: FullScreenDestination) {
        presentedFullScreenCover = destination
        navigationHistory.append("Present full screen: \(destination)")
    }
    
    func getNavigationHistory() -> [String] {
        navigationHistory
    }
}

// MARK: - Mock Data Sync Manager

@MainActor
@Observable
final class MockDataSyncManager: DataSyncManagerProtocol {
    var isSyncing: Bool = false
    var syncError: AppError?
    var lastSyncDate: Date? = Date()
    
    func syncPendingChanges() async throws {
        isSyncing = true
        syncError = nil
        
        // Simulate sync delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Randomly fail sometimes for testing
        if Bool.random() {
            isSyncing = false
            lastSyncDate = Date()
        } else {
            isSyncing = false
            syncError = AppError.sync(.firebaseConnectionFailed)
            throw AppError.sync(.firebaseConnectionFailed)
        }
    }
    
    func forceSyncAll() async throws {
        try await syncPendingChanges()
    }
}

// MARK: - Mock Analytics Manager

@MainActor
final class MockAnalyticsManager: AnalyticsManagerProtocol {
    private var events: [(name: String, parameters: [String: Any]?)] = []
    private var screens: [String] = []
    private var errors: [(error: Error, context: String)] = []
    private var userProperties: [String: String] = [:]
    
    func trackEvent(_ name: String, parameters: [String: Any]? = nil) {
        events.append((name: name, parameters: parameters))
        print("📊 Mock Analytics Event: \(name)")
    }
    
    func trackScreenViewed(_ screenName: String) {
        screens.append(screenName)
        print("📊 Mock Analytics Screen: \(screenName)")
    }
    
    func trackError(_ error: Error, context: String) {
        errors.append((error: error, context: context))
        print("📊 Mock Analytics Error: \(error.localizedDescription) in \(context)")
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        if let value = value {
            userProperties[name] = value
        } else {
            userProperties.removeValue(forKey: name)
        }
        print("📊 Mock Analytics User Property: \(name) = \(value ?? "nil")")
    }
    
    // Testing helpers
    func getEvents() -> [(name: String, parameters: [String: Any]?)] { events }
    func getScreens() -> [String] { screens }
    func getErrors() -> [(error: Error, context: String)] { errors }
    func getUserProperties() -> [String: String] { userProperties }
}

// MARK: - Mock Core Data Manager

@MainActor
final class MockCoreDataManager: CoreDataManagerProtocol {
    // Required by protocol
    private(set) var dataStoreStatus: DataStoreStatus = .ready
    
    private var medications: [MedicationModel] = MockData.medications
    private var supplements: [SupplementModel] = MockData.supplements
    private var doctors: [DoctorModel] = MockData.doctors
    
    func saveContext() async throws {
        // Simulate save delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func fetchMedications(for userId: String) async throws -> [MedicationModel] {
        // Simulate fetch delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        return medications.filter { $0.userId == userId }
    }
    
    func fetchSupplements(for userId: String) async throws -> [SupplementModel] {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        return supplements.filter { $0.userId == userId }
    }
    
    func fetchDoctors(for userId: String) async throws -> [DoctorModel] {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        return doctors.filter { $0.userId == userId }
    }
    
    // MARK: - Medication Operations
    func medicationExists(withId id: String) async throws -> Bool {
        return medications.contains { $0.id == id }
    }
    
    func saveMedication(_ medication: MedicationModel) async throws {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
        } else {
            medications.append(medication)
        }
    }
    
    func deleteMedication(_ medicationId: String) async throws {
        medications.removeAll { $0.id == medicationId }
    }
    
    func updateMedication(_ medication: MedicationModel) async throws {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
        }
    }
    
    func markMedicationTaken(medicationId: String, userId: String, takenAt: Date) async throws {
        guard var medication = medications.first(where: { $0.id == medicationId && $0.userId == userId }) else {
            throw AppError.data(.medicationNotFound)
        }
        
        // Find and update the closest uncompleted schedule
        var updatedSchedules = medication.schedule
        if let scheduleIndex = updatedSchedules
            .enumerated()
            .filter({ !$0.element.isCompleted })
            .min(by: { abs($0.element.time.timeIntervalSince(takenAt)) < abs($1.element.time.timeIntervalSince(takenAt)) })?
            .offset {
            
            updatedSchedules[scheduleIndex].isCompleted = true
            updatedSchedules[scheduleIndex].completedAt = takenAt
            
            medication.schedule = updatedSchedules
            medication.updatedAt = Date()
            
            try await updateMedication(medication)
        }
    }
    
    // MARK: - Supplement Operations
    func saveSupplement(_ supplement: SupplementModel) async throws {
        if let index = supplements.firstIndex(where: { $0.id == supplement.id }) {
            supplements[index] = supplement
        } else {
            supplements.append(supplement)
        }
    }
    
    func deleteSupplement(_ supplementId: String) async throws {
        supplements.removeAll { $0.id == supplementId }
    }
    
    func updateSupplement(_ supplement: SupplementModel) async throws {
        if let index = supplements.firstIndex(where: { $0.id == supplement.id }) {
            supplements[index] = supplement
        }
    }
    
    // MARK: - Doctor Operations
    func saveDoctor(_ doctor: DoctorModel) async throws {
        if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
            doctors[index] = doctor
        } else {
            doctors.append(doctor)
        }
    }
    
    func deleteDoctor(_ doctorId: String) async throws {
        doctors.removeAll { $0.id == doctorId }
    }
    
    func updateDoctor(_ doctor: DoctorModel) async throws {
        if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
            doctors[index] = doctor
        }
    }
    
    // MARK: - Conflict Operations
    func fetchConflicts(for userId: String) async throws -> [MedicationConflict] {
        return [] // Mock returns empty conflicts
    }
    
    func fetchConflict(id: String, userId: String) async throws -> MedicationConflict? {
        return nil // Mock returns no conflict
    }
    
    func saveConflict(_ conflict: MedicationConflict) async throws {
        // Mock does nothing
    }
    
    func deleteConflict(_ conflictId: String) async throws {
        // Mock does nothing
    }
    
    func updateConflict(_ conflict: MedicationConflict) async throws {
        // Mock does nothing
    }
    
    // MARK: - Meal Time Based Operations
    func fetchMedicationsForTime(userId: String, mealTime: MealType) async throws -> [MedicationModel] {
        // Mock returns medications for any meal time
        return medications.filter { $0.userId == userId }
    }
    
    func fetchSupplementsForTime(userId: String, mealTime: MealType) async throws -> [SupplementModel] {
        // Mock returns supplements for any meal time  
        return supplements.filter { $0.userId == userId }
    }
    
    // MARK: - Diet Entry Operations
    func fetchDietEntries(for userId: String) async throws -> [DietEntryModel] {
        return [] // Mock returns empty diet entries
    }
    
    func fetchDietEntry(id: String, userId: String) async throws -> DietEntryModel? {
        return nil // Mock returns no diet entry
    }
    
    func saveDietEntry(_ dietEntry: DietEntryModel) async throws {
        // Mock does nothing
    }
    
    func deleteDietEntry(_ dietEntryId: String) async throws {
        // Mock does nothing
    }
    
    func updateDietEntry(_ dietEntry: DietEntryModel) async throws {
        // Mock does nothing
    }
    
    // MARK: - Sync Operations
    func fetchMedicationsNeedingSync() async throws -> [MedicationModel] {
        return medications.filter { $0.needsSync }
    }
    
    func fetchSupplementsNeedingSync() async throws -> [SupplementModel] {
        return supplements.filter { $0.needsSync }
    }
    
    func fetchDietEntriesNeedingSync() async throws -> [DietEntryModel] {
        return []
    }
    
    func fetchDoctorsNeedingSync() async throws -> [DoctorModel] {
        return doctors.filter { $0.needsSync }
    }
    
    func fetchConflictsNeedingSync() async throws -> [MedicationConflict] {
        return []
    }
    
    func markMedicationSynced(_ id: String) async throws {
        if let index = medications.firstIndex(where: { $0.id == id }) {
            medications[index].needsSync = false
        }
    }
    
    func markSupplementSynced(_ id: String) async throws {
        if let index = supplements.firstIndex(where: { $0.id == id }) {
            supplements[index].needsSync = false
        }
    }
    
    func markDietEntrySynced(_ id: String) async throws {
        // Mock does nothing
    }
    
    func markDoctorSynced(_ id: String) async throws {
        if let index = doctors.firstIndex(where: { $0.id == id }) {
            doctors[index].needsSync = false
        }
    }
    
    func markConflictSynced(_ id: String) async throws {
        // Mock does nothing
    }
    
    // MARK: - Caregiver Operations
    func fetchCaregiverTasks(for caregiverId: String) async throws -> [CaregiverTask] {
        return []
    }
    
    func saveCaregiverTask(_ task: CaregiverTask) async throws {
        // Mock does nothing
    }
    
    func updateCaregiverTask(_ task: CaregiverTask) async throws {
        // Mock does nothing
    }
    
    func deleteCaregiverTask(_ taskId: String) async throws {
        // Mock does nothing
    }
    
    // MARK: - User Operations
    func saveUserProfile(_ profile: UserProfile) async throws {
        // Mock does nothing
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        return nil
    }
    
    // MARK: - Search Operations
    func searchMedications(query: String, userId: String) async throws -> [MedicationModel] {
        return medications.filter { 
            $0.userId == userId && $0.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Export/Import Operations
    func exportUserData(userId: String) async throws -> Data {
        return Data() // Mock returns empty data
    }
    
    func importUserData(_ data: Data, userId: String) async throws {
        // Mock does nothing
    }
    
    // MARK: - Database Management
    func clearUserData(for userId: String) async throws {
        medications.removeAll { $0.userId == userId }
        supplements.removeAll { $0.userId == userId }
        doctors.removeAll { $0.userId == userId }
    }
    
    func migrateToAppGroupIfNeeded() async throws {
        // Mock does nothing
    }
    
    func clearLocalChanges() async throws {
        // Mock does nothing
    }
}

// MARK: - Test Helpers (Not in Protocol)
#if DEBUG
extension MockCoreDataManager {
    // Testing convenience methods
    func addMedication(_ medication: MedicationModel) {
        medications.append(medication)
    }
    
    func clearAllTestData() {
        medications.removeAll()
        supplements.removeAll()
        doctors.removeAll()
    }
    
    // Allow tests to simulate different data store states
    func simulateDataStoreStatus(_ status: DataStoreStatus) {
        self.dataStoreStatus = status
    }
}
#endif

// MARK: - Mock Speech Manager

@MainActor
@Observable
final class MockSpeechManager: SpeechManagerProtocol {
    var isAuthorized: Bool = true
    var isRecording: Bool = false
    var recognizedText: String = ""
    
    private let mockPhrases = [
        "Take ibuprofen 200 milligrams twice daily",
        "Add vitamin D supplement",
        "Schedule appointment with Dr. Smith",
        "Check medication conflicts"
    ]
    
    func requestSpeechAuthorization() async {
        // Simulate authorization delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isAuthorized = true
    }
    
    func startRecording() async throws {
        guard isAuthorized else {
            throw AppError.voice(.microphonePermissionDenied)
        }
        
        isRecording = true
        recognizedText = ""
        
        // Simulate speech recognition
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if isRecording {
                recognizedText = mockPhrases.randomElement() ?? ""
                stopRecording()
            }
        }
    }
    
    func stopRecording() {
        isRecording = false
    }
}

// MARK: - Mock Data

struct MockData {
    static let userId = "mock-user-123"
    
    static let user = User(
        id: userId,
        email: "test@example.com",
        displayName: "Test User",
        profileImageURL: nil,
        userType: .primary,
        subscriptionStatus: .active,
        subscriptionType: .annual,
        trialEndDate: nil,
        createdAt: Date(),
        lastLoginAt: Date(),
        preferences: UserPreferences(),
        caregiverAccess: User.CaregiverAccess(enabled: false, caregivers: []),
        mfaEnabled: false,
        mfaEnrolledAt: nil,
        backupCodes: nil
    )
    
    static let medications: [MedicationModel] = [
        MedicationModel(
            id: "med1",
            userId: userId,
            name: "Ibuprofen",
            dosage: "200mg",
            frequency: .twice,
            schedule: [
                MedicationSchedule(
                    time: Date(),
                    dosageAmount: "200mg",
                    instructions: nil,
                    isCompleted: false,
                    completedAt: nil
                )
            ],
            notes: "Take with food",
            prescribedBy: "Dr. Jane Smith",
            startDate: Date(),
            endDate: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            takeWithFood: true,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
    
    static let supplements: [SupplementModel] = [
        SupplementModel(
            id: "supp1",
            userId: userId,
            name: "Vitamin D",
            dosage: "1000 IU",
            frequency: .daily,
            schedule: [
                SupplementSchedule(
                    time: Date(),
                    amount: "1000 IU",
                    withMeal: true,
                    isCompleted: false,
                    completedAt: nil
                )
            ],
            notes: "Take with breakfast",
            purpose: "Bone health",
            brand: "Nature's Way",
            isActive: true,
            isTakenWithFood: true,
            startDate: Date(),
            endDate: nil,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
    
    static let doctors: [DoctorModel] = [
        DoctorModel(
            id: "doc1",
            userId: userId,
            name: "Dr. Jane Smith",
            specialty: "Primary Care",
            phoneNumber: "+1234567892",
            email: "dr.smith@medical.com",
            address: DoctorAddress(
                street: "123 Medical Way",
                city: "New York",
                state: "NY",
                zipCode: "10001",
                country: "USA"
            ),
            notes: "Primary physician",
            isImportedFromContacts: false,
            contactIdentifier: nil,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            needsSync: false,
            isDeletedFlag: false
        )
    ]
}

// MARK: - Mock View Factory

@MainActor
final class MockViewFactory: ViewFactoryProtocol {
    func createTabView(for tab: MainTab) -> AnyView {
        switch tab {
        case .myHealth:
            return AnyView(Text("Mock My Health View"))
        case .doctorList:
            return AnyView(Text("Mock Doctors View"))
        case .conflicts:
            return AnyView(Text("Mock Conflicts View"))
        case .groups:
            return AnyView(Text("Mock Groups View"))
        }
    }
    
    func createDetailView(for destination: NavigationDestination) -> AnyView {
        switch destination {
        case .medicationDetail(let id):
            return AnyView(Text("Mock Medication Detail: \(id)"))
        case .doctorDetail(let id):
            return AnyView(Text("Mock Doctor Detail: \(id)"))
        case .conflictDetail(let id):
            return AnyView(Text("Mock Conflict Detail: \(id)"))
        case .supplementDetail(let id):
            return AnyView(Text("Mock Supplement Detail: \(id)"))
        case .dietEntryDetail(let id):
            return AnyView(Text("Mock Diet Entry Detail: \(id)"))
        case .caregiverSettings:
            return AnyView(Text("Mock Caregiver Settings"))
        case .userProfile:
            return AnyView(Text("Mock User Profile"))
        case .appSettings:
            return AnyView(Text("Mock App Settings"))
        case .privacySettings:
            return AnyView(Text("Mock Privacy Settings"))
        case .notificationSettings:
            return AnyView(Text("Mock Notification Settings"))
        case .syncSettings:
            return AnyView(Text("Mock Sync Settings"))
        case .aboutApp:
            return AnyView(Text("Mock About App"))
        }
    }
    
    func createSheetView(for sheet: SheetDestination) -> AnyView {
        return AnyView(Text("Mock Sheet: \(String(describing: sheet))"))
    }
    
    func createFullScreenView(for cover: FullScreenDestination) -> AnyView {
        return AnyView(Text("Mock Full Screen: \(String(describing: cover))"))
    }
}

// MARK: - Test Container Factory

extension DIContainer {
    /// Creates a container with all mock implementations for testing
    static func createMockContainer() -> DIContainer {
        DIContainer(
            authManager: MockAuthenticationManager(),
            navigationManager: MockNavigationManager(),
            dataSyncManager: MockDataSyncManager(),
            analyticsManager: MockAnalyticsManager(),
            coreDataManager: MockCoreDataManager(),
            speechManager: MockSpeechManager(),
            viewFactory: AppViewFactory() // Use real view factory even in tests
        )
    }
    
    /// Creates a container with mixed real and mock implementations
    static func createTestContainer(
        authManager: AuthenticationManagerProtocol? = nil,
        navigationManager: NavigationManagerProtocol? = nil,
        dataSyncManager: DataSyncManagerProtocol? = nil,
        analyticsManager: AnalyticsManagerProtocol? = nil,
        coreDataManager: CoreDataManagerProtocol? = nil,
        speechManager: SpeechManagerProtocol? = nil,
        viewFactory: ViewFactoryProtocol? = nil
    ) -> DIContainer {
        DIContainer(
            authManager: authManager ?? MockAuthenticationManager(),
            navigationManager: navigationManager ?? MockNavigationManager(),
            dataSyncManager: dataSyncManager ?? MockDataSyncManager(),
            analyticsManager: analyticsManager ?? MockAnalyticsManager(),
            coreDataManager: coreDataManager ?? MockCoreDataManager(),
            speechManager: speechManager ?? MockSpeechManager(),
            viewFactory: viewFactory ?? MockViewFactory()
        )
    }
}

#endif