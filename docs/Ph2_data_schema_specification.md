# Data Schema Specification - Mango Health App

## 🎯 Overview
This document defines the complete data models for the Mango Health medication management app. All models must support Firebase Firestore sync and Core Data local caching.

## 📱 Core Data Models

### 1. User Model
```swift
struct User: Codable, Identifiable {
    let id: String                    // Firebase Auth UID
    let email: String
    let displayName: String
    let profileImageURL: String?
    let createdAt: Date
    var lastLoginAt: Date
    var subscriptionStatus: SubscriptionStatus
    var subscriptionType: SubscriptionType?
    let trialEndDate: Date?
    var preferences: UserPreferences
    var caregiverAccess: CaregiverAccess
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case trial = "trial"
    case active = "active"  
    case expired = "expired"
}

enum SubscriptionType: String, Codable, CaseIterable {
    case monthly = "monthly"
    case annual = "annual"
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var voiceInputEnabled: Bool = true
    var reminderFrequency: ReminderFrequency = .threeDaily
    var timeZone: String
    var language: String = "en"
}

enum ReminderFrequency: String, Codable, CaseIterable {
    case threeDaily = "three_daily"   // Breakfast, lunch, dinner
    case custom = "custom"
}
```

### 2. Medication Model
```swift
struct Medication: Codable, Identifiable {
    let id: String = UUID().uuidString
    let userId: String                // Owner's user ID
    var name: String
    var dosage: String               // "10mg", "2 tablets"
    var frequency: MedicationFrequency
    var schedule: [MedicationSchedule]
    var notes: String?
    var prescribedBy: String?        // Doctor name
    var startDate: Date
    var endDate: Date?               // For temporary medications
    var isActive: Bool = true
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool = false // Track if entered via voice
}

enum MedicationFrequency: String, Codable, CaseIterable {
    case once = "once_daily"
    case twice = "twice_daily"
    case thrice = "three_times_daily"
    case asNeeded = "as_needed"
    case custom = "custom"
}

struct MedicationSchedule: Codable, Identifiable {
    let id: String = UUID().uuidString
    var time: Date                   // Time of day to take
    var dosageAmount: String         // Amount for this specific time
    var instructions: String?        // "Take with food", "Before bed"
    var isCompleted: Bool = false
    var completedAt: Date?
    var skipped: Bool = false
    var skippedReason: String?
}
```

### 3. Supplement Model
```swift
struct Supplement: Codable, Identifiable {
    let id: String = UUID().uuidString
    let userId: String
    var name: String
    var dosage: String
    var frequency: SupplementFrequency
    var schedule: [SupplementSchedule]
    var notes: String?
    var purpose: String?             // "Vitamin D", "Joint health"
    var brand: String?
    var isActive: Bool = true
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool = false
}

enum SupplementFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case asNeeded = "as_needed"
    case custom = "custom"
}

struct SupplementSchedule: Codable, Identifiable {
    let id: String = UUID().uuidString
    var time: Date
    var amount: String
    var withMeal: Bool = false
    var isCompleted: Bool = false
    var completedAt: Date?
}
```

### 4. Diet Model
```swift
struct DietEntry: Codable, Identifiable {
    let id: String = UUID().uuidString
    let userId: String
    var mealType: MealType
    var foods: [FoodItem]
    var allergies: [String]          // Food allergies to track
    var notes: String?
    var scheduledTime: Date?         // Planned meal time
    var actualTime: Date?            // When actually eaten
    let date: Date                   // Date of the meal
    let createdAt: Date
    var updatedAt: Date
    var voiceEntryUsed: Bool = false
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
}

struct FoodItem: Codable, Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var quantity: String?
    var calories: Int?
    var notes: String?
}
```

### 5. Doctor Model
```swift
struct Doctor: Codable, Identifiable {
    let id: String = UUID().uuidString
    let userId: String
    var name: String
    var specialty: String
    var phoneNumber: String?
    var email: String?
    var address: DoctorAddress?
    var notes: String?
    var isImportedFromContacts: Bool = false
    var contactIdentifier: String?   // iOS Contacts framework ID
    let createdAt: Date
    var updatedAt: Date
}

struct DoctorAddress: Codable {
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String = "US"
}
```

