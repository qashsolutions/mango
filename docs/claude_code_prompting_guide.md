# Claude Code Prompting Guide - Minimize Coding Mistakes

## 1. Essential Prompting Principles for Claude Code

### 🎯 **Primary Directive for Claude Code**
```
You are building an iOS 18 SwiftUI medication management app. You MUST:

1. NEVER hardcode any values - use Configuration files only
2. Follow iOS 18 modern patterns with @Observable, NavigationStack, async/await
3. Implement comprehensive error handling for ALL async operations
4. Use @MainActor for ALL UI updates
5. Support full accessibility and Dynamic Type
6. Use only AppTheme, AppStrings, AppIcons, and Configuration constants
7. Implement proper memory management with weak references
8. Test each component thoroughly before moving to the next
9. Use Firebase + Core Data hybrid architecture as documented
10. Follow App Store compliance guidelines strictly

CRITICAL: If you encounter ANY error, STOP and ask for clarification rather than guessing.
```

### 📋 **Step-by-Step Implementation Order**
```
Phase 1 (Foundation):
1. Create Configuration, AppTheme, AppStrings, AppIcons files first
2. Set up Firebase configuration with proper error handling
3. Implement basic authentication with GoogleSignIn
4. Create core data models with proper Codable conformance
5. Test authentication flow completely before proceeding

Phase 2 (Core Features):
6. Build MyHealth tab with medications sub-tab only
7. Implement voice input with proper permissions and error handling
8. Add Core Data local storage with offline capability
9. Test medication entry and storage thoroughly
10. Add supplements and diet tabs using same pattern

Phase 3 (Advanced Features):
11. Implement Medgemma AI integration with proper API error handling
12. Build Groups tab with caregiver QR code functionality
13. Add Doctor List with contact integration
14. Implement notification system
15. Add subscription and payment processing

Phase 4 (Polish):
16. Implement Live Activities and Siri Shortcuts
17. Add comprehensive accessibility features
18. Performance optimization and testing
19. App Store submission preparation
```

## 2. Specific Technical Instructions

### 🏗️ **Architecture Implementation Commands**

#### Authentication Setup
```
Implement Firebase Authentication using these exact specifications:

1. Use FirebaseManager.swift singleton pattern with @MainActor
2. Implement GoogleSignInManager with proper error handling
3. Create User model matching the Firestore schema in claude.md
4. Use @Observable pattern for authentication state
5. Handle all authentication errors with AppError enum
6. Never hardcode Firebase configuration - use Configuration.swift
7. Implement proper sign-out with session cleanup
8. Test with invalid credentials and network failures

Required error handling patterns:
- Network connectivity issues
- Invalid credentials
- User not found scenarios
- Firebase service unavailable
- Token expiration and refresh
```

#### Data Layer Implementation
```
Implement the hybrid data storage exactly as specified:

Firebase Firestore (Primary):
- Use collection structure from claude.md documentation
- Implement proper security rules for user data isolation
- Handle offline/online state transitions
- Use proper Firestore pagination for large datasets
- Implement real-time listeners for caregiver data sharing

Core Data (Local Cache):
- Create data models matching Firebase schema
- Implement automatic sync when network available
- Handle data conflicts with last-write-wins strategy
- Enable iCloud sync as user preference
- Proper data migration handling

CRITICAL: Test offline functionality completely before proceeding.
```

#### UI Implementation Standards
```
For EVERY SwiftUI view, implement these requirements:

1. Use ONLY AppTheme constants - no hardcoded values
2. Support Dynamic Type with minimum and maximum scaling
3. Implement proper loading and error states
4. Add meaningful accessibility labels and hints
5. Use NavigationStack instead of NavigationView
6. Implement pull-to-refresh where appropriate
7. Handle empty states with ContentUnavailableView
8. Use sensory feedback for user interactions
9. Support both portrait and landscape orientations
10. Test with VoiceOver enabled

Example structure for every view:
```swift
struct ExampleView: View {
    @State private var viewModel = ExampleViewModel()
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        NavigationStack {
            // Main content with proper error handling
        }
        .navigationTitle(AppStrings.Example.title)
        .refreshable { await viewModel.refresh() }
        .overlay {
            if viewModel.items.isEmpty {
                ContentUnavailableView(...)
            }
        }
    }
}
```

#### Voice Input Implementation
```
Implement speech recognition with these exact requirements:

