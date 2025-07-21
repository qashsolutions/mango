import SwiftUI

@MainActor
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var firebaseManager = FirebaseManager.shared
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppTheme.Colors.primary.opacity(0.1),
                    AppTheme.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(AppStrings.Notifications.actionSkip) {
                        completeOnboarding()
                    }
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators and navigation
                VStack(spacing: AppTheme.Spacing.large) {
                    // Custom page indicators
                    HStack(spacing: AppTheme.Spacing.small) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? AppTheme.Colors.primary : AppTheme.Colors.divider)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.medium)
                    
                    // Navigation buttons
                    HStack(spacing: AppTheme.Spacing.medium) {
                        if currentPage > 0 {
                            Button(action: previousPage) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text(AppStrings.Navigation.back)
                                }
                                .font(AppTheme.Typography.body)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button(action: nextPageOrComplete) {
                            HStack {
                                Text(currentPage == pages.count - 1 ? AppStrings.Actions.getStarted : AppStrings.Common.next)
                                if currentPage < pages.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.large)
                            .padding(.vertical, AppTheme.Spacing.medium)
                        }
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
        .onAppear {
            AnalyticsManager.shared.trackScreenViewed("onboarding_start")
        }
    }
    
    private func previousPage() {
        withAnimation {
            currentPage = max(0, currentPage - 1)
        }
    }
    
    private func nextPageOrComplete() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        
        // Track completion
        AnalyticsManager.shared.trackEvent(
            "onboarding_completed",
            parameters: ["pages_viewed": currentPage + 1]
        )
        
        // Dismiss
        dismiss()
    }
}

// MARK: - Onboarding Page View
private struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            // Icon
            Image(systemName: page.iconName)
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.bottom, AppTheme.Spacing.large)
            
            // Title
            Text(page.title)
                .font(AppTheme.Typography.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.extraLarge)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Onboarding Page Model
private struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    
    static let allPages = [
        OnboardingPage(
            title: NSLocalizedString("onboarding.welcome.title", value: "Welcome to Mango Health", comment: "Welcome title"),
            description: NSLocalizedString("onboarding.welcome.description", value: "Your personal medication manager with AI-powered conflict detection", comment: "Welcome description"),
            iconName: AppIcons.health
        ),
        OnboardingPage(
            title: NSLocalizedString("onboarding.voice.title", value: "Voice-First Design", comment: "Voice feature title"),
            description: NSLocalizedString("onboarding.voice.description", value: "Add medications, supplements, and diet entries using just your voice", comment: "Voice feature description"),
            iconName: AppIcons.microphone
        ),
        OnboardingPage(
            title: NSLocalizedString("onboarding.ai.title", value: "AI-Powered Safety", comment: "AI feature title"),
            description: NSLocalizedString("onboarding.ai.description", value: "Claude AI analyzes your medications for potential conflicts and interactions", comment: "AI feature description"),
            iconName: AppIcons.ai
        ),
        OnboardingPage(
            title: NSLocalizedString("onboarding.caregivers.title", value: "Share with Caregivers", comment: "Caregiver feature title"),
            description: NSLocalizedString("onboarding.caregivers.description", value: "Invite family members or caregivers to help manage your health", comment: "Caregiver feature description"),
            iconName: AppIcons.caregivers
        ),
        OnboardingPage(
            title: NSLocalizedString("onboarding.getStarted.title", value: "Let's Get Started", comment: "Get started title"),
            description: NSLocalizedString("onboarding.getStarted.description", value: "Set up your profile and add your first medication", comment: "Get started description"),
            iconName: AppIcons.success
        )
    ]
}

#Preview {
    OnboardingView()
}
