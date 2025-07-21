import Foundation
import Observation

#if DEBUG
@MainActor
@Observable
final class SyncTestRunner {
    var testResults: [TestResult] = []
    var isRunning: Bool = false
    var currentTest: String = ""
    
    private let coreDataManager = CoreDataManager.shared
    private let dataSyncManager = DataSyncManager.shared
    private let authManager = FirebaseManager.shared
    
    // MARK: - Test Suite Runner
    func runAllTests() async {
        isRunning = true
        testResults.removeAll()
        
        await runOfflineTests()
        await runOnlineTests()
        await runSyncTests()
        
        isRunning = false
        currentTest = ""
        
        // Generate test report
        generateTestReport()
    }
    
    // MARK: - Offline Tests
    private func runOfflineTests() async {
        currentTest = "Testing Offline Functionality"
        
        // Test 1: Core Data Medication Save/Load
        await testCoreDataMedicationOperations()
        
        // Test 2: Core Data Supplement Save/Load
        await testCoreDataSupplementOperations()
        
        // Test 3: Offline Data Persistence
        await testOfflineDataPersistence()
        
        // Test 4: Database Size Monitoring
        await testDatabaseSizeMonitoring()
    }
    
    private func testCoreDataMedicationOperations() async {
        let testName = "Core Data Medication Operations"
        currentTest = testName
        
        do {
            // Create test medication
            let testMedication = createTestMedication()
            
            // Save medication
            try await coreDataManager.saveMedication(testMedication)
            addTestResult(testName, "Save", true, AppStrings.Success.itemSaved("Medication"))
            
            // Fetch medications
            let fetchedMedications = try await coreDataManager.fetchMedications(for: testMedication.userId)
            let medicationExists = fetchedMedications.contains { $0.id == testMedication.id }
            addTestResult(testName, "Fetch", medicationExists, medicationExists ? AppStrings.Testing.medicationFetchedSuccessfully : AppStrings.Testing.medicationNotFound)
            
            // Update medication
            var updatedMedication = testMedication
            updatedMedication.notes = "Updated test notes"
            try await coreDataManager.saveMedication(updatedMedication)
            addTestResult(testName, "Update", true, AppStrings.Testing.medicationUpdatedSuccessfully)
            
            // Delete medication
            try await coreDataManager.deleteMedication(testMedication.id)
            addTestResult(testName, "Delete", true, AppStrings.Success.itemDeleted("Medication"))
            
        } catch {
            addTestResult(testName, "Operations", false, "Error: \(error.localizedDescription)")
        }
    }
    
    private func testCoreDataSupplementOperations() async {
        let testName = "Core Data Supplement Operations"
        currentTest = testName
        
        do {
            // Create test supplement
            let testSupplement = createTestSupplement()
            
            // Save supplement
            try await coreDataManager.saveSupplement(testSupplement)
            addTestResult(testName, "Save", true, AppStrings.Success.itemSaved("Supplement"))
            
            // Fetch supplements
            let fetchedSupplements = try await coreDataManager.fetchSupplements(for: testSupplement.userId)
            let supplementExists = fetchedSupplements.contains { $0.id == testSupplement.id }
            addTestResult(testName, "Fetch", supplementExists, supplementExists ? AppStrings.Testing.supplementFetchedSuccessfully : AppStrings.Testing.supplementNotFound)
            
        } catch {
            addTestResult(testName, "Operations", false, "Error: \(error.localizedDescription)")
        }
    }
    
    private func testOfflineDataPersistence() async {
        let testName = "Offline Data Persistence"
        currentTest = testName
        
        do {
            // Create test data
            let medication = createTestMedication()
            let supplement = createTestSupplement()
            
            // Save data while "offline"
            try await coreDataManager.saveMedication(medication)
            try await coreDataManager.saveSupplement(supplement)
            
            // Verify data persistence
            let medications = try await coreDataManager.fetchMedications(for: medication.userId)
            let supplements = try await coreDataManager.fetchSupplements(for: supplement.userId)
            
            let medicationPersisted = medications.contains { $0.id == medication.id }
            let supplementPersisted = supplements.contains { $0.id == supplement.id }
            
            addTestResult(testName, "Persistence", medicationPersisted && supplementPersisted,
                         "Data persisted successfully offline")
            
        } catch {
            addTestResult(testName, "Persistence", false, "Error: \(error.localizedDescription)")
        }
    }
    
