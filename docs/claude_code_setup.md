# Claude Code Setup & Development Guide

## Overview
This document provides comprehensive setup instructions and best practices for Claude Code to minimize errors and ensure successful implementation of the Medication Management App.

## 1. Project Structure & Organization

### Recommended Xcode Project Structure
```
MedicationManager/
├── App/
│   ├── MedicationManagerApp.swift
│   ├── ContentView.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Authentication/
│   │   ├── AuthManager.swift
│   │   ├── GoogleSignInManager.swift
│   │   └── UserSession.swift
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   ├── FirebaseManager.swift
│   │   └── VertexAIClient.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Medication.swift
│   │   ├── Supplement.swift
│   │   ├── Diet.swift
│   │   └── Doctor.swift
│   └── Utilities/
│       ├── Constants.swift
│       ├── Extensions.swift
│       └── Helpers.swift
├── Features/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   ├── MyHealth/
│   │   ├── MyHealthView.swift
│   │   ├── MedicationsView.swift
│   │   ├── SupplementsView.swift
│   │   └── DietView.swift
│   ├── Groups/
│   │   ├── GroupsView.swift
│   │   └── CaregiverManagementView.swift
│   ├── DoctorList/
│   │   ├── DoctorListView.swift
│   │   └── AddDoctorView.swift
│   └── Conflicts/
│       ├── ConflictsView.swift
│       └── ConflictResultsView.swift
├── Resources/
│   ├── Assets.xcassets/
│   ├── SVG/
│   └── Localization/
└── Configuration/
    ├── Info.plist
    ├── GoogleService-Info.plist
    └── Configuration.swift
```

## 2. Essential Dependencies & Setup

### Package.swift Dependencies
```swift
// Package Dependencies
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    .package(url: "https://github.com/stripe/stripe-ios", from: "23.0.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSVGCoder", from: "1.7.0")
]

// Target Dependencies
targets: [
    .target(
        name: "MedicationManager",
        dependencies: [
            .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            .product(name: "Stripe", package: "stripe-ios"),
            .product(name: "SDWebImageSVGCoder", package: "SDWebImageSVGCoder")
        ]
    )
]
```

### Info.plist Configuration
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Firebase Configuration -->
    <key>REVERSED_CLIENT_ID</key>
    <string>$(GOOGLE_REVERSED_CLIENT_ID)</string>
    
    <!-- URL Schemes -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>GoogleSignIn</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>$(GOOGLE_REVERSED_CLIENT_ID)</string>
            </array>
        </dict>
    </array>
    
    <!-- Permissions -->
    <key>NSMicrophoneUsageDescription</key>
    <string>This app uses the microphone for voice input of medication information.</string>
    
    <key>NSContactsUsageDescription</key>
    <string>This app accesses your contacts to help you add doctors to your list.</string>
    
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>This app uses speech recognition to convert your voice input to text for medication entries.</string>
    
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>background-processing</string>
        <string>remote-notification</string>
    </array>
</dict>
</plist>
```

## 3. Core Implementation Guidelines

### Constants File Setup
```swift
// Constants.swift
import Foundation

struct AppConstants {
    // Firebase
    static let firebaseProjectId = "medication-manager-prod"
    
    // Vertex AI
    static let vertexAIEndpoint = "https://us-central1-aiplatform.googleapis.com"
    static let medgemmaModel = "medgemma-27b"
    
    // Subscription Products
    static let monthlySubscriptionId = "com.medicationmanager.monthly"
    static let annualSubscriptionId = "com.medicationmanager.annual"
    
    // Notification Categories
    static let medicationReminderCategory = "medication-reminder"
    static let conflictAlertCategory = "conflict-alert"
    
    // User Defaults Keys
    struct UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let notificationPermissionGranted = "notificationPermissionGranted"
        static let voiceInputEnabled = "voiceInputEnabled"
    }
    
    // UI Constants
    struct UI {
        static let cardCornerRadius: CGFloat = 12
        static let standardPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let animationDuration: Double = 0.3
    }
}
```

### Error Handling Strategy
```swift
// AppError.swift
import Foundation

enum AppError: LocalizedError, Equatable {
    case authentication(AuthError)
    case network(NetworkError)
    case voice(VoiceError)
    case data(DataError)
    case payment(PaymentError)
    
    var errorDescription: String? {
        switch self {
        case .authentication(let authError):
            return authError.localizedDescription
        case .network(let networkError):
            return networkError.localizedDescription
        case .voice(let voiceError):
            return voiceError.localizedDescription
        case .data(let dataError):
            return dataError.localizedDescription
        case .payment(let paymentError):
            return paymentError.localizedDescription
        }
    }
}

enum AuthError: LocalizedError {
    case signInFailed
    case signOutFailed
    case userNotFound
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return "Sign in failed. Please try again."
        case .signOutFailed:
            return "Sign out failed. Please try again."
        case .userNotFound:
            return "User not found. Please sign up first."
        case .invalidCredentials:
            return "Invalid credentials. Please check your email and password."
        }
    }
}

