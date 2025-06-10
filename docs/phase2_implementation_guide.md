# Phase 2 Implementation Guide - Core App Structure

## 🎯 Phase 2 Objectives
Build the foundational architecture that supports all future features. This phase creates the data layer, navigation structure, and core UI components that everything else will build upon.

## 📋 Implementation Checklist

### Step 1: Core Data Models (Priority 1)
Create in this exact order to handle dependencies:

#### 1.1 Base Models
```swift
// Core/Models/User.swift - Create first
// Core/Models/AppError.swift - Error handling
// Core/Models/BaseModel.swift - Common protocols
```

#### 1.2 Health Data Models  
```swift
// Core/Models/Medication.swift
// Core/Models/Supplement.swift
// Core/Models/DietEntry.swift
```

#### 1.3 Social & Medical Models
```swift
// Core/Models/Doctor.swift
// Core/Models/CaregiverAccess.swift
// Core/Models/MedicationConflict.swift
```

### Step 2: Core Managers (Priority 1)
Essential services that handle data operations:

#### 2.1 Data Management
```swift
// Core/Networking/FirebaseManager.swift (already exists)
// Core/Networking/DataSyncManager.swift - Firebase + Core Data sync
// Core/Utilities/CoreDataManager.swift - Local persistence
```

#### 2.2 Feature Managers
```swift
// Core/Utilities/SpeechManager.swift - Voice input
// Core/Security/AccessControl.swift - Caregiver permissions  
// Core/Analytics/AnalyticsManager.swift - Event tracking
```

### Step 3: Navigation Architecture (Priority 2)
Replace ContentView with authenticated app structure:

#### 3.1 Main Navigation
```swift
// App/ContentView.swift - Replace with authentication gate
// Core/Navigation/NavigationManager.swift - State management
// Core/Navigation/TabType.swift - Tab definitions
```

#### 3.2 Authentication Integration
```swift
// Ensure tabs only show when authenticated
// Handle sign-out gracefully
// Persist authentication state
```

### Step 4: Core UI Components (Priority 2)
Reusable components used throughout the app:

#### 4.1 Input Components
```swift
// Core/UI/Components/VoiceInputButton.swift
// Core/UI/Components/VoiceEnabledTextField.swift
// Core/UI/Components/MedicationCard.swift
```

#### 4.2 Layout Components
```swift
// Core/UI/Components/EmptyStateView.swift
// Core/UI/Components/LoadingView.swift
// Core/UI/Components/ErrorView.swift
```

### Step 5: Feature Views (Priority 3)
Basic implementations of main screens:

#### 5.1 Tab Views (Placeholder Implementation)
```swift
// Features/MyHealth/MyHealthView.swift
// Features/Groups/GroupsView.swift
// Features/DoctorList/DoctorListView.swift
// Features/Conflicts/ConflictsView.swift
```

#### 5.2 MyHealth Sub-Views
```swift
// Features/MyHealth/MedicationsView.swift
// Features/MyHealth/SupplementsView.swift
// Features/MyHealth/DietView.swift
```

## 🔧 Critical Implementation Details

### Authentication Gate Pattern
```swift
// App/ContentView.swift
struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .transition(.slide)
            } else {
                AuthenticationView()
                    .transition(.slide)
            }
        }
        .animation(AppTheme.Animation.standard, value: authManager.isAuthenticated)
    }
}
```

### Tab Navigation Implementation
```swift
// Core/Navigation/MainTabView.swift
struct MainTabView: View {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            MyHealthView()
                .tabItem {
                    Label(AppStrings.TabTitles.myHealth, 
                          systemImage: AppIcons.health)
                }
                .tag(TabType.myHealth)
            
            GroupsView()
                .tabItem {
                    Label(AppStrings.TabTitles.groups, 
                          systemImage: AppIcons.groups)
                }
                .tag(TabType.groups)
            
            DoctorListView()
                .tabItem {
                    Label(AppStrings.TabTitles.doctorList, 
                          systemImage: AppIcons.doctorList)
                }
                .tag(TabType.doctorList)
            
            ConflictsView()
                .tabItem {
                    Label(AppStrings.TabTitles.conflicts, 
                          systemImage: AppIcons.conflicts)
                }
                .tag(TabType.conflicts)
        }
        .environmentObject(navigationManager)
    }
}
```

