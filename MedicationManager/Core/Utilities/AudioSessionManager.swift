import Foundation
@preconcurrency import AVFoundation
@preconcurrency import Speech
import OSLog
import UIKit

// MARK: - Audio Events
/// Domain events representing audio system state changes
enum AudioEvent: Sendable {
    case recordingStarted
    case recordingStopped
    case audioDataReceived // Remove the buffer as it's not Sendable
    case recognitionResult(String, isFinal: Bool)
    case recognitionError(Error)
    case audioSessionInterrupted(InterruptionType)
    case audioRouteChanged(RouteChangeReason)
    case microphonePermissionChanged(Bool)
    case speechPermissionChanged(Bool)
    
    enum InterruptionType: Sendable {
        case began
        case ended(shouldResume: Bool)
    }
    
    enum RouteChangeReason: Sendable {
        case oldDeviceUnavailable
        case categoryChange
        case other
    }
}

// MARK: - Speech Recognizer Delegate Handler
/// Handles speech recognizer delegate callbacks and forwards them to the AudioSessionManager
private final class SpeechRecognizerDelegateHandler: NSObject, SFSpeechRecognizerDelegate, @unchecked Sendable {
    private let eventHandler: @Sendable (AudioEvent) async -> Void
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "AudioSession")
    
    init(eventHandler: @escaping @Sendable (AudioEvent) async -> Void) {
        self.eventHandler = eventHandler
        super.init()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        logger.debug("Speech recognizer availability changed: \(available)")
        
        if !available {
            Task { @Sendable in
                await eventHandler(.recognitionError(AppError.voice(.speechRecognitionUnavailable)))
            }
        }
    }
}