// Similar enums for NetworkError, VoiceError, DataError, PaymentError
```

## 4. Data Models Implementation

### User Model
```swift
import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    let displayName: String
    var subscriptionStatus: SubscriptionStatus
    var subscriptionType: SubscriptionType?
    let trialEndDate: Date?
    let createdAt: Date
    var lastLoginAt: Date
    var caregiverAccess: CaregiverAccess
    
    enum SubscriptionStatus: String, Codable, CaseIterable {
        case trial = "trial"
        case active = "active"
        case expired = "expired"
    }
    
    enum SubscriptionType: String, Codable, CaseIterable {
        case monthly = "monthly"
        case annual = "annual"
    }
    
    struct CaregiverAccess: Codable {
        var enabled: Bool
        var caregivers: [CaregiverInfo]
        
        struct CaregiverInfo: Codable, Identifiable {
            let id: String
            let caregiverId: String
            let accessLevel: AccessLevel
            let grantedAt: Date
            var permissions: [Permission]
            
            enum AccessLevel: String, Codable {
                case readonly = "readonly"
            }
            
            enum Permission: String, Codable, CaseIterable {
                case myhealth = "myhealth"
                case doctorlist = "doctorlist"
            }
        }
    }
}
```

### Medication Model
```swift
import Foundation
import FirebaseFirestore

struct Medication: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let dosage: String
    let frequency: String
    var schedule: [MedicationSchedule]
    let notes: String?
    let createdAt: Date
    var updatedAt: Date
    
    struct MedicationSchedule: Codable, Identifiable {
        let id = UUID()
        let time: Date
        let dosageAmount: String
        let instructions: String?
        var isCompleted: Bool = false
        var completedAt: Date?
    }
}

// Similar models for Supplement, Diet, Doctor
```

## 5. Firebase Integration Best Practices

### FirebaseManager Implementation
```swift
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
        configurFirestore()
    }
    
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                if let user = user {
                    await self?.loadUserProfile(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func configurFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    // CRUD Operations with proper error handling
    func createUser(_ user: User) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AppError.authentication(.userNotFound)
        }
        
        try await db.collection("users").document(userId).setData(from: user)
    }
    
    func loadUserProfile(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            self.currentUser = try document.data(as: User.self)
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
}
```

## 6. Voice Input Implementation

### SpeechManager Class
```swift
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = status == .authorized
            }
        }
    }
    
    func startRecording() throws {
        // Reset previous session
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw AppError.voice(.recognitionRequestFailed)
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil {
                DispatchQueue.main.async {
                    self?.stopRecording()
                }
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
```

## 7. Common Error Prevention Strategies

### Memory Management
```swift
// Use weak references in closures
class SomeManager {
    func performAsyncOperation() {
        someAsyncCall { [weak self] result in
            guard let self = self else { return }
            // Handle result
        }
    }
}

// Proper cancellable management
class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
}
```

### Network Request Best Practices
```swift
// Proper async/await error handling
func fetchData() async throws -> Data {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        return data
    } catch {
        if error is NetworkError {
            throw error
        } else {
            throw NetworkError.unknown(error)
        }
    }
}
```

## 8. Testing Setup

### Unit Test Structure
```swift
import XCTest
@testable import MedicationManager

class MedicationManagerTests: XCTestCase {
    var firebaseManager: FirebaseManager!
    
    override func setUpWithError() throws {
        firebaseManager = FirebaseManager()
    }
    
    override func tearDownWithError() throws {
        firebaseManager = nil
    }
    
    func testUserCreation() async throws {
        // Test implementation
    }
}
```

## 9. Debugging Configuration

### Debug Flags
```swift
#if DEBUG
struct DebugConfig {
    static let enableVerboseLogging = true
    static let useTestFirebaseProject = true
    static let skipOnboarding = false
    static let mockVoiceInput = true
}
#endif
```

## 10. Common Claude Code Error Prevention

### Issues to Avoid:
1. **Missing async/await**: Always use proper async/await for Firebase operations
2. **Memory leaks**: Use weak references in closures and proper cancellable management
3. **Permission handling**: Always check and request permissions before using features
4. **Error handling**: Implement comprehensive error handling for all async operations
5. **State management**: Use @MainActor for UI updates and proper state binding
6. **Resource cleanup**: Properly clean up audio sessions, recognition tasks, and network requests

### Best Practices:
1. **Incremental development**: Build one feature at a time and test thoroughly
2. **Modular architecture**: Keep components separate and testable
3. **Dependency injection**: Use proper dependency injection for testability
4. **Configuration management**: Use environment-specific configurations
5. **Logging**: Implement comprehensive logging for debugging

This setup guide provides Claude Code with a solid foundation to build upon, minimizing common errors and ensuring successful implementation.