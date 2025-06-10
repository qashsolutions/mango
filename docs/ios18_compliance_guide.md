# iOS 18 Compliance & App Store Standards Guide

## 1. iOS 18 Coding Standards Compliance

### SwiftUI Best Practices (iOS 18)
```swift
// ✅ CORRECT: iOS 18 Modern SwiftUI
struct MedicationCardView: View {
    @State private var medication: Medication
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Use proper view builders
        }
        .containerRelativeFrame(.horizontal, count: 2, spacing: AppTheme.Spacing.small)
        .background(AppTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        // iOS 18 specific modifiers
        .sensoryFeedback(.impact(weight: .light), trigger: medication.isSelected)
        .hoverEffect(.highlight)
    }
}

// ❌ AVOID: Hardcoded values
struct BadExample: View {
    var body: some View {
        VStack(spacing: 16) { // ❌ Hardcoded spacing
            Text("Medication")
                .font(.system(size: 18)) // ❌ Hardcoded font size
                .foregroundColor(.blue) // ❌ Hardcoded color
        }
        .background(Color(red: 0.2, green: 0.3, blue: 0.4)) // ❌ Hardcoded color values
    }
}
```

### iOS 18 Modern Navigation
```swift
// ✅ CORRECT: iOS 18 Navigation
struct ContentView: View {
    @State private var selectedTab: TabType = .myHealth
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MyHealthView()
                .tabItem {
                    Label(AppStrings.TabTitles.myHealth, systemImage: AppIcons.health)
                }
                .tag(TabType.myHealth)
            
            GroupsView()
                .tabItem {
                    Label(AppStrings.TabTitles.groups, systemImage: AppIcons.groups)
                }
                .tag(TabType.groups)
        }
        .tabViewStyle(.sidebarAdaptable) // iOS 18 adaptive style
    }
}

// Tab type enumeration
enum TabType: String, CaseIterable {
    case myHealth = "myHealth"
    case groups = "groups"
    case doctorList = "doctorList"
    case conflicts = "conflicts"
}
```

### iOS 18 Data Flow Patterns
```swift
// ✅ CORRECT: iOS 18 Observable Pattern
@Observable
class MedicationStore {
    var medications: [Medication] = []
    var isLoading = false
    var errorMessage: String?
    
    @MainActor
    func loadMedications() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            medications = try await FirebaseManager.shared.fetchMedications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// ✅ CORRECT: Modern SwiftUI View
struct MedicationsView: View {
    @State private var store = MedicationStore()
    
    var body: some View {
        NavigationStack {
            List(store.medications) { medication in
                MedicationRowView(medication: medication)
            }
            .refreshable {
                await store.loadMedications()
            }
            .overlay {
                if store.medications.isEmpty {
                    ContentUnavailableView(
                        AppStrings.EmptyStates.noMedications,
                        systemImage: AppIcons.medicationEmpty,
                        description: Text(AppStrings.EmptyStates.addFirstMedication)
                    )
                }
            }
        }
    }
}
```

## 2. Configuration Management (Zero Hardcoding)

### AppTheme.swift - Global Design System
```swift
import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color("PrimaryColor")
        static let primaryVariant = Color("PrimaryVariantColor")
        static let secondary = Color("SecondaryColor")
        
        // Background Colors
        static let background = Color("BackgroundColor")
        static let surface = Color("SurfaceColor")
        static let cardBackground = Color("CardBackgroundColor")
        
        // Text Colors
        static let onPrimary = Color("OnPrimaryColor")
        static let onSecondary = Color("OnSecondaryColor")
        static let onBackground = Color("OnBackgroundColor")
        static let onSurface = Color("OnSurfaceColor")
        
        // Semantic Colors
        static let success = Color("SuccessColor")
        static let warning = Color("WarningColor")
        static let error = Color("ErrorColor")
        static let info = Color("InfoColor")
        
        // Medication Conflict Severity
        static let conflictLow = Color("ConflictLowColor")
        static let conflictMedium = Color("ConflictMediumColor")
        static let conflictHigh = Color("ConflictHighColor")
        static let conflictCritical = Color("ConflictCriticalColor")
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.custom("SF-Pro-Display-Bold", size: 34, relativeTo: .largeTitle)
        static let title1 = Font.custom("SF-Pro-Display-Bold", size: 28, relativeTo: .title)
        static let title2 = Font.custom("SF-Pro-Display-Bold", size: 22, relativeTo: .title2)
        static let title3 = Font.custom("SF-Pro-Display-Semibold", size: 20, relativeTo: .title3)
        static let headline = Font.custom("SF-Pro-Display-Semibold", size: 17, relativeTo: .headline)
        static let body = Font.custom("SF-Pro-Text-Regular", size: 17, relativeTo: .body)
        static let callout = Font.custom("SF-Pro-Text-Regular", size: 16, relativeTo: .callout)
        static let subheadline = Font.custom("SF-Pro-Text-Regular", size: 15, relativeTo: .subheadline)
        static let footnote = Font.custom("SF-Pro-Text-Regular", size: 13, relativeTo: .footnote)
        static let caption1 = Font.custom("SF-Pro-Text-Regular", size: 12, relativeTo: .caption)
        static let caption2 = Font.custom("SF-Pro-Text-Regular", size: 11, relativeTo: .caption2)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
    
    // MARK: - Layout
    struct Layout {
        static let minimumTouchTarget: CGFloat = 44
        static let cardMinHeight: CGFloat = 60
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 44
        static let navigationBarHeight: CGFloat = 44
        static let tabBarHeight: CGFloat = 83
    }
}
```