### 6. Caregiver Access Model
```swift
struct CaregiverAccess: Codable {
    var enabled: Bool = false
    var caregivers: [CaregiverInfo] = []
    var maxCaregivers: Int = 3       // From Configuration.App.maxCaregivers
}

struct CaregiverInfo: Codable, Identifiable {
    let id: String = UUID().uuidString
    let caregiverId: String          // Caregiver's Firebase user ID
    let caregiverEmail: String
    let caregiverName: String
    let accessLevel: AccessLevel = .readonly
    let grantedAt: Date
    var permissions: [Permission] = [.myhealth, .doctorlist]
    var notificationsEnabled: Bool = true
    var isActive: Bool = true
}

enum AccessLevel: String, Codable {
    case readonly = "readonly"
    // Future: Could add "edit" permissions
}

enum Permission: String, Codable, CaseIterable {
    case myhealth = "myhealth"
    case doctorlist = "doctorlist"
    case groups = "groups"           // Future feature
    case conflicts = "conflicts"     // Future feature
}
```

### 7. Conflict Detection Model
```swift
struct MedicationConflict: Codable, Identifiable {
    let id: String = UUID().uuidString
    let userId: String
    let queryText: String            // Original voice/text query
    let medications: [String]        // Medication IDs involved
    let supplements: [String]        // Supplement IDs involved
    let conflictsFound: Bool
    let severity: ConflictSeverity?
    let conflictDetails: [ConflictDetail]
    let recommendations: [String]
    let educationalInfo: String?
    let source: ConflictSource
    let createdAt: Date
    var isResolved: Bool = false
    var userNotes: String?
}

enum ConflictSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct ConflictDetail: Codable, Identifiable {
    let id: String = UUID().uuidString
    let medication1: String
    let medication2: String?         // Could be medication or supplement
    let interactionType: String
    let description: String
    let severity: ConflictSeverity
}

enum ConflictSource: String, Codable {
    case medgemma = "medgemma_ai"
    case manual = "manual_entry"
    case scheduled = "scheduled_check"
}
```

## 🔥 Firebase Firestore Structure

### Collection Hierarchy
```
/users/{userId}
├── /medications/{medicationId}
├── /supplements/{supplementId}  
├── /diet/{dietEntryId}
├── /doctors/{doctorId}
├── /conflicts/{conflictId}
├── /caregiverAccess/{caregiverId}
└── /preferences (document)
```

### Security Rules Requirements
```javascript
// Users can only access their own data
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  
  // Caregiver read-only access
  match /{document=**} {
    allow read: if request.auth != null && 
      (request.auth.uid == userId || 
       exists(/databases/$(database)/documents/users/$(userId)/caregiverAccess/$(request.auth.uid)));
  }
}
```

## 💾 Core Data Integration

### Entity Relationships
- **User** ↔ **Medications** (One-to-Many)
- **User** ↔ **Supplements** (One-to-Many)
- **User** ↔ **DietEntries** (One-to-Many)
- **User** ↔ **Doctors** (One-to-Many)
- **User** ↔ **Conflicts** (One-to-Many)

### Sync Strategy
- **Firebase**: Primary cloud storage
- **Core Data**: Local cache for offline access
- **Sync Logic**: Bidirectional with conflict resolution (last-write-wins)

## 🎯 Voice Input Integration

### Voice-Captured Fields
All models include `voiceEntryUsed: Bool` to track:
- Which entries were created via voice input
- Analytics for voice feature usage
- UI indicators for voice-created content

### Voice Processing Requirements
- **Apple Speech Framework** for speech-to-text
- **Smart autocomplete** for medication names
- **Confirmation screens** for voice entries
- **Edit capability** for voice-to-text corrections

## 📱 UI Data Binding

