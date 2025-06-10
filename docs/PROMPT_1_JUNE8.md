# Claude Code - Medication Management App Development Brief

## 🎯 PROJECT OVERVIEW

You are building **Mango Health**, an iOS-only medication management app with AI-powered conflict detection, caregiver access, and voice-first interface. This is a production-ready app targeting the App Store.

### Key Requirements:
- **iOS 18 only** - iPhone only (no iPad/Mac)
- **SwiftUI + Modern Patterns** - NavigationStack, @Observable, async/await
- **Zero Hardcoding** - Use only configuration files
- **Voice-First Interface** - Apple Intelligence integration
- **Firebase + Core Data Hybrid** - Cloud sync + local storage
- **HIPAA-Free Consumer App** - Educational disclaimers only

## ✅ WHAT'S ALREADY COMPLETED

### 1. Project Setup (100% Complete)
- ✅ **Xcode Project**: "MedicationManager" with correct bundle ID `com.medicationmanager.MedicationManager`
- ✅ **Display Name**: "Mango Health" (what users see)
- ✅ **App Category**: Healthcare & Fitness
- ✅ **iOS Deployment Target**: 18.5
- ✅ **iPhone Only**: No iPad/Mac support
- ✅ **Core Data**: Enabled for local caching

### 2. Firebase Setup (100% Complete)
- ✅ **Firebase Project**: "medication-manager-dev" created and configured
- ✅ **Bundle ID**: `com.medicationmanager.MedicationManager` registered
- ✅ **GoogleService-Info.plist**: Downloaded and added to Resources/ folder in Xcode
- ✅ **Google Sign-In**: Enabled in Firebase Console Authentication
- ✅ **Target Membership**: GoogleService-Info.plist properly added to MedicationManager target

### 3. Folder Structure (100% Complete)
```
MedicationManager/
├── App/
│   ├── ContentView.swift (placeholder - REPLACE THIS)
│   └── MedicationManagerApp.swift (basic - ENHANCE THIS)
├── Core/
│   ├── Configuration/
│   │   ├── ✅ AppTheme.swift (COMPLETE - colors, spacing, typography)
│   │   ├── ✅ AppStrings.swift (COMPLETE - localized strings)
│   │   ├── ✅ AppIcons.swift (COMPLETE - SF Symbols)
│   │   └── ✅ Configuration.swift (COMPLETE - environment settings)
│   ├── Models/ (EMPTY - you will create data models here)
│   ├── Networking/ (EMPTY - you will create API clients here)
│   └── Utilities/ (contains Persistence.swift - Core Data)
├── Features/ (EMPTY - you will create feature modules here)
│   ├── Authentication/
│   ├── MyHealth/
│   ├── Groups/
│   ├── DoctorList/
│   └── Conflicts/
└── Resources/
    ├── Configuration/
    └── Localization/
```

### 4. Configuration Files (100% Complete - USE THESE)
- ✅ **AppTheme.swift**: Colors, typography, spacing, animations, layout constants
- ✅ **AppStrings.swift**: All localized strings (includes "Mango Health" branding)
- ✅ **AppIcons.swift**: SF Symbols for all UI elements
- ✅ **Configuration.swift**: Environment-specific settings (dev/staging/prod)

### 5. Current Build Status
- ✅ **Build Status**: SUCCESS - No compilation errors
- ✅ **Dependencies**: Ready for Firebase packages
- ✅ **Target Membership**: All files properly configured
- ✅ **Code Quality**: Zero hardcoded values, iOS 18 patterns

## 🚀 NEXT DEVELOPMENT PHASES

### PHASE 1: Authentication System (START HERE - READY TO IMPLEMENT)
**Priority: IMMEDIATE** - Firebase is configured and ready

#### Dependencies to Add:
❗️**IMPORTANT**: Add Firebase dependencies to Xcode BEFORE starting development

```swift
// Add these Package Dependencies to Xcode:
// File → Add Package Dependencies
// Firebase iOS SDK: https://github.com/firebase/firebase-ios-sdk
// Select: FirebaseAuth, FirebaseFirestore, FirebaseAnalytics, FirebaseCrashlytics

// Google Sign-In: https://github.com/google/GoogleSignIn-iOS
// Select: GoogleSignIn
```

#### Files to Create:
1. **Core/Networking/FirebaseManager.swift** - Firebase setup and authentication
2. **Core/Models/User.swift** - User data model
3. **Features/Authentication/LoginView.swift** - Login interface
4. **Features/Authentication/AuthenticationViewModel.swift** - Auth logic

#### Dependencies to Add:
```swift
// Add these Package Dependencies to Xcode FIRST:
// Firebase iOS SDK: https://github.com/firebase/firebase-ios-sdk
// - FirebaseAuth
// - FirebaseFirestore  
// - FirebaseAnalytics
// - FirebaseCrashlytics

// Google Sign-In: https://github.com/google/GoogleSignIn-iOS
```

#### What to Build:
- Google Sign-In integration using Firebase Auth
- User session management with @Observable pattern
- Secure token handling and refresh
- Error handling with AppError enum
- Update MedicationManagerApp.swift with auth environment

#### Success Criteria:
- Users can sign in with Google
- Authentication state persists across app launches
- Proper error handling for network failures
- Uses AppTheme for all styling (NO hardcoding)

### PHASE 2: Core App Structure 
**Priority: After Auth Complete**