### AppStrings.swift - Localization Ready
```swift
import Foundation

struct AppStrings {
    // MARK: - Tab Titles
    struct TabTitles {
        static let myHealth = NSLocalizedString("tab.myHealth", value: "MyHealth", comment: "MyHealth tab title")
        static let groups = NSLocalizedString("tab.groups", value: "Groups", comment: "Groups tab title")
        static let doctorList = NSLocalizedString("tab.doctorList", value: "Doctors", comment: "Doctor list tab title")
        static let conflicts = NSLocalizedString("tab.conflicts", value: "Conflicts", comment: "Conflicts tab title")
    }
    
    // MARK: - Authentication
    struct Authentication {
        static let signIn = NSLocalizedString("auth.signIn", value: "Sign In", comment: "Sign in button")
        static let signUp = NSLocalizedString("auth.signUp", value: "Sign Up", comment: "Sign up button")
        static let signOut = NSLocalizedString("auth.signOut", value: "Sign Out", comment: "Sign out button")
        static let forgotPassword = NSLocalizedString("auth.forgotPassword", value: "Forgot Password?", comment: "Forgot password link")
        static let welcomeMessage = NSLocalizedString("auth.welcome", value: "Welcome to Medication Manager", comment: "Welcome message")
    }
    
    // MARK: - Medications
    struct Medications {
        static let title = NSLocalizedString("medications.title", value: "Medications", comment: "Medications section title")
        static let addMedication = NSLocalizedString("medications.add", value: "Add Medication", comment: "Add medication button")
        static let dosage = NSLocalizedString("medications.dosage", value: "Dosage", comment: "Dosage label")
        static let frequency = NSLocalizedString("medications.frequency", value: "Frequency", comment: "Frequency label")
        static let schedule = NSLocalizedString("medications.schedule", value: "Schedule", comment: "Schedule label")
        static let notes = NSLocalizedString("medications.notes", value: "Notes", comment: "Notes label")
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let genericError = NSLocalizedString("error.generic", value: "Something went wrong. Please try again.", comment: "Generic error message")
        static let networkError = NSLocalizedString("error.network", value: "Network connection error. Please check your internet connection.", comment: "Network error message")
        static let authenticationError = NSLocalizedString("error.authentication", value: "Authentication failed. Please sign in again.", comment: "Authentication error")
        static let permissionDenied = NSLocalizedString("error.permission", value: "Permission denied. Please enable in Settings.", comment: "Permission denied error")
    }
    
    // MARK: - Empty States
    struct EmptyStates {
        static let noMedications = NSLocalizedString("empty.medications", value: "No Medications", comment: "No medications empty state title")
        static let addFirstMedication = NSLocalizedString("empty.addFirst", value: "Add your first medication to get started", comment: "Add first medication description")
        static let noDoctors = NSLocalizedString("empty.doctors", value: "No Doctors Added", comment: "No doctors empty state")
        static let noConflicts = NSLocalizedString("empty.conflicts", value: "No Conflicts Found", comment: "No conflicts empty state")
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static let medicationCard = NSLocalizedString("accessibility.medicationCard", value: "Medication card", comment: "Medication card accessibility label")
        static let addButton = NSLocalizedString("accessibility.addButton", value: "Add new item", comment: "Add button accessibility label")
        static let voiceInputButton = NSLocalizedString("accessibility.voiceInput", value: "Voice input", comment: "Voice input button accessibility label")
    }
}
```