1. Request microphone and speech recognition permissions on first use
2. Handle permission denied gracefully with Settings redirect
3. Implement proper audio session management
4. Use SFSpeechRecognizer with offline capability when available
5. Provide real-time feedback during voice input
6. Implement confirmation screen for voice-to-text results
7. Handle background app interruptions properly
8. Support medical terminology with custom vocabulary
9. Implement noise cancellation if available
10. Test with various accents and speaking speeds

Error handling requirements:
- Microphone not available
- Speech recognition service unavailable
- Audio session conflicts
- Recognition timeout scenarios
- Background app interruption
```

## 3. Error Prevention Strategies

### 🚫 **Common Mistakes to Avoid**

#### Memory Management Issues
```
ALWAYS prevent these memory leaks:

❌ Strong reference cycles in closures:
someAsyncCall { result in
    self.handleResult(result) // WRONG - creates retain cycle
}

✅ Use weak references:
someAsyncCall { [weak self] result in
    self?.handleResult(result) // CORRECT
}

❌ Not canceling async operations:
Task {
    await longRunningOperation()
}

✅ Store and cancel tasks:
@State private var loadingTask: Task<Void, Never>?

loadingTask = Task {
    await longRunningOperation()
}
// Cancel in deinit or when view disappears
```

#### Async/Await Best Practices
```
ALWAYS implement proper async patterns:

❌ Missing error handling:
func loadData() async {
    let data = try await fetchData() // WRONG - unhandled error
}