### Data Manager Pattern
```swift
// Core/Managers/MedicationManager.swift
@MainActor
@Observable
class MedicationManager {
    var medications: [Medication] = []
    var isLoading = false
    var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    func loadMedications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try Firebase first
            if firebaseManager.isOnline {
                medications = try await firebaseManager.fetchMedications()
                // Cache to Core Data
                try await coreDataManager.saveMedications(medications)
            } else {
                // Load from Core Data if offline
                medications = try await coreDataManager.fetchMedications()
            }
        } catch {
            errorMessage = AppStrings.ErrorMessages.genericError
            Logger.error("Failed to load medications", error: error)
        }
        
        isLoading = false
    }
    
    func addMedication(_ medication: Medication) async throws {
        // Add to Core Data immediately
        try await coreDataManager.saveMedication(medication)
        medications.append(medication)
        
        // Sync to Firebase when online
        if firebaseManager.isOnline {
            try await firebaseManager.saveMedication(medication)
        } else {
            // Mark for sync later
            try await coreDataManager.markForSync(medication)
        }
    }
}
```

### Voice Input Integration
```swift
// Core/UI/Components/VoiceEnabledTextField.swift
struct VoiceEnabledTextField: View {
    @Binding var text: String
    let placeholder: String
    let onVoiceInput: ((String) -> Void)?
    
    @StateObject private var speechManager = SpeechManager()
    @State private var showingVoiceInput = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .font(AppTheme.Typography.body)
            
            Button(action: { showingVoiceInput = true }) {
                Image(systemName: AppIcons.voice)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: AppTheme.Layout.minimumTouchTarget,
                           height: AppTheme.Layout.minimumTouchTarget)
            }
            .accessibility(label: Text(AppStrings.Accessibility.voiceInputButton))
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView(
                onTextCaptured: { capturedText in
                    text = capturedText
                    onVoiceInput?(capturedText)
                }
            )
        }
    }
}
```

## 🎨 UI Styling Requirements

### Consistent Card Design
```swift
// Core/UI/Styles/CardStyle.swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(
                color: AppTheme.Shadow.small.color,
                radius: AppTheme.Shadow.small.radius,
                x: AppTheme.Shadow.small.x,
                y: AppTheme.Shadow.small.y
            )
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}
```

### Empty State Design
```swift
// Core/UI/Components/EmptyStateView.swift
struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.secondary)
            
            Text(title)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.onBackground)
            
            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.large)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .frame(height: AppTheme.Layout.buttonHeight)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            }
        }
        .padding(AppTheme.Spacing.large)
    }
}
```

## 🚨 Critical Testing Points

### Must Test After Each Step
1. **Authentication Flow**: Sign in/out works correctly
2. **Tab Navigation**: All tabs accessible and display correctly
3. **Data Models**: CRUD operations work with Firebase and Core Data
4. **Voice Input**: Permission requests work, speech recognition functional
5. **Offline Mode**: App works without internet connection
6. **Error Handling**: User-friendly messages for all error scenarios

### Performance Benchmarks
- App launch: <3 seconds cold start
- Tab switching: <500ms response time
- Data loading: <2 seconds for 50+ items
- Voice input: <2 seconds response time

## 🔄 Phase 2 to Phase 3 Transition

### Phase 2 Completion Criteria
- ✅ All core data models implemented and tested
- ✅ Tab navigation with authentication gate working
- ✅ Basic CRUD operations for medications functional
- ✅ Voice input infrastructure ready
- ✅ Offline/online sync working
- ✅ Error handling comprehensive
- ✅ Core UI components reusable and consistent

### Handoff to Phase 3
Phase 2 provides the foundation for Phase 3 features:
- **Medgemma AI Integration**: Data models support conflict analysis
- **Advanced Voice Processing**: SpeechManager ready for medical terminology
- **Caregiver Features**: Access control framework in place
- **Notification System**: Data models support scheduling

## 📋 Phase 2 Claude Code Prompt

```
Phase 1 authentication is complete and working perfectly. Now implement Phase 2: Core App Structure.

Read the data-schema.md and phase2-implementation.md files completely.

Start with Step 1: Create all core data models in the exact order specified. Then build the core managers, navigation architecture, and finally the UI components.

Requirements:
- Use AppTheme, AppStrings, AppIcons, Configuration - NO hardcoding
- Implement comprehensive error handling with user-friendly messages
- Build offline-first with Firebase sync
- Include voice input infrastructure
- Follow iOS 18 modern patterns (@Observable, NavigationStack, async/await)
- Test each component as you build it

Focus on creating a solid foundation that Phase 3 can build upon. Build incrementally and confirm each step works before proceeding.
```