### AppIcons.swift - System Icons Only
```swift
import SwiftUI

struct AppIcons {
    // MARK: - Tab Bar Icons
    static let health = "heart.fill"
    static let groups = "person.3.fill"
    static let doctorList = "stethoscope"
    static let conflicts = "exclamationmark.triangle.fill"
    
    // MARK: - Action Icons
    static let add = "plus.circle.fill"
    static let edit = "pencil.circle.fill"
    static let delete = "trash.circle.fill"
    static let voice = "mic.circle.fill"
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease.circle"
    
    // MARK: - Status Icons
    static let success = "checkmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.circle.fill"
    static let info = "info.circle.fill"
    
    // MARK: - Medication Icons
    static let medication = "pills.fill"
    static let supplement = "leaf.fill"
    static let diet = "fork.knife"
    static let schedule = "clock.fill"
    
    // MARK: - Empty State Icons
    static let medicationEmpty = "pills"
    static let doctorEmpty = "stethoscope"
    static let groupEmpty = "person.3"
}
```

### Configuration.swift - Environment Management
```swift
import Foundation

enum Environment {
    case development
    case staging
    case production
    
    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

struct Configuration {
    // MARK: - Firebase
    struct Firebase {
        static var projectId: String {
            switch Environment.current {
            case .development:
                return "medication-manager-dev"
            case .staging:
                return "medication-manager-staging"
            case .production:
                return "medication-manager-prod"
            }
        }
        
        static var apiKey: String {
            guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let apiKey = plist["API_KEY"] as? String else {
                fatalError("Firebase API Key not found")
            }
            return apiKey
        }
    }
    
    // MARK: - Vertex AI
    struct VertexAI {
        static var endpoint: String {
            return "https://us-central1-aiplatform.googleapis.com"
        }
        
        static var modelName: String {
            return "medgemma-27b"
        }
        
        static var projectId: String {
            switch Environment.current {
            case .development:
                return "medication-manager-ai-dev"
            case .staging:
                return "medication-manager-ai-staging"
            case .production:
                return "medication-manager-ai-prod"
            }
        }
    }
    
    // MARK: - Subscription
    struct Subscription {
        static let monthlyProductId = "com.medicationmanager.monthly"
        static let annualProductId = "com.medicationmanager.annual"
        static let trialDurationDays = 7
    }
    
    // MARK: - App Settings
    struct App {
        static let maxCaregivers = 3
        static let maxFamilyMembers = 2
        static let notificationsPerDay = 3
        static let conflictCacheExpiryHours = 24
    }
}
```

## 3. App Store Compliance Requirements

### Privacy Policy Requirements
```swift
// Privacy.swift - Privacy Compliance Helper
struct PrivacyCompliance {
    // MARK: - Data Collection Disclosure
    static let dataCollectionTypes: [String] = [
        "Health and Fitness Data",
        "Contact Information", 
        "User Content",
        "Usage Data",
        "Diagnostics"
    ]
    
    // MARK: - Third Party Services
    static let thirdPartyServices: [String] = [
        "Firebase Analytics",
        "Firebase Crashlytics",
        "Google Vertex AI",
        "Stripe Payment Processing"
    ]
    
    // MARK: - Privacy Settings
    static func configurePrivacySettings() {
        // Implement privacy controls
    }
}
```

### App Store Metadata Compliance
```swift
// AppStoreMetadata.swift
struct AppStoreMetadata {
    static let appName = "Medication Manager"
    static let appDescription = """
    Educational medication tracking app with drug interaction information. 
    For informational purposes only - not a substitute for professional medical advice.
    """
    
    static let keywords = [
        "medication",
        "health",
        "tracking",
        "education",
        "drug interactions"
    ]
    
    static let ageRating = "17+" // Due to medical content
    
    static let disclaimers = [
        "For educational purposes only",
        "Not a substitute for professional medical advice",
        "Consult healthcare providers for medical decisions"
    ]
}
```