✅ Comprehensive error handling:
func loadData() async {
    do {
        let data = try await fetchData()
        await MainActor.run {
            self.data = data
            self.isLoading = false
        }
    } catch {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
```

#### SwiftUI State Management
```
ALWAYS follow proper state patterns:

❌ Direct state mutations:
Button("Update") {
    someAsyncOperation { result in
        self.items = result // WRONG - off main thread
    }
}

✅ Proper state updates:
Button("Update") {
    Task {
        let result = await someAsyncOperation()
        await MainActor.run {
            self.items = result // CORRECT - on main thread
        }
    }
}
```

## 4. Testing & Validation Commands

### 🧪 **Required Testing for Each Feature**

#### Before Implementing Each Feature
```
MANDATORY testing checklist for every feature:

1. Create unit tests for all business logic
2. Test error scenarios (network failures, invalid data)
3. Test with VoiceOver enabled
4. Test with Dynamic Type at largest size
5. Test in both light and dark modes
6. Test on iPhone SE (smallest screen)
7. Test on iPhone 15 Pro Max (largest screen)
8. Test with poor network connectivity
9. Test offline functionality
10. Test memory usage with Instruments

Do NOT proceed to next feature until ALL tests pass.
```

#### Voice Input Testing Protocol
```
Test voice input with these scenarios:

1. Clear speech in quiet environment
2. Background noise conditions
3. Medical terminology pronunciation
4. Different accents and speech patterns
5. Microphone permission denied
6. Audio session interruptions (phone calls)
7. Speech recognition service unavailable
8. Very long speech input (>60 seconds)
9. Multiple consecutive voice inputs
10. Voice input while app is in background

Record test results and handle all failure cases gracefully.
```

## 5. Incremental Development Strategy

### 📈 **Build and Validate Approach**

#### Single Feature Development Cycle
```
For EACH feature, follow this exact cycle:

1. Plan: Review requirements and design patterns
2. Implement: Build minimal viable version
3. Test: Comprehensive testing as outlined above
4. Validate: Ensure no hardcoding and proper error handling
5. Document: Update comments and documentation
6. Review: Check against iOS 18 and App Store guidelines
7. Commit: Save working version before proceeding

NEVER work on multiple features simultaneously.
NEVER proceed if ANY tests fail.
NEVER skip error handling implementation.
```

#### Integration Testing Protocol
```
After completing each major feature:

1. Full app smoke testing
2. Integration testing with other features
3. Performance testing with realistic data
4. Memory leak detection
5. Network failure simulation
6. Device storage full scenarios
7. iOS permission revocation testing
8. Background/foreground app transitions
9. Device rotation and multitasking
10. Low battery mode behavior testing
```

## 6. Quality Gates & Checkpoints

### ✅ **Required Quality Gates**

#### Code Quality Gate
```
Before marking any feature complete:

✅ No compiler warnings
✅ No force unwrapping except documented exceptions
✅ All strings localized using AppStrings
✅ All colors from AppTheme
✅ All spacing from AppTheme
✅ Comprehensive error handling
✅ Accessibility labels implemented
✅ Loading states implemented
✅ Memory leak testing passed
✅ Unit tests written and passing
```

#### App Store Readiness Gate
```
Before any App Store submission:

✅ Privacy policy linked and accessible
✅ Medical disclaimers prominently displayed
✅ Age rating appropriate (17+)
✅ Subscription terms clearly stated
✅ All required app metadata completed
✅ Screenshots and app preview created
✅ TestFlight beta testing completed
✅ App Store review guidelines compliance verified
✅ COPPA compliance if applicable
✅ International accessibility standards met
```

## 7. Emergency Protocols

### 🚨 **When Things Go Wrong**

#### If Claude Code Gets Stuck or Errors
```
IMMEDIATE ACTIONS:

1. STOP all development
2. Document the exact error and context
3. Revert to last known working state
4. Review the specific section in claude.md
5. Check against iOS 18 compliance guide
6. Verify no hardcoding was introduced
7. Test the basic functionality before proceeding
8. Ask specific questions about the blocking issue

DO NOT attempt to fix by guessing.
DO NOT bypass error handling to make code work.
DO NOT introduce hardcoding as a quick fix.
```

#### Code Review Recovery Protocol
```
If code review reveals issues:

1. Immediately stop new development
2. Create comprehensive issue list
3. Prioritize issues by severity (crashes > performance > style)
4. Fix issues one at a time with testing
5. Verify each fix doesn't break other functionality
6. Update documentation if patterns changed
7. Add additional tests to prevent regression
8. Continue only after ALL issues resolved
```

## 8. Final Validation Prompts

### 🎯 **Pre-Submission Final Check**

```
Execute this final validation before ANY deployment:

1. Run complete test suite - ALL must pass
2. Test on physical device, not just simulator
3. Verify offline functionality works completely
4. Test voice input with medical terminology
5. Verify caregiver access works with QR codes
6. Test subscription flow end-to-end
7. Verify all error scenarios show proper messages
8. Test accessibility with VoiceOver
9. Verify App Store metadata accuracy
10. Confirm privacy policy compliance

CRITICAL: Any failure requires immediate fix before proceeding.
```

## Summary: Keys to Claude Code Success

### 🔑 **Success Formula**
1. **Always start with configuration files** - never hardcode anything
2. **Build incrementally** - one feature at a time with full testing
3. **Use @MainActor consistently** - prevent threading issues
4. **Implement error handling first** - not as an afterthought
5. **Test offline scenarios early** - don't assume connectivity
6. **Follow iOS 18 patterns strictly** - use modern SwiftUI approaches
7. **Validate accessibility continuously** - not just at the end
8. **Document decisions and patterns** - maintain consistency
9. **Ask questions when uncertain** - don't guess or assume
10. **Test on real devices** - simulators miss real-world issues

Following this guide will minimize coding mistakes and ensure a high-quality, App Store-ready application that meets all iOS 18 standards and compliance requirements.