### ObservableObject Wrappers
Each model needs corresponding ViewModel:
- `MedicationManager: ObservableObject`
- `SupplementManager: ObservableObject`
- `DietManager: ObservableObject`
- `DoctorManager: ObservableObject`

### SwiftUI Integration
- Use `@StateObject` for managers
- `@Published` properties for UI updates
- Async/await for all Firebase operations
- Error handling with user-friendly messages

## 🔧 Implementation Notes

### Required Imports
```swift
import Foundation
import FirebaseFirestore
import CoreData
import SwiftUI
import Speech              // For voice input
import AVFoundation        // For audio sessions
import Contacts            // For doctor contact integration
```

### Error Handling
- All Firebase operations must include comprehensive error handling
- Use AppStrings for user-facing error messages
- Detailed logging for debugging
- Graceful offline/online transitions

### Performance Considerations
- Lazy loading for large datasets
- Pagination for medication lists
- Efficient Core Data predicates
- Background sync operations

## 🎙️ Voice Input Architecture

### Core Voice Components Required
```swift
// Core/Utilities/SpeechManager.swift
@MainActor
class SpeechManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
}

// Core/Utilities/VoiceInputViewModel.swift
@Observable
class VoiceInputViewModel {
    var showingVoiceInput = false
    var voiceText = ""
    var isProcessing = false
    var errorMessage: String?
}
```

### Medical Terminology Support
```swift
// Core/Utilities/MedicationAutoComplete.swift
struct MedicationAutoComplete {
    static let commonMedications = [
        "Acetaminophen", "Ibuprofen", "Aspirin", "Metformin",
        "Lisinopril", "Atorvastatin", "Amlodipine", "Omeprazole"
        // Expand with comprehensive medication database
    ]
    
    static func suggestions(for input: String) -> [String] {
        // Smart autocomplete logic
    }
}
```

## 🔄 Data Sync Architecture

### Firebase + Core Data Hybrid Strategy
```swift
// Core/Networking/DataSyncManager.swift
@Observable
class DataSyncManager {
    var isOnline = true
    var lastSyncDate: Date?
    var syncInProgress = false
    
    func syncAllData() async throws {
        // 1. Sync medications
        // 2. Sync supplements  
        // 3. Sync diet entries
        // 4. Sync doctors
        // 5. Update last sync timestamp
    }
}
```

### Offline-First Design
```swift
// Always save to Core Data first, then sync to Firebase
protocol SyncableModel {
    var id: String { get }
    var updatedAt: Date { get set }
    var needsSync: Bool { get set }
    var isDeleted: Bool { get set }
}
```

## 📱 UI Architecture Patterns

### View Hierarchy Structure
```
ContentView (Auth Gate)
├── AuthenticationView (if not authenticated)
└── MainTabView (if authenticated)
    ├── MyHealthView
    │   ├── MedicationsListView
    │   ├── SupplementsListView
    │   └── DietTrackingView
    ├── GroupsView
    │   ├── CaregiverListView
    │   └── CaregiverInviteView
    ├── DoctorListView
    │   ├── DoctorCardView
    │   └── AddDoctorView
    └── ConflictsView
        ├── ConflictQueryView
        └── ConflictHistoryView
```

### Navigation State Management
```swift
// Core/Navigation/NavigationManager.swift
@Observable
class NavigationManager {
    var selectedTab: TabType = .myHealth
    var myHealthSubTab: MyHealthSubTab = .medications
    var showingAddMedication = false
    var showingVoiceInput = false
}

enum TabType: String, CaseIterable {
    case myHealth = "myHealth"
    case groups = "groups" 
    case doctorList = "doctorList"
    case conflicts = "conflicts"
}

enum MyHealthSubTab: String, CaseIterable {
    case medications = "medications"
    case supplements = "supplements"
    case diet = "diet"
}
```

## 🎨 UI Component Architecture