### Content Guidelines Compliance
```swift
// ContentGuidelines.swift
struct ContentGuidelines {
    // MARK: - Medical Disclaimers
    static let primaryDisclaimer = """
    This app is for educational purposes only and is not intended to replace 
    professional medical advice, diagnosis, or treatment. Always seek the advice 
    of your physician or other qualified health provider with any questions you 
    may have regarding a medical condition.
    """
    
    static let conflictDisclaimer = """
    Drug interaction information is provided for educational purposes only. 
    This information may not include all possible interactions. Always consult 
    your healthcare provider before making any changes to your medications.
    """
    
    // MARK: - Age Restriction Compliance
    static let minimumAge = 17
    static let ageVerificationRequired = true
    
    // MARK: - Content Filtering
    static func filterMedicalContent(_ content: String) -> String {
        // Implement content filtering for medical information
        return content
    }
}
```

## 4. iOS 18 Accessibility Compliance

### AccessibilityHelper.swift
```swift
import SwiftUI

struct AccessibilityHelper {
    // MARK: - Voice Over Support
    static func configureVoiceOver(for view: some View, label: String, hint: String? = nil) -> some View {
        view
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Dynamic Type Support
    static func scaledFont(_ font: Font, maxSize: CGFloat = 28) -> Font {
        font.monospacedDigit()
    }
    
    // MARK: - Color Contrast
    static func ensureContrast(foreground: Color, background: Color) -> Color {
        // Implement contrast checking logic
        return foreground
    }
    
    // MARK: - Reduced Motion Support
    @ViewBuilder
    static func conditionalAnimation<T: View>(
        @ViewBuilder content: @escaping () -> T,
        animation: Animation
    ) -> some View {
        if AccessibilityHelper.isReduceMotionEnabled {
            content()
        } else {
            content()
                .animation(animation, value: UUID())
        }
    }
    
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}
```

## 5. Quality Assurance Checklist

### PreSubmissionChecklist.swift
```swift
// PreSubmissionChecklist.swift
struct PreSubmissionChecklist {
    // MARK: - App Store Requirements
    static let requirements = [
        "All text is localized and supports Dynamic Type",
        "App supports all iPhone screen sizes from iPhone SE to iPhone 15 Pro Max",
        "Dark mode is fully supported",
        "VoiceOver navigation works correctly",
        "High contrast mode is supported", 
        "Privacy policy is linked and accessible",
        "Medical disclaimers are prominently displayed",
        "Age rating is set to 17+ due to medical content",
        "No hardcoded strings or values",
        "All colors use semantic naming",
        "Subscription terms are clearly stated",
        "Free trial period is properly implemented",
        "App handles network connectivity issues gracefully",
        "Error messages are user-friendly and actionable",
        "Loading states are implemented for all async operations"
    ]
    
    // MARK: - iOS 18 Specific Requirements
    static let iOS18Requirements = [
        "Uses @Observable instead of ObservableObject where appropriate",
        "Implements modern SwiftUI navigation with NavigationStack",
        "Uses ContentUnavailableView for empty states",
        "Implements sensory feedback where appropriate",
        "Uses containerRelativeFrame for responsive layouts",
        "Supports Live Activities if applicable",
        "Integrates with Siri Shortcuts properly",
        "Uses modern async/await patterns consistently"
    ]
}
```

## 6. Code Review Guidelines

### CodeReviewGuidelines.swift
```swift
// CodeReviewGuidelines.swift
struct CodeReviewGuidelines {
    // ✅ ALWAYS CHECK
    static let checklist = [
        "No hardcoded strings - use AppStrings",
        "No hardcoded colors - use AppTheme.Colors", 
        "No hardcoded spacing - use AppTheme.Spacing",
        "No hardcoded fonts - use AppTheme.Typography",
        "All async functions use proper error handling",
        "All UI updates happen on @MainActor",
        "Memory leaks prevented with weak references",
        "Accessibility labels are meaningful",
        "Loading and error states are handled",
        "Network requests have timeout handling"
    ]
    
    // ❌ NEVER ALLOW
    static let forbidden = [
        "Magic numbers or strings",
        "Force unwrapping (!) except in controlled scenarios",
        "Hardcoded API endpoints",
        "Missing error handling for async operations",
        "UI updates off main thread",
        "Missing accessibility support",
        "Non-localized user-facing strings"
    ]
}
```

This comprehensive guide ensures iOS 18 compliance, App Store approval, and zero hardcoding while maintaining modern Swift standards.