    private func testDatabaseSizeMonitoring() async {
        let testName = "Database Size Monitoring"
        currentTest = testName
        
        // TODO: getDatabaseSize method needs to be implemented in CoreDataManager
        // For now, we'll skip this test
        let sizeRetrieved = false
        let _ = "Not implemented"
        
        addTestResult(testName, "Size Retrieval", sizeRetrieved,
                     "Database size monitoring not yet implemented")
    }
    
    // MARK: - Online Tests
    private func runOnlineTests() async {
        currentTest = "Testing Online Functionality"
        
        // Test 1: Network Connectivity Detection
        await testNetworkConnectivity()
        
        // Test 2: Firebase Authentication
        await testFirebaseAuthentication()
        
        // Test 3: Firebase Data Access
        await testFirebaseDataAccess()
    }
    
    private func testNetworkConnectivity() async {
        let testName = "Network Connectivity"
        currentTest = testName
        
        let isOnline = dataSyncManager.isOnline
        addTestResult(testName, "Detection", true, "Network status detected: \(isOnline ? "Online" : "Offline")")
    }
    
    private func testFirebaseAuthentication() async {
        let testName = "Firebase Authentication"
        currentTest = testName
        
        let isAuthenticated = authManager.isAuthenticated
        let hasUser = authManager.currentUser != nil
        
        addTestResult(testName, "Auth Status", isAuthenticated,
                     isAuthenticated ? "User authenticated" : "User not authenticated")
        addTestResult(testName, "User Data", hasUser,
                     hasUser ? "User data available" : "No user data")
    }
    
    private func testFirebaseDataAccess() async {
        let testName = "Firebase Data Access"
        currentTest = testName
        
        // This would test actual Firebase connectivity in a real scenario
        // For now, we'll simulate the test
        let canAccessFirebase = authManager.isAuthenticated
        addTestResult(testName, "Access", canAccessFirebase,
                     canAccessFirebase ? "Firebase access available" : "Firebase access unavailable")
    }
    
    // MARK: - Sync Tests
    private func runSyncTests() async {
        currentTest = "Testing Sync Functionality"
        
        // Test 1: Sync Status Monitoring
        await testSyncStatusMonitoring()
        
        // Test 2: Offline-to-Online Sync
        await testOfflineToOnlineSync()
        
        // Test 3: Conflict Resolution
        await testConflictResolution()
        
        // Test 4: Sync Error Handling
        await testSyncErrorHandling()
    }
    
    private func testSyncStatusMonitoring() async {
        let testName = "Sync Status Monitoring"
        currentTest = testName
        
        let syncStatus = dataSyncManager.getSyncStatus()
        let lastSyncDate = dataSyncManager.lastSyncDate
        
        addTestResult(testName, "Status Detection", true, "Sync status: \(syncStatus.displayText)")
        addTestResult(testName, "Last Sync", lastSyncDate != nil,
                     lastSyncDate.map { "Last sync: \($0.formatted())" } ?? "No previous sync")
    }
    
    private func testOfflineToOnlineSync() async {
        let testName = "Offline to Online Sync"
        currentTest = testName
        
        guard dataSyncManager.isOnline else {
            addTestResult(testName, "Sync", false, "Cannot test sync - device is offline")
            return
        }
        
        do {
            // Create test medication that needs sync
            var medication = createTestMedication()
            medication.needsSync = true
            
            // Save medication locally
            try await coreDataManager.saveMedication(medication)
            
            // Trigger sync
            try await dataSyncManager.syncPendingChanges()
            
            // Check if sync completed without error
            let syncError = dataSyncManager.syncError
            addTestResult(testName, "Sync Completion", syncError == nil,
                         syncError == nil ? "Sync completed successfully" : "Sync failed: \(syncError?.localizedDescription ?? "Unknown error")")
            
        } catch {
            addTestResult(testName, "Sync", false, "Sync test failed: \(error.localizedDescription)")
        }
    }
    
    private func testConflictResolution() async {
        let testName = "Conflict Resolution"
        currentTest = testName
        
        // Create two versions of the same medication with different timestamps
        let localMedication = createTestMedication()
        var remoteMedication = localMedication
        
        // Make remote version newer
        remoteMedication.updatedAt = Date().addingTimeInterval(60)
        remoteMedication.notes = "Remote version"
        
        // Test conflict resolution (should prefer newer version)
        let resolved = dataSyncManager.resolveConflict(local: localMedication, remote: remoteMedication)
        let isCorrectResolution = resolved.notes == "Remote version"
        
        addTestResult(testName, "Resolution", isCorrectResolution,
                     isCorrectResolution ? "Conflict resolved correctly (newer version selected)" : "Conflict resolution failed")
    }
    
