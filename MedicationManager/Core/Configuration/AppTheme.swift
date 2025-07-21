import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color.blue
        static let primaryVariant = Color.blue.opacity(0.8)
        static let secondary = Color.green
        static let shadow = Color.black.opacity(0.1)
        static let accent = Color.yellow
        static let neutral = Color.gray
        
        static let cardBorder = Color.gray.opacity(0.2)
        
        // Background Colors
        static let background = Color(.systemBackground)
        static let surface = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
        static let primaryBackground = Color.blue.opacity(0.1)
        static let infoBackground = Color.blue.opacity(0.1)
        static let warningBackground = Color.orange.opacity(0.1)
        static let errorBackground = Color.red.opacity(0.1)
        static let successBackground = Color.green.opacity(0.1)
        static let secondaryBackground = Color.gray.opacity(0.1)
        static let inputBackground = Color(.tertiarySystemBackground)
        static let neutralBackground = Color(.secondarySystemBackground)
        static let backgroundspaceAndNewlines = Color(.systemGroupedBackground)
        static let border = Color.gray.opacity(0.2)
        // Text Colors
        static let onPrimary = Color.white
        
        static let onSecondary = Color.white
        static let onBackground = Color(.label)
        static let onSurface = Color(.label)
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        static let textSecondary = Color(.secondaryLabel)
        static let text = Color(.label)
        
        
        // State Colors
        static let inactive = Color.gray.opacity(0.5)
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        static let critical = Color.purple
        static let divider = Color.gray.opacity(0.2)
        // Medication Conflict Severity
        static let conflictLow = Color.yellow
        static let conflictMedium = Color.orange
        static let conflictHigh = Color.red
        static let conflictCritical = Color.purple
        
        // Results
        static let onError = Color.white
        static let onSuccess = Color.white
        static let onWarning = Color.black
        
        // Voice Input Colors
        static let voiceProcessing = Color.blue.opacity(0.8)
        static let voiceActive = Color.green
        static let voiceInactive = Color.gray
        static let voiceError = Color.red
        static let voiceDisabled = Color.gray.opacity(0.5)
        static let voicePlaceholder = Color.gray.opacity(0.6)
        static let voiceIdle = Color.gray.opacity(0.6)
        static let voiceActiveBorder = Color.green
        static let onVoiceActive = Color.white
        static let onVoiceInactive = Color.white
        static let onVoiceError = Color.white
        static let onVoiceDisabled = Color.gray.opacity(0.6)
        static let onVoiceIdle = Color.gray.opacity(0.6)
        static let permissionNeeded = Color.red
        static let voiceIdleBorder = Color.gray.opacity(0.6)
        
        // Opacity Constants
        static let inactiveOpacity: Double = 0.3
        static let lightBackgroundOpacity: Double = 0.2
        static let buttonOpacity: Double = 0.8
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 2
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
        static let xxxLarge: CGFloat = 100
        static let xSmall: CGFloat = 8
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let extraSmall: CGFloat = 4
        static let pill = CGFloat.infinity
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let shadow = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let cardRadius = CGFloat(8)
        static let cardShadowRadius: CGFloat = 12
        static let cardOffset = CGPoint(x: 0, y: 2)
    }
    
    // MARK: - Shadow (alias for backward compatibility)
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let shadow = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    }
    
    // MARK: - Shadow Radius
    struct ShadowRadius {
        static let small: CGFloat = 2
        static let medium: CGFloat = 4
        static let large: CGFloat = 8
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let loadingScale: CGFloat = 0.8
    }
    
    // MARK: - Layout
    struct Layout {
        static let minimumTouchTarget: CGFloat = 44
        static let cardMinHeight: CGFloat = 60
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 44
        static let navigationBarHeight: CGFloat = 44
        static let navBarHeight: CGFloat = 70
        static let tabBarHeight: CGFloat = 83
        static let floatingButtonBottomOffset: CGFloat = 90
        static let floatingButtonEdgeConstraint: CGFloat = 24
        static let qrCodeSize: CGFloat = 200
        static let inputFieldMaxWidth: CGFloat = 400
        static let maxContentWidth: CGFloat = 600
    }
    
    // MARK: - Sizing
    struct Sizing {
        static let iconSmall: CGFloat = 24
        static let iconMedium: CGFloat = 44
        static let iconLarge: CGFloat = 64
        static let buttonSmall: CGFloat = 36
        static let buttonMedium: CGFloat = 44
        static let buttonLarge: CGFloat = 56
    }
    
    // MARK: - Opacity
    struct Opacity {
        static let low: Double = 0.3
        static let medium: Double = 0.6
        static let high: Double = 0.8
        static let disabled: Double = 0.5
    }
    
    // MARK: - Icon Sizes
    struct IconSizes {
        static let tiny: CGFloat = 10
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 16
        static let alert: CGFloat = 18
    }
    
    struct IconSize {
        static let extraSmall: CGFloat = 16
        static let small: CGFloat = 20
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let extraLarge: CGFloat = 40
        static let xxLarge: CGFloat = 48
        static let xxxLarge: CGFloat = 60
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        static let compactIndicatorSize: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let severityBarWidth: CGFloat = 3
        static let severityBarHeight: CGFloat = 12
        static let severityBarCornerRadius: CGFloat = 1.5
        static let progressBarHeight: CGFloat = 4
        static let progressBarCornerRadius: CGFloat = 2
        static let floatingButtonRadius: CGFloat = 28
    }
    
    // MARK: - Extended Animation Durations
    struct AnimationDurations {
        static let criticalPulseDuration: Double = 0.8
        static let standardBadgeDuration: Double = 1.2
        static let progressAnimationDuration: Double = 0.8
        static let dismissDuration: Double = 0.3
    }
}
