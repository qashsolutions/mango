import SwiftUI

struct ContentView: View {
    // iOS 18/Swift 6: Direct reference to @Observable singleton (no property wrapper needed)
    private let authManager = FirebaseManager.shared
    private let viewFactory = AppViewFactory()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(viewFactory: viewFactory)
            } else {
                AuthenticationView()
            }
        }
    }
}

// MARK: - Authentication Landing View
struct AuthenticationLandingView: View {
    // Use singleton directly - it manages its own lifecycle with @Observable
    @Bindable private var navigationManager = NavigationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                Image(systemName: AppIcons.health)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text(AppStrings.Authentication.welcomeMessage)
                    .font(AppTheme.Typography.title1)
                    .multilineTextAlignment(.center)
                
                Text(AppStrings.Authentication.welcomeSubtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.onBackground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                
                Spacer()
                
                VStack(spacing: AppTheme.Spacing.medium) {
                    Button(AppStrings.Authentication.signIn) {
                        navigationManager.handleAuthenticationRequired()
                    }
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.onPrimary)
                    .frame(height: AppTheme.Layout.buttonHeight)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    
                    Text(AppStrings.Legal.medicalDisclaimer)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.onBackground)
                }
            }
            .padding(AppTheme.Spacing.large)
            .navigationTitle("MyGuide")
        }
        .fullScreenCover(item: $navigationManager.presentedFullScreenCover) { destination in
            FullScreenCoverView(destination: destination, viewFactory: AppViewFactory())
        }
    }
}

#Preview {
    ContentView()
}
