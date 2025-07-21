import Foundation
import SwiftUI
import Observation

/// Protocol for managers that need lifecycle management
/// All managers are @MainActor isolated, so this protocol must be too
@MainActor
protocol LifecycleManageable {
    /// Called when the manager should start its services
    func startup() async throws
    /// Called when the manager should stop its services and clean up resources
    func shutdown() async
}

/// Protocol defining the interface for all manager dependencies
protocol ManagerProtocol {
    associatedtype Manager
    static var shared: Manager { get }
}

/// Authentication manager protocol
/// Note: @MainActor because all implementations (FirebaseManager) are @MainActor isolated
@MainActor
protocol AuthenticationManagerProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    func signOut() async throws
}

/// Navigation manager protocol
/// Note: @MainActor because all implementations (NavigationManager) are @MainActor isolated
@MainActor
protocol NavigationManagerProtocol: AnyObject {
    var selectedTab: MainTab { get set }
    var presentedSheet: SheetDestination? { get set }
    var presentedFullScreenCover: FullScreenDestination? { get set }
    func navigate(to destination: NavigationDestination)
    func presentSheet(_ destination: SheetDestination)
    func presentFullScreenCover(_ destination: FullScreenDestination)
}

/// Data sync manager protocol
/// Note: @MainActor because all implementations (DataSyncManager) are @MainActor isolated
@MainActor
protocol DataSyncManagerProtocol: AnyObject {
    var isSyncing: Bool { get }
    var syncError: AppError? { get }
    var lastSyncDate: Date? { get }
    func syncPendingChanges() async throws
    func forceSyncAll() async throws
}

/// Analytics manager protocol
/// Note: @MainActor because all implementations (AnalyticsManager) are @MainActor isolated
@MainActor
protocol AnalyticsManagerProtocol: AnyObject {
    func trackEvent(_ name: String, parameters: [String: Any]?)
    func trackScreenViewed(_ screenName: String)
    func trackError(_ error: Error, context: String)
    func setUserProperty(_ value: String?, forName name: String)
}


/// Speech manager protocol
/// Note: @MainActor because all implementations (SpeechManager) are @MainActor isolated
@MainActor
protocol SpeechManagerProtocol: AnyObject {
    var isAuthorized: Bool { get }
    var isRecording: Bool { get }
    var recognizedText: String { get }
    func requestSpeechAuthorization() async
    func startRecording() async throws
    func stopRecording()
}

/// Main dependency injection container
/// Swift 6 compliant - No singleton, uses SwiftUI environment injection
@MainActor
final class DIContainer: ObservableObject {
    
    // MARK: - Manager Dependencies
    // Using lazy properties to defer initialization until first access
    
    lazy var authManager: AuthenticationManagerProtocol = {
        if let testManager = _authManager {
            return testManager
        }
        print("🟡 [DI] Lazily initializing FirebaseManager")
        let manager = FirebaseManager.shared
        trackLifecycleManager(manager)
        return manager
    }()
    
    lazy var navigationManager: NavigationManagerProtocol = {
        if let testManager = _navigationManager {
            return testManager
        }
        print("🟡 [DI] Lazily initializing NavigationManager")
        let manager = NavigationManager.shared
        trackLifecycleManager(manager)
        return manager
    }()
    
    lazy var dataSyncManager: DataSyncManagerProtocol = {
        if let testManager = _dataSyncManager {
            return testManager
        }
        print("🟡 [DI] Lazily initializing DataSyncManager")
        let manager = DataSyncManager.shared
        trackLifecycleManager(manager)
        return manager
    }()
    
    lazy var analyticsManager: AnalyticsManagerProtocol = {
        if let testManager = _analyticsManager {
            return testManager
        }
        print("🟡 [DI] Lazily initializing AnalyticsManager")
        let manager = AnalyticsManager.shared
        trackLifecycleManager(manager)
        return manager
    }()
    
    lazy var coreDataManager: CoreDataManagerProtocol = {
        if let testManager = _coreDataManager {
            return testManager
        }
        print("🟡 [DI] Lazily initializing CoreDataManager")
        let manager = CoreDataManager.shared
        trackLifecycleManager(manager)
        return manager
    }()
    
    lazy var speechManager: SpeechManagerProtocol = {
        if let testManager = _speechManager {
            return testManager
        }
        print("🟡 [DI] Lazily initializing SpeechManager")
        let manager = SpeechManager.shared
        trackLifecycleManager(manager)
        return manager
    }()
    
    let viewFactory: ViewFactoryProtocol
    
    // Track which managers support lifecycle management
    // Since all managers are @MainActor, this array is also @MainActor isolated
    private var lifecycleManagers: [LifecycleManageable] = []
    