// MARK: - Audio Session Manager
/// System layer responsible for managing audio resources and system notifications
/// This actor ensures thread-safe access to audio resources and prevents data races
actor AudioSessionManager {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: Configuration.App.bundleId, category: "AudioSession")
    private let eventHandler: @Sendable (AudioEvent) async -> Void
    
    // Audio components
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Delegate handler
    private var delegateHandler: SpeechRecognizerDelegateHandler?
    
    // Notification observers
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var appLifecycleObserver: NSObjectProtocol?
    
    // State tracking for defensive programming
    private var hasActiveTap = false
    private let tapQueue = DispatchQueue(label: "com.medicationmanager.audiotap", qos: .userInitiated)
    
    // MARK: - Initialization
    init(eventHandler: @escaping @Sendable (AudioEvent) async -> Void) {
        self.eventHandler = eventHandler
    }
    
    /// Initialize the audio session manager - must be called after creation
    func initialize() async {
        setupSpeechRecognizer()
        setupNotifications()
    }
    
    /// Cleanup resources - must be called before releasing the manager
    func shutdown() async {
        cleanup()
        removeNotificationObservers()
    }
    
    // MARK: - Setup
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        delegateHandler = SpeechRecognizerDelegateHandler(eventHandler: eventHandler)
        speechRecognizer?.delegate = delegateHandler
        
        logger.debug("Speech recognizer initialized")
    }
    
    private func setupNotifications() {
        let handler = self.eventHandler
        let log = self.logger
        
        // Audio session interruption
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            let shouldResumeValue: Bool = {
                if case .ended = type,
                   let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    return options.contains(.shouldResume)
                }
                return false
            }()
            
            Task { @Sendable in
                switch type {
                case .began:
                    log.info("Audio interruption began")
                    await handler(.audioSessionInterrupted(.began))
                    
                case .ended:
                    log.info("Audio interruption ended, shouldResume: \(shouldResumeValue)")
                    await handler(.audioSessionInterrupted(.ended(shouldResume: shouldResumeValue)))
                    
                @unknown default:
                    log.warning("Unknown interruption type")
                }
            }
        }
        
        // Audio route changes
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }
            
            Task { @Sendable in
                switch reason {
                case .oldDeviceUnavailable:
                    log.info("Audio device unavailable")
                    await handler(.audioRouteChanged(.oldDeviceUnavailable))
                    
                case .categoryChange:
                    log.info("Audio category changed")
                    await handler(.audioRouteChanged(.categoryChange))
                    
                default:
                    await handler(.audioRouteChanged(.other))
                }
            }
        }
        
        // App lifecycle
        appLifecycleObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @Sendable in
                log.info("App entering background")
                // We need to handle this differently since we can't call actor methods
                await handler(.audioSessionInterrupted(.began))
            }
        }
        
        logger.debug("Notification observers setup completed")
    }
    
    // MARK: - Public Interface
    
    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            let handler = self.eventHandler
            AVAudioApplication.requestRecordPermission { granted in
                Task { @Sendable in
                    await handler(.microphonePermissionChanged(granted))
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Request speech recognition permission
    func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            let handler = self.eventHandler
            SFSpeechRecognizer.requestAuthorization { status in
                let granted = status == .authorized
                Task { @Sendable in
                    await handler(.speechPermissionChanged(granted))
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Check current permissions
    func checkPermissions() -> (microphone: Bool, speech: Bool) {
        let microphoneStatus = AVAudioApplication.shared.recordPermission == .granted
        let speechStatus = SFSpeechRecognizer.authorizationStatus() == .authorized
        return (microphoneStatus, speechStatus)
    }
    
    /// Start audio recording and speech recognition
    func startRecording() async throws {
        logger.debug("Starting recording")
        
        // Setup audio session
        try await setupAudioSession()
        
        // Clean up any existing recording
        await cleanupRecording()
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw AppError.voice(.speechRecognitionFailed)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Setup audio tap
        try await setupAudioTap(recognitionRequest: recognitionRequest)
        
        // Start recognition task
        try await startRecognitionTask(request: recognitionRequest)
        
        // Start audio engine
        try startAudioEngine()
        
        // Notify recording started
        await eventHandler(.recordingStarted)
        
        logger.info("Recording started successfully")
    }
    
    /// Stop recording
    func stopRecording() async {
        logger.debug("Stopping recording")
        
        await cleanupRecording()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        // Notify recording stopped
        await eventHandler(.recordingStopped)
        
        logger.info("Recording stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            logger.debug("Audio session activated")
        } catch {
            logger.error("Failed to setup audio session: \(error)")
            throw AppError.voice(.audioSessionError)
        }
    }
    
    private func setupAudioTap(recognitionRequest: SFSpeechAudioBufferRecognitionRequest) async throws {
        let inputNode = audioEngine.inputNode
        
        // Ensure we have audio input
        guard inputNode.numberOfInputs > 0 else {
            logger.error("No audio input available")
            throw AppError.voice(.audioSessionError)
        }
        
        // Remove any existing tap (defensive programming)
        await removeTapSafely()
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on background queue to avoid blocking
        let handler = self.eventHandler
        let log = self.logger
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tapQueue.async {
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                    
                    // Notify audio data received
                    Task { @Sendable in
                        await handler(.audioDataReceived)
                    }
                }
                
                log.debug("Audio tap installed")
                continuation.resume()
            }
        }
        
        hasActiveTap = true
    }
    
    private func startRecognitionTask(request: SFSpeechAudioBufferRecognitionRequest) async throws {
        guard let speechRecognizer = speechRecognizer else {
            throw AppError.voice(.speechRecognitionUnavailable)
        }
        
        let handler = eventHandler
        recognitionTask = speechRecognizer.recognitionTask(with: request) { (result: SFSpeechRecognitionResult?, error: Error?) in
            // Extract values from non-Sendable types before Task
            let transcription = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let recognitionError = error
            
            Task { @Sendable in
                if let transcription = transcription {
                    await handler(.recognitionResult(
                        transcription,
                        isFinal: isFinal
                    ))
                }
                
                if let recognitionError = recognitionError {
                    await handler(.recognitionError(recognitionError))
                }
            }
        }
        
        guard recognitionTask != nil else {
            throw AppError.voice(.speechRecognitionFailed)
        }
        
        logger.debug("Recognition task started")
    }
    
    private func startAudioEngine() throws {
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            logger.debug("Audio engine started")
        } catch {
            // Clean up on failure
            Task {
                await removeTapSafely()
            }
            logger.error("Failed to start audio engine: \(error)")
            throw AppError.voice(.audioSessionError)
        }
    }
    
    private func cleanupRecording() async {
        // Cancel recognition task - already on actor, no need for continuation
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Remove audio tap
        await removeTapSafely()
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        logger.debug("Recording cleanup completed")
    }
    
    private func removeTapSafely() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let engine = self.audioEngine
            let log = self.logger
            let hasTap = self.hasActiveTap
            
            tapQueue.async {
                guard hasTap else {
                    continuation.resume()
                    return
                }
                
                let inputNode = engine.inputNode
                if inputNode.numberOfInputs > 0 {
                    inputNode.removeTap(onBus: 0)
                    log.debug("Audio tap removed")
                }
                
                continuation.resume()
            }
        }
        
        hasActiveTap = false
    }
    
    // MARK: - Notification Handlers
    
    nonisolated private func handleAudioSessionInterruption(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        let handler = eventHandler
        let log = logger
        let interruptionType = type
        let shouldResumeValue: Bool = {
            if case .ended = type,
               let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                return options.contains(.shouldResume)
            }
            return false
        }()
        
        Task { @Sendable in
            switch interruptionType {
            case .began:
                log.info("Audio interruption began")
                await handler(.audioSessionInterrupted(.began))
                
            case .ended:
                log.info("Audio interruption ended, shouldResume: \(shouldResumeValue)")
                await handler(.audioSessionInterrupted(.ended(shouldResume: shouldResumeValue)))
                
            @unknown default:
                log.warning("Unknown interruption type")
            }
        }
    }
    
    private func handleAudioRouteChange(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        let handler = eventHandler
        let log = logger
        let routeChangeReason = reason
        
        Task { @Sendable in
            switch routeChangeReason {
            case .oldDeviceUnavailable:
                log.info("Audio device unavailable")
                await handler(.audioRouteChanged(.oldDeviceUnavailable))
                
            case .categoryChange:
                log.info("Audio category changed")
                await handler(.audioRouteChanged(.categoryChange))
                
            default:
                await handler(.audioRouteChanged(.other))
            }
        }
    }
    
    private func handleAppBackground() async {
        logger.info("App entering background")
        await stopRecording()
    }
    
    private func removeNotificationObservers() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = appLifecycleObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func cleanup() {
        Task {
            await cleanupRecording()
        }
        speechRecognizer?.delegate = nil
        speechRecognizer = nil
        delegateHandler = nil
    }
    
}