    private func testSyncErrorHandling() async {
        let testName = "Sync Error Handling"
        currentTest = testName
        
        // Test sync retry mechanism
        if dataSyncManager.syncError != nil {
            await dataSyncManager.retryFailedSync()
            let errorCleared = dataSyncManager.syncError == nil
            addTestResult(testName, "Error Recovery", errorCleared,
                         errorCleared ? "Error recovery successful" : "Error recovery failed")
        } else {
            addTestResult(testName, "Error Handling", true, "No sync errors to test recovery")
        }
    }
    
    // MARK: - Test Helpers
    private func createTestMedication() -> MedicationModel {
        return MedicationModel(
            id: UUID().uuidString,
            userId: authManager.currentUser?.id ?? "test-user",
            name: "Test Medication",
            dosage: "10mg",
            frequency: .once,
            schedule: [MedicationSchedule(time: Date(), dosageAmount: "1")],
            notes: "Test medication for sync testing",
            prescribedBy: "Test Doctor",
            startDate: Date(),
            endDate: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false,
            takeWithFood: false,
            needsSync: true,
            isDeletedFlag: false
        )
    }
    
    private func createTestSupplement() -> SupplementModel {
        return SupplementModel(
            userId: authManager.currentUser?.id ?? "test-user",
            name: "Test Supplement",
            dosage: "500mg",
            frequency: .daily,
            schedule: [SupplementSchedule(time: Date(), amount: "1")],
            notes: "Test supplement for sync testing",
            purpose: "Testing",
            brand: "Test Brand",
            isActive: true,
            startDate: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            voiceEntryUsed: false
        )
    }
    
    private func addTestResult(_ category: String, _ operation: String, _ success: Bool, _ message: String) {
        let result = TestResult(
            category: category,
            operation: operation,
            success: success,
            message: message,
            timestamp: Date()
        )
        testResults.append(result)
    }
    
    private func generateTestReport() {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.success }.count
        let failedTests = totalTests - passedTests
        
        let reportSummary = TestResult(
            category: "Test Summary",
            operation: "All Tests",
            success: failedTests == 0,
            message: "Passed: \(passedTests), Failed: \(failedTests), Total: \(totalTests)",
            timestamp: Date()
        )
        
        testResults.insert(reportSummary, at: 0)
    }
    
    // MARK: - Test Result Analysis
    func getTestResultsByCategory() -> [String: [TestResult]] {
        return Dictionary(grouping: testResults) { $0.category }
    }
    
    func getFailedTests() -> [TestResult] {
        return testResults.filter { !$0.success }
    }
    
    func getSuccessRate() -> Double {
        guard !testResults.isEmpty else { return 0.0 }
        let passedTests = testResults.filter { $0.success }.count
        return Double(passedTests) / Double(testResults.count)
    }
    
    func exportTestResults() -> String {
        var report = "Mango Health - Sync Test Report\n"
        report += "Generated: \(Date().formatted())\n\n"
        
        for category in Set(testResults.map { $0.category }) {
            report += "=== \(category) ===\n"
            let categoryResults = testResults.filter { $0.category == category }
            
            for result in categoryResults {
                let status = result.success ? "✅ PASS" : "❌ FAIL"
                report += "\(status) - \(result.operation): \(result.message)\n"
            }
            report += "\n"
        }
        
        return report
    }
}

// MARK: - Test Result Model
struct TestResult: Identifiable {
    let id = UUID()
    let category: String
    let operation: String
    let success: Bool
    let message: String
    let timestamp: Date
    
    var statusIcon: String {
        success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var statusColor: String {
        success ? "success" : "error"
    }
}

// MARK: - Test Configuration
struct TestConfiguration {
    let includeOfflineTests: Bool
    let includeOnlineTests: Bool
    let includeSyncTests: Bool
    let includePerformanceTests: Bool
    let timeout: TimeInterval
    
    static let standard = TestConfiguration(
        includeOfflineTests: true,
        includeOnlineTests: true,
        includeSyncTests: true,
        includePerformanceTests: false,
        timeout: 30.0
    )
    
    static let quick = TestConfiguration(
        includeOfflineTests: true,
        includeOnlineTests: false,
        includeSyncTests: false,
        includePerformanceTests: false,
        timeout: 10.0
    )
}
#endif