#### Replace ContentView.swift:
- TabView with 4 tabs: MyHealth, Groups, DoctorList, Conflicts
- Bottom navigation using AppIcons
- Tab titles using AppStrings
- Navigation state management

#### Files to Create:
- Features/MyHealth/MyHealthView.swift
- Features/Groups/GroupsView.swift  
- Features/DoctorList/DoctorListView.swift
- Features/Conflicts/ConflictsView.swift

### PHASE 3: MyHealth Feature (Medications, Supplements, Diet)
**Priority: Core feature**

#### Voice-First Interface:
- Apple Speech framework integration
- Voice-to-text for medication entry
- Smart autocomplete for drug names
- Confirmation screens for voice input

#### Data Management:
- Firebase Firestore for cloud storage
- Core Data for local caching
- Offline/online sync
- CRUD operations for medications

### PHASE 4: Advanced Features
- Medgemma 27B AI integration (Vertex AI)
- Caregiver QR code sharing
- Push notifications (3x daily)
- Doctor contact integration

## 🔧 CRITICAL IMPLEMENTATION RULES

### 1. ABSOLUTELY NO HARDCODING
```swift
// ❌ WRONG:
Text("Add Medication").font(.system(size: 18)).foregroundColor(.blue)

// ✅ CORRECT:
Text(AppStrings.Medications.addMedication)
    .font(AppTheme.Typography.headline)
    .foregroundColor(AppTheme.Colors.primary)
```

### 2. Always Use Modern iOS 18 Patterns
```swift
// ✅ Use @Observable instead of ObservableObject
@Observable
class AuthenticationManager {
    var isAuthenticated = false
}

// ✅ Use NavigationStack instead of NavigationView
NavigationStack {
    // content
}

// ✅ Use async/await for all network calls
func signIn() async throws -> User {
    // implementation
}
```

### 3. MANDATORY Error Handling & User-Friendly Messages
```swift
// ✅ Always implement comprehensive error handling
do {
    let user = try await authManager.signIn()
    // handle success
} catch {
    // MUST use AppStrings for user-facing error messages
    // MUST be App Store compliant and user-friendly
    errorMessage = AppStrings.ErrorMessages.authenticationError
    
    // MUST include detailed logging for debugging
    Logger.error("Authentication failed", error: error, context: ["userId": user?.id])
}
```

### 4. MANDATORY Detailed Logging
```swift
// ✅ Log all important events for debugging
Logger.info("User sign-in attempt started")
Logger.debug("Firebase token refresh initiated", context: ["tokenExpiry": token.expiry])
Logger.error("Network request failed", error: error, context: ["endpoint": url, "statusCode": statusCode])

// ✅ Include context for easier debugging
Logger.warning("Slow network response", context: [
    "endpoint": endpoint,
    "responseTime": responseTime,
    "userConnection": networkType
])
```

### 5. App Store Compliance Requirements
```swift
// ✅ User-facing messages MUST be:
// - Clear and non-technical
// - Actionable when possible
// - Professional and helpful
// - Never expose internal errors

// ❌ WRONG:
"Firebase Auth error: invalid_token_exception_3847"

// ✅ CORRECT:
"Please sign in again to continue using Mango Health."

// ✅ Use AppStrings for all user messages
errorMessage = AppStrings.ErrorMessages.networkError
// "Network connection error. Please check your internet connection."
```

### 6. Use @MainActor for UI Updates
```swift
@MainActor
class ViewModel: Observable {
    // All UI-related properties and methods
}
```

## 📱 CURRENT APP STATE

### What Users See Now:
- Welcome screen with Mango Health branding
- "Get Started" button (not functional yet)
- Uses AppTheme styling throughout
- Modern iOS 18 design

### What You'll Build Next:
- Replace welcome screen with authentication flow
- Add Google Sign-In capability
- Set up user session management
- Create foundation for main app features

## 🎯 IMMEDIATE NEXT STEPS

1. **Add Firebase Dependencies** to Xcode project
2. **Create GoogleService-Info.plist** (Firebase console)
3. **Start with FirebaseManager.swift** in Core/Networking/
4. **Build authentication system** step by step
5. **Test thoroughly** before moving to next feature

## 📋 QUALITY CHECKLIST

Before marking any feature complete:
- ✅ No hardcoded strings (use AppStrings)
- ✅ No hardcoded colors (use AppTheme.Colors)
- ✅ No hardcoded spacing (use AppTheme.Spacing)
- ✅ Comprehensive error handling for all async operations
- ✅ User-friendly error messages that comply with App Store guidelines
- ✅ Detailed logging for all important events and errors
- ✅ @MainActor for all UI updates
- ✅ Builds without warnings
- ✅ Follows iOS 18 patterns consistently
- ✅ All user-facing text uses AppStrings localization
- ✅ Professional, helpful error messages (never technical jargon)

## 🚨 IMPORTANT NOTES

### Firebase Setup Required:
- Create Firebase project for "medication-manager-dev"
- Enable Google Sign-In authentication
- Download GoogleService-Info.plist
- Add to Xcode project Resources folder

### Bundle Identifier:
- Use: `com.medicationmanager.MedicationManager`
- This matches all documentation and configuration

### Testing Strategy:
- Build and test each feature completely before proceeding
- Use iPhone simulator for testing
- Test offline/online scenarios
- Verify voice input functionality

---

**START WITH PHASE 1: AUTHENTICATION SYSTEM**
**Focus on FirebaseManager.swift first, then build the authentication flow step by step.**