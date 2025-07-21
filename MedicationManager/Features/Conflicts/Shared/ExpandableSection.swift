import SwiftUI

struct ExpandableSection<Content: View>: View {
    let id: String
    let title: String
    var badge: String? = nil
    var badgeColor: Color = AppTheme.Colors.primary
    let isExpanded: Bool
    @ViewBuilder let content: () -> Content
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.onBackground)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.onPrimary)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.xSmall)
                            .background(badgeColor)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(AppTheme.Animation.standard, value: isExpanded)
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.surface)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                VStack {
                    Divider()
                        .background(AppTheme.Colors.divider)
                    
                    content()
                        .padding(AppTheme.Spacing.medium)
                }
                .background(AppTheme.Colors.surface)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.CornerRadius.large)
        .animation(AppTheme.Animation.standard, value: isExpanded)
    }
}