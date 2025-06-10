import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = FirebaseManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationLandingView()
            }
        }
    }
}

// MARK: - Authentication Landing View
struct AuthenticationLandingView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.large) {
                Image(systemName: AppIcons.health)
                    .font(.system(size: 60))
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
            .navigationTitle("Mango Health")
        }
        .fullScreenCover(item: $navigationManager.presentedFullScreenCover) { destination in
            FullScreenCoverView(destination: destination)
        }
    }
}

#Preview {
    ContentView()
}