### Reusable Components Required
```swift
// Core/UI/Components/VoiceInputButton.swift
struct VoiceInputButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: AppIcons.voice)
                .font(AppTheme.Typography.title2)
                .foregroundColor(isRecording ? AppTheme.Colors.error : AppTheme.Colors.primary)
        }
        .accessibility(label: Text(AppStrings.Accessibility.voiceInputButton))
    }
}

// Core/UI/Components/MedicationCard.swift
struct MedicationCard: View {
    let medication: Medication
    @State private var isExpanded = false
    
    var body: some View {
        // Expandable card with medication details
        // Voice indicator if entered via voice
        // Schedule display
        // Edit/delete actions
    }
}
```

### Form Input Components
```swift
// Core/UI/Components/VoiceEnabledTextField.swift
struct VoiceEnabledTextField: View {
    @Binding var text: String
    let placeholder: String
    @State private var showingVoiceInput = false
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
            
            VoiceInputButton(isRecording: .constant(false)) {
                showingVoiceInput = true
            }
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView(text: $text)
        }
    }
}
```

## 🔐 Security & Privacy Implementation

### Data Protection Requirements
```swift
// Core/Security/DataProtection.swift
class DataProtection {
    static func encryptSensitiveData(_ data: String) -> String {
        // Encrypt medication names, doctor info
    }
    
    static func anonymizeForAnalytics(_ data: Any) -> Any {
        // Remove PII before logging
    }
}
```

### Caregiver Access Control
```swift
// Core/Security/AccessControl.swift
@Observable
class AccessControl {
    func hasPermission(_ permission: Permission, for userId: String) -> Bool {
        // Check if current user has permission to access another user's data
    }
    
    func grantCaregiverAccess(caregiverEmail: String, permissions: [Permission]) async throws {
        // Generate QR code for caregiver invitation
        // Send secure invitation
    }
}
```

## 📊 Analytics & Monitoring

### Event Tracking Requirements
```swift
// Core/Analytics/AnalyticsManager.swift
@Observable
class AnalyticsManager {
    func trackMedicationAdded(viaVoice: Bool, medicationType: String) {
        // Firebase Analytics event
    }
    
    func trackConflictDetected(severity: ConflictSeverity, medicationCount: Int) {
        // Track conflict analysis usage
    }
    
    func trackVoiceInputUsage(success: Bool, inputType: String) {
        // Track voice feature adoption
    }
}
```

## 🚨 Critical Error Scenarios

### Must Handle These Errors
```swift
enum AppError: LocalizedError {
    // Network errors
    case networkUnavailable
    case firebaseConnectionFailed
    case syncTimeout
    
    // Voice input errors  
    case microphonePermissionDenied
    case speechRecognitionFailed
    case noSpeechDetected
    
    // Data errors
    case medicationNotFound
    case invalidDosageFormat
    case scheduleConflict
    
    // Authentication errors
    case userNotAuthenticated
    case caregiverAccessDenied
    case subscriptionExpired
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return AppStrings.ErrorMessages.networkError
        case .microphonePermissionDenied:
            return AppStrings.ErrorMessages.permissionDenied
        // Must use AppStrings for ALL user-facing errors
        }
    }
}
```

## 🎯 Phase 2 Success Criteria

### Must Be Complete Before Phase 3
- ✅ All data models compile and work with Firebase/Core Data
- ✅ Tab navigation with authentication gate
- ✅ Voice input infrastructure ready
- ✅ Offline/online sync foundation
- ✅ Basic CRUD operations for medications
- ✅ Error handling with user-friendly messages
- ✅ Caregiver access control framework
- ✅ Analytics event tracking setup

### Performance Benchmarks
- ✅ App launches in <3 seconds
- ✅ Tab switching <500ms
- ✅ Voice input response <2 seconds
- ✅ Medication list loads <1 second for 50+ items
- ✅ Offline mode works completely

## 🔮 Phase 3 Preview (What Comes Next)
- Medgemma AI integration for conflict detection
- Advanced voice processing with medical terminology
- Caregiver QR code sharing system
- Push notification scheduling
- Advanced medication scheduling

