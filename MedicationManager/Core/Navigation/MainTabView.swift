import SwiftUI

struct MainTabView: View {
    let viewFactory: ViewFactoryProtocol
    
    // NavigationManager uses @Observable - needs @Bindable for binding support
    @Bindable private var navigationManager = NavigationManager.shared
    // FirebaseManager now uses @Observable - no property wrapper needed
    private let authManager = FirebaseManager.shared
    private let dataSync = DataSyncManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            myHealthTabView()
                .tabItem {
                    Label(
                        MainTab.myHealth.displayName,
                        systemImage: navigationManager.selectedTab == .myHealth ? 
                            MainTab.myHealth.selectedIcon : MainTab.myHealth.icon
                    )
                }
                .tag(MainTab.myHealth)
            
            doctorListTabView()
                .tabItem {
                    Label(
                        MainTab.doctorList.displayName,
                        systemImage: navigationManager.selectedTab == .doctorList ? 
                            MainTab.doctorList.selectedIcon : MainTab.doctorList.icon
                    )
                }
                .tag(MainTab.doctorList)
            
            groupsTabView()
                .tabItem {
                    Label(
                        MainTab.groups.displayName,
                        systemImage: navigationManager.selectedTab == .groups ? 
                            MainTab.groups.selectedIcon : MainTab.groups.icon
                    )
                }
                .tag(MainTab.groups)
            
            conflictsTabView()
                .tabItem {
                    Label(
                        MainTab.conflicts.displayName,
                        systemImage: navigationManager.selectedTab == .conflicts ? 
                            MainTab.conflicts.selectedIcon : MainTab.conflicts.icon
                    )
                }
                .tag(MainTab.conflicts)
        }
        .onAppear {
            setupTabBarAppearance()
            Task {
                await initializeApp()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .sheet(item: $navigationManager.presentedSheet) { destination in
            viewFactory.createSheetView(for: destination)
        }
        .fullScreenCover(item: $navigationManager.presentedFullScreenCover) { destination in
            FullScreenCoverView(destination: destination, viewFactory: viewFactory)
        }
    }
    
    // ... rest of the file where dataSync.syncPendingChanges() is called
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            Task {
                if authManager.isAuthenticated {
                    do {
                        try await dataSync.syncPendingChanges()
                    } catch {
                        // Log error but don't interrupt user experience
                        print("Background sync failed: \(error)")
                    }
                }
            }
        case .background:
            // Save any pending changes when backgrounding
            Task {
                try await CoreDataManager.shared.saveContext()
            }
        default:
            break
        }
    }
    
    private func initializeApp() async {
        let startTime = Date()
        
        // Initialize managers if needed
        if authManager.isAuthenticated {
            do {
                try await dataSync.syncPendingChanges()
            } catch {
                // Initial sync failure shouldn't block app launch
                print("Initial sync failed: \(error)")
            }
        }
        
        let loadTime = Date().timeIntervalSince(startTime)
        AnalyticsManager.shared.trackEvent("tab_load_time", parameters: ["tab": "myHealth", "duration": loadTime])
    }
    
    // MARK: - Tab Views
    @ViewBuilder
    private func myHealthTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            viewFactory.createTabView(for: .myHealth)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    viewFactory.createDetailView(for: destination)
                }
        }
    }
    
    @ViewBuilder
    private func doctorListTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            viewFactory.createTabView(for: .doctorList)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    viewFactory.createDetailView(for: destination)
                }
        }
    }
    
    @ViewBuilder
    private func groupsTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            viewFactory.createTabView(for: .groups)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    viewFactory.createDetailView(for: destination)
                }
        }
    }
    
    @ViewBuilder
    private func conflictsTabView() -> some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            viewFactory.createTabView(for: .conflicts)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    viewFactory.createDetailView(for: destination)
                }
        }
    }
    
    // MARK: - Appearance Setup
    private func setupTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppTheme.Colors.surface)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}