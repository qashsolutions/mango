import SwiftUI

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    // iOS 18/Swift 6: Direct reference to @Observable singleton
    private let navigationManager = NavigationManager.shared
    
    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.MyHealth.quickActions)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.medium) {
                QuickActionCard(
                    icon: AppIcons.conflicts,
                    title: AppStrings.Conflicts.checkConflicts,
                    subtitle: AppStrings.Conflicts.checkConflictsSubtitle,
                    color: AppTheme.Colors.warning
                ) {
                    navigationManager.presentSheet(.medicationConflictCheck)
                }
                
                QuickActionCard(
                    icon: AppIcons.voiceInput,
                    title: AppStrings.Voice.quickEntry,
                    subtitle: AppStrings.Voice.quickEntrySubtitle,
                    color: AppTheme.Colors.voiceActive
                ) {
                    navigationManager.presentSheet(.voiceInput(context: .general))
                }
                
                QuickActionCard(
                    icon: AppIcons.doctors,
                    title: AppStrings.Doctors.contactDoctor,
                    subtitle: AppStrings.Doctors.contactDoctorSubtitle,
                    color: AppTheme.Colors.secondary
                ) {
                    navigationManager.selectTab(.doctorList)
                }
                
                QuickActionCard(
                    icon: AppIcons.caregivers,
                    title: AppStrings.Caregivers.manageAccess,
                    subtitle: AppStrings.Caregivers.manageAccessSubtitle,
                    color: AppTheme.Colors.primary
                ) {
                    navigationManager.selectTab(.groups)
                }
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                iconView
                textContent
                Spacer()
            }
            .frame(height: 100)
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(
                color: AppTheme.Shadow.medium.color,
                radius: AppTheme.Shadow.medium.radius,
                x: AppTheme.Shadow.medium.x,
                y: AppTheme.Shadow.medium.y
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        HStack {
            Image(systemName: icon)
                .font(AppTheme.Typography.headline)
                .foregroundColor(color)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.primaryText)
                .multilineTextAlignment(.leading)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
    }
}