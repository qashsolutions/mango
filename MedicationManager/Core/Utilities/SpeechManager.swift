import Foundation
import Speech
import AVFoundation
import Observation
import OSLog

// MARK: - Task Storage
/// Non-isolated storage for tasks that need to be cancelled in deinit
private final class TaskStorage: @unchecked Sendable {
    private var tasks: [Task<Void, Never>] = []
    private let lock = NSLock()
    
    func add(_ task: Task<Void, Never>) {
        lock.lock()
        defer { lock.unlock() }
        tasks.append(task)
    }
    
    func remove(_ task: Task<Void, Never>) {
        lock.lock()
        defer { lock.unlock() }
        tasks.removeAll { $0 == task }
    }
    
    func cancelAll() {
        lock.lock()
        defer { lock.unlock() }
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

// MARK: - Speech Manager (UI Layer)
/// UI Layer responsible for managing speech recognition UI state and user interactions
/// This class is @MainActor isolated for SwiftUI integration
@MainActor
@Observable
final class SpeechManager: SpeechManagerProtocol {
    static let shared = SpeechManager()
    
    // MARK: - Observable UI State
    var isRecording: Bool = false
    var isAuthorized: Bool = false
    var recognizedText: String = ""
    var speechError: AppError?
    var isProcessing: Bool = false
    
    // MARK: - Private Properties
    private let recognitionActor: SpeechRecognitionActor
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "SpeechManager")
    
    // Timer management for context-specific recognition
    private var contextTimer: Task<Void, Never>?
    
    // State observation task
    private var stateObservationTask: Task<Void, Never>?
    
    // Task storage for cleanup in deinit (nonisolated)
    private let taskStorage = TaskStorage()
    
    // MARK: - Initialization
    private init() {
        self.recognitionActor = SpeechRecognitionActor()
        
        checkAuthorizationStatus()
        startStateObservation()
        
        // Initialize the recognition actor
        Task {
            await recognitionActor.initialize()
        }
        
        logger.info("SpeechManager initialized")
    }
    
    deinit {
        // Cancel tasks through nonisolated storage
        taskStorage.cancelAll()
    }
    
    // MARK: - Setup
    
    private func checkAuthorizationStatus() {
        // Check speech recognition authorization
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            isAuthorized = true
        case .denied, .restricted, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    /// Start observing actor state changes
    private func startStateObservation() {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                
                // Poll state every 100ms
                try? await Task.sleep(for: .milliseconds(100))
                
                // Update UI based on actor state
                let state = await self.recognitionActor.getCurrentState()
                self.updateUIForState(state)
                
                // Update recognized text if available
                if let result = await self.recognitionActor.currentResult {
                    self.recognizedText = result.text
                }
            }
        }
        
        stateObservationTask = task
        taskStorage.add(task)
    }
    
    /// Update UI state based on recognition state
    private func updateUIForState(_ state: RecognitionState) {
        switch state {
        case .idle:
            isRecording = false
            isProcessing = false
            speechError = nil
            
        case .requestingPermissions:
            isProcessing = true
            
        case .permissionsGranted:
            isAuthorized = true
            isProcessing = false
            
        case .permissionsDenied(let reason):
            isAuthorized = false
            isProcessing = false
            
            switch reason {
            case .microphone, .both:
                speechError = AppError.voice(.microphonePermissionDenied)
            case .speechRecognition:
                speechError = AppError.voice(.speechRecognitionUnavailable)
            }
            
        case .preparing:
            isProcessing = true
            
        case .recording:
            isRecording = true
            isProcessing = false
            
        case .processing:
            isProcessing = true
            
        case .stopped:
            isRecording = false
            isProcessing = false
            
        case .error(let error):
            isRecording = false
            isProcessing = false
            speechError = error
        }
    }
    
    // MARK: - Public Interface
    
    /// Request speech authorization
    func requestSpeechAuthorization() async {
        logger.debug("Requesting speech authorization")
        _ = await recognitionActor.requestPermissions()
    }
    
    /// Start recording
    func startRecording() async throws {
        logger.debug("Start recording requested from UI")
        
        clearError()
        recognizedText = ""
        
        do {
            try await recognitionActor.startRecording()
        } catch {
            logger.error("Failed to start recording: \(error)")
            throw error
        }
    }
    
    /// Stop recording
    func stopRecording() {
        logger.debug("Stop recording requested from UI")
        
        Task {
            await recognitionActor.stopRecording()
        }
    }
    
    /// Reset speech recognition
    func resetSpeechRecognition() {
        logger.debug("Reset requested from UI")
        
        Task {
            await recognitionActor.reset()
        }
        
        recognizedText = ""
        speechError = nil
        isProcessing = false
        isRecording = false
    }
    
    /// Clear error state
    func clearError() {
        speechError = nil
    }
    
    // MARK: - Specialized Voice Input
    
    /// Recognize medication name with timeout
    func recognizeMedicationName() async throws -> String {
        logger.debug("Recognizing medication name")
        
        try await startRecordingWithContext(.medicationName, timeout: .seconds(5))
        return recognizedText
    }
    
    /// Recognize dosage with timeout
    func recognizeDosage() async throws -> String {
        logger.debug("Recognizing dosage")
        
        try await startRecordingWithContext(.dosage, timeout: .seconds(3))
        return recognizedText
    }
    
    /// Recognize frequency with timeout
    func recognizeFrequency() async throws -> String {
        logger.debug("Recognizing frequency")
        
        try await startRecordingWithContext(.frequency, timeout: .seconds(5))
        return recognizedText
    }
    
    // MARK: - Private Methods
    
    /// Start recording with specific context and timeout
    private func startRecordingWithContext(_ context: VoiceInteractionContext, timeout: Duration) async throws {
        // Cancel any existing timer
        if let existingTimer = contextTimer {
            existingTimer.cancel()
            taskStorage.remove(existingTimer)
        }
        
        // Start recording
        try await recognitionActor.startRecording(context: context)
        
        // Start timeout timer
        let timerTask = Task { [weak self] in
            do {
                try await Task.sleep(for: timeout)
                
                // Stop recording after timeout
                self?.stopRecording()
                
                // Process the result for context
                if let self = self {
                    let text = self.recognizedText
                    if !text.isEmpty {
                        let processedText = await self.recognitionActor.processTextForContext(text, context: context)
                        self.recognizedText = processedText
                    }
                }
            } catch {
                // Task cancelled
            }
        }
        
        contextTimer = timerTask
        taskStorage.add(timerTask)
        
        // Wait for the timer to complete
        _ = await timerTask.value
    }
}

// MARK: - Development Support
#if DEBUG
extension SpeechManager {
    static let mockSpeechManager: SpeechManager = {
        let manager = SpeechManager()
        manager.isAuthorized = true
        manager.recognizedText = "Lisinopril 10 mg once daily"
        return manager
    }()
}
#endif