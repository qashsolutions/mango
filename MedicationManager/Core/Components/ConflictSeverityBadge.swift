import SwiftUI

struct ConflictSeverityBadge: View {
    let severity: ConflictSeverity
    let size: BadgeSize
    let showLabel: Bool
    
    init(
        severity: ConflictSeverity,
        size: BadgeSize = .medium,
        showLabel: Bool = true
    ) {
        self.severity = severity
        self.size = size
        self.showLabel = showLabel
    }
    
    var body: some View {
        HStack(spacing: size.spacing) {
            // Icon
            Image(systemName: severity.icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(severity.foregroundColor)
            
            // Label
            if showLabel {
                Text(severity.displayName)
                    .font(size.font)
                    .foregroundColor(severity.foregroundColor)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(severity.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(severity.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Badge Size
enum BadgeSize {
    case small
    case medium
    case large
    
    var iconSize: CGFloat {
        switch self {
        case .small: return AppTheme.IconSizes.small
        case .medium: return AppTheme.IconSizes.medium
        case .large: return AppTheme.IconSizes.large
        }
    }
    
    var font: Font {
        switch self {
        case .small: return AppTheme.Typography.caption2
        case .medium: return AppTheme.Typography.caption1
        case .large: return AppTheme.Typography.subheadline
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return AppTheme.Spacing.extraSmall
        case .medium: return AppTheme.Spacing.small
        case .large: return AppTheme.Spacing.small
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return AppTheme.Spacing.small
        case .medium: return AppTheme.Spacing.medium
        case .large: return AppTheme.Spacing.large
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return AppTheme.Spacing.extraSmall
        case .medium: return AppTheme.Spacing.small
        case .large: return AppTheme.Spacing.medium
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return AppTheme.CornerRadius.small
        case .medium: return AppTheme.CornerRadius.medium
        case .large: return AppTheme.CornerRadius.medium
        }
    }
}

// MARK: - Animated Severity Badge
struct AnimatedConflictSeverityBadge: View {
    let severity: ConflictSeverity
    let size: BadgeSize
    
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ConflictSeverityBadge(severity: severity, size: size)
            .scaleEffect(isAnimating ? 1.0 : 0.95)
            .opacity(isAnimating ? 1.0 : AppTheme.Colors.buttonOpacity)
            .animation(
                severity == .critical ?
                Animation.easeInOut(duration: AppTheme.AnimationDurations.criticalPulseDuration).repeatForever(autoreverses: true) :
                Animation.easeInOut(duration: AppTheme.AnimationDurations.standardBadgeDuration),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Severity Indicator
struct SeverityIndicator: View {
    let severity: ConflictSeverity
    let isCompact: Bool
    
    init(severity: ConflictSeverity, isCompact: Bool = false) {
        self.severity = severity
        self.isCompact = isCompact
    }
    
    var body: some View {
        if isCompact {
            compactIndicator()
        } else {
            fullIndicator()
        }
    }
    
    @ViewBuilder
    private func compactIndicator() -> some View {
        Circle()
            .fill(severity.backgroundColor)
            .frame(width: AppTheme.Dimensions.compactIndicatorSize, height: AppTheme.Dimensions.compactIndicatorSize)
            .overlay(
                Circle()
                    .stroke(severity.borderColor, lineWidth: AppTheme.Dimensions.borderWidth)
            )
    }
    
    @ViewBuilder
    private func fullIndicator() -> some View {
        HStack(spacing: AppTheme.Spacing.extraSmall / 2) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index < severity.level ? severity.color : AppTheme.Colors.tertiaryText.opacity(AppTheme.Colors.inactiveOpacity))
                    .frame(width: AppTheme.Dimensions.severityBarWidth, height: AppTheme.Dimensions.severityBarHeight)
                    .cornerRadius(AppTheme.Dimensions.severityBarCornerRadius)
            }
        }
    }
}

// MARK: - Severity Progress Bar
struct SeverityProgressBar: View {
    let severity: ConflictSeverity
    let showLabel: Bool
    
    @State private var progressValue: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if showLabel {
                HStack {
                    Text(AppStrings.Conflicts.severityLevels)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text(severity.displayName)
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(severity.color)
                        .fontWeight(.medium)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.progressBarCornerRadius)
                        .fill(AppTheme.Colors.tertiaryText.opacity(AppTheme.Colors.lightBackgroundOpacity))
                        .frame(height: AppTheme.Dimensions.progressBarHeight)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: AppTheme.Dimensions.progressBarCornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [severity.color.opacity(AppTheme.Colors.buttonOpacity), severity.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressValue, height: AppTheme.Dimensions.progressBarHeight)
                }
            }
            .frame(height: AppTheme.Dimensions.progressBarHeight)
            .onAppear {
                withAnimation(.easeOut(duration: AppTheme.AnimationDurations.progressAnimationDuration)) {
                    progressValue = CGFloat(severity.level) / CGFloat(Configuration.Conflicts.maxSeverityLevels)
                }
            }
        }
    }
}

// MARK: - Conflict Count Badge
struct ConflictCountBadge: View {
    let count: Int
    let severity: ConflictSeverity?
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.extraSmall) {
            if let severity = severity {
                Image(systemName: severity.icon)
                    .font(.system(size: AppTheme.IconSizes.tiny, weight: .medium))
                    .foregroundColor(severity.foregroundColor)
            }
            
            Text("\(count)")
                .font(AppTheme.Typography.caption1)
                .foregroundColor(textColor)
                .fontWeight(.bold)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.extraSmall / 2)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var textColor: Color {
        if let severity = severity {
            return severity.foregroundColor
        }
        return count > 0 ? AppTheme.Colors.onSurface : AppTheme.Colors.secondaryText
    }
    
    private var backgroundColor: Color {
        if let severity = severity {
            return severity.backgroundColor
        }
        return count > 0 ? AppTheme.Colors.warningBackground : AppTheme.Colors.inputBackground
    }
    
    private var borderColor: Color {
        if let severity = severity {
            return severity.borderColor
        }
        return count > 0 ? AppTheme.Colors.warning.opacity(AppTheme.Opacity.low) : AppTheme.Colors.cardBorder
    }
}

// MARK: - Severity Legend
struct SeverityLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(AppStrings.Conflicts.severityLevels)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(ConflictSeverity.allCases, id: \.self) { severity in
                    HStack(spacing: AppTheme.Spacing.medium) {
                        ConflictSeverityBadge(
                            severity: severity,
                            size: .small,
                            showLabel: false
                        )
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.extraSmall / 2) {
                            Text(severity.displayName)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.primaryText)
                            
                            Text(severity.description)
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Severity Alert Banner
struct SeverityAlertBanner: View {
    let severity: ConflictSeverity
    let message: String
    let onDismiss: (() -> Void)?
    
    @State private var isVisible: Bool = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: severity.icon)
                    .font(.system(size: AppTheme.IconSizes.alert, weight: .medium))
                    .foregroundColor(severity.foregroundColor)
                
                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(severity.foregroundColor)
                    .lineLimit(2)
                
                Spacer()
                
                if let onDismiss = onDismiss {
                    Button(action: {
                        withAnimation(.easeOut(duration: AppTheme.AnimationDurations.dismissDuration)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.AnimationDurations.dismissDuration) {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: AppIcons.close)
                            .font(.system(size: AppTheme.IconSizes.small, weight: .medium))
                            .foregroundColor(severity.foregroundColor.opacity(AppTheme.Colors.buttonOpacity))
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(severity.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(severity.borderColor, lineWidth: 1)
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.large) {
            // Basic badges
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.UI.severityBadges)
                    .font(AppTheme.Typography.title3)
                
                HStack(spacing: AppTheme.Spacing.medium) {
                    ConflictSeverityBadge(severity: .none, size: .small)
                    ConflictSeverityBadge(severity: .low, size: .small)
                    ConflictSeverityBadge(severity: .medium, size: .small)
                    ConflictSeverityBadge(severity: .high, size: .small)
                    ConflictSeverityBadge(severity: .critical, size: .small)
                }
                
                HStack(spacing: AppTheme.Spacing.medium) {
                    AnimatedConflictSeverityBadge(severity: .critical, size: .medium)
                    AnimatedConflictSeverityBadge(severity: .high, size: .medium)
                }
            }
            
            Divider()
            
            // Indicators
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.UI.severityIndicators)
                    .font(AppTheme.Typography.title3)
                
                HStack(spacing: AppTheme.Spacing.large) {
                    ForEach(ConflictSeverity.allCases, id: \.self) { severity in
                        VStack(spacing: AppTheme.Spacing.small) {
                            SeverityIndicator(severity: severity, isCompact: false)
                            SeverityIndicator(severity: severity, isCompact: true)
                        }
                    }
                }
            }
            
            Divider()
            
            // Progress bars
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.UI.severityProgressBars)
                    .font(AppTheme.Typography.title3)
                
                ForEach(ConflictSeverity.allCases, id: \.self) { severity in
                    SeverityProgressBar(severity: severity, showLabel: true)
                }
            }
            
            Divider()
            
            // Count badges
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.UI.conflictCountBadges)
                    .font(AppTheme.Typography.title3)
                
                HStack(spacing: AppTheme.Spacing.medium) {
                    ConflictCountBadge(count: 0, severity: nil)
                    ConflictCountBadge(count: 3, severity: .low)
                    ConflictCountBadge(count: 2, severity: .medium)
                    ConflictCountBadge(count: 1, severity: .critical)
                }
            }
            
            Divider()
            
            // Alert banners
            VStack(spacing: AppTheme.Spacing.medium) {
                Text(AppStrings.UI.alertBanners)
                    .font(AppTheme.Typography.title3)
                
                SeverityAlertBanner(
                    severity: .critical,
                    message: AppStrings.Conflicts.criticalAlertMessage,
                    onDismiss: {}
                )
                
                SeverityAlertBanner(
                    severity: .medium,
                    message: AppStrings.Conflicts.moderateAlertMessage,
                    onDismiss: nil
                )
            }
            
            Divider()
            
            // Legend
            SeverityLegend()
        }
        .padding()
    }
    .background(AppTheme.Colors.background)
}