    // MARK: - Initialization
    
    /// Public initializer for SwiftUI environment injection
    /// Swift 6 compliant - No singleton pattern, created once at app level
    init() {
        print("🟡 [DI] DIContainer.init() - START (Swift 6 Environment Pattern)")
        print("🟡 [DI] Thread: \(Thread.current), isMain: \(Thread.isMainThread)")
        
        // Only initialize lightweight dependencies immediately
        self.viewFactory = AppViewFactory()
        
        // Note: All heavy managers are now lazy and will be created on first access
        print("🟡 [DI] DIContainer.init() - COMPLETE (managers will be loaded lazily)")
    }
    
    /// Test initializer for dependency injection in tests
    init(
        authManager: AuthenticationManagerProtocol,
        navigationManager: NavigationManagerProtocol,
        dataSyncManager: DataSyncManagerProtocol,
        analyticsManager: AnalyticsManagerProtocol,
        coreDataManager: CoreDataManagerProtocol,
        speechManager: SpeechManagerProtocol,
        viewFactory: ViewFactoryProtocol
    ) {
        print("🟡 [DI] DIContainer.init(test) - Using injected dependencies")
        
        // For tests, we need to set the lazy properties directly
        // Create private storage properties for test injection
        self.viewFactory = viewFactory
        
        // Override lazy properties with test dependencies
        self._authManager = authManager
        self._navigationManager = navigationManager
        self._dataSyncManager = dataSyncManager
        self._analyticsManager = analyticsManager
        self._coreDataManager = coreDataManager
        self._speechManager = speechManager
    }
    
    // Private storage for test injection
    private var _authManager: AuthenticationManagerProtocol?
    private var _navigationManager: NavigationManagerProtocol?
    private var _dataSyncManager: DataSyncManagerProtocol?
    private var _analyticsManager: AnalyticsManagerProtocol?
    private var _coreDataManager: CoreDataManagerProtocol?
    private var _speechManager: SpeechManagerProtocol?
    
    // MARK: - Lifecycle Management
    
    /// Track a manager that supports lifecycle management
    private func trackLifecycleManager(_ manager: Any) {
        if let lifecycleManager = manager as? LifecycleManageable {
            lifecycleManagers.append(lifecycleManager)
            print("🟡 [DI] Tracked lifecycle manager: \(type(of: manager))")
        }
    }
    
    /// Start all managers that support lifecycle management
    /// Called when app becomes active
    func startupManagers() async {
        print("🟡 [DI] Starting up managers...")
        
        for manager in lifecycleManagers {
            do {
                try await manager.startup()
                print("🟡 [DI] Started: \(type(of: manager))")
            } catch {
                print("🟡 [DI] Failed to start \(type(of: manager)): \(error)")
            }
        }
    }
    
    /// Shutdown all managers that support lifecycle management
    /// Called when app goes to background
    func shutdownManagers() async {
        print("🟡 [DI] Shutting down managers...")
        
        // Shutdown in reverse order of initialization
        for manager in lifecycleManagers.reversed() {
            await manager.shutdown()
            print("🟡 [DI] Shutdown: \(type(of: manager))")
        }
    }
    
    /// Preload critical managers that should be available immediately
    /// Call this after authentication is confirmed
    func preloadCriticalManagers() {
        print("🟡 [DI] Preloading critical managers...")
        
        // Force initialization of critical managers
        _ = authManager
        _ = navigationManager
        _ = coreDataManager
        
        print("🟡 [DI] Critical managers preloaded")
    }
    
    // MARK: - Factory Methods
    
    /// Creates a view model with injected dependencies
    func makeMyHealthViewModel() -> MyHealthViewModel {
        // In the future, ViewModels should accept protocol dependencies
        // For now, they still use singletons internally
        return MyHealthViewModel()
    }
    
    func makeDoctorListViewModel() -> DoctorListViewModel {
        return DoctorListViewModel()
    }
    
    func makeConflictsViewModel() -> ConflictsViewModel {
        return ConflictsViewModel()
    }
    
    func makeGroupsViewModel() -> GroupsViewModel {
        return GroupsViewModel()
    }
}

// MARK: - Manager Conformances
// Note: All managers already declare protocol conformance in their class definitions

// MARK: - View Extension
// Swift 6 compliant - Uses standard SwiftUI @EnvironmentObject pattern

extension View {
    /// Injects the dependency container using standard SwiftUI pattern
    /// This is for backwards compatibility - new code should use .environmentObject directly
    func withDependencies(_ container: DIContainer) -> some View {
        self.environmentObject(container)
    }
}
