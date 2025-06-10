import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors - with fallback colors for now
        static let primary = Color.blue  // Will be replaced with Color("PrimaryColor") later
        static let primaryVariant = Color.blue.opacity(0.8)
        static let secondary = Color.green
        static let shadow = Color.black.opacity(0.125)
        
        static let cardBorder = Color.gray.opacity(0.25)
        // Background Colors
        static let background = Color(.systemBackground)
        static let surface = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
        static let primaryBackground = Color.blue
        static let inforBackground = Color.blue
        static let infoBackground = Color.blue.opacity(0.1)
        static let warningBackground = Color.orange.opacity(0.1)
        static let errorBackground = Color.red.opacity(0.1)
        static let successBackground = Color.green.opacity(0.1)
        static let secondaryBackground = Color.gray.opacity(0.1)
        // Text Colors
        static let onPrimary = Color.white
        static let onSecondary = Color.white
        static let onBackground = Color.primary
        static let onSurface = Color.primary
        static let secondaryText = Color.gray
        static let primaryText = Color.black
        static let tertiaryText = Color.gray.opacity(0.5)
        
        // State Colors
        static let inactive = Color.gray.opacity(0.6)
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        static let critical = Color.purple
        
        // Medication Conflict Severity
        static let conflictLow = Color.yellow
        static let conflictMedium = Color.orange
        static let conflictHigh = Color.red
        static let conflictCritical = Color.purple
        
        // Results
        static let onError = Color.white
        static let onSuccess = Color.white
        static let onWarning = Color.black
        
        //voice Input Colors
        static let voiceProcessing = Color.blue.opacity(0.7)
        static let voiceActive = Color.green
        static let voiceInactive = Color.gray
        static let voiceError = Color.red
        static let voiceDisabled = Color.gray
        static let voicePlaceholder = Color.gray
        static let voiceIdle = Color.gray
        static let voiceActiveBorder = Color.green
        static let onVoiceActive = Color.white
        static let onVoiceInactive = Color.white
        static let onVoiceError = Color.white
        static let onVoiceDisabled = Color.gray
        static let onVoiceIdle = Color.gray
        static let permissionNeeded = Color.red
        static let voiceIdleBorder = Color.gray
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.custom("SF-Pro-Display-Bold", size: 34, relativeTo: .largeTitle)
        static let title1 = Font.custom("SF-Pro-Display-Bold", size: 28, relativeTo: .title)
        static let title2 = Font.custom("SF-Pro-Display-Bold", size: 22, relativeTo: .title2)
        static let title3 = Font.custom("SF-Pro-Display-Semibold", size: 20, relativeTo: .title3)
        static let headline = Font.custom("SF-Pro-Display-Semibold", size: 17, relativeTo: .headline)
        static let body = Font.custom("SF-Pro-Text-Regular", size: 17, relativeTo: .body)
        static let callout = Font.custom("SF-Pro-Text-Regular", size: 16, relativeTo: .callout)
        static let subheadline = Font.custom("SF-Pro-Text-Regular", size: 15, relativeTo: .subheadline)
        static let footnote = Font.custom("SF-Pro-Text-Regular", size: 13, relativeTo: .footnote)
        static let caption1 = Font.custom("SF-Pro-Text-Regular", size: 12, relativeTo: .caption)
        static let caption2 = Font.custom("SF-Pro-Text-Regular", size: 11, relativeTo: .caption2)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let extraSmall: CGFloat = 4
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let shadow = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let cardRadius = CGFloat(8)
        static let cardShadowRadius: CGFloat = 12
        static let cardOffset = CGPoint(x: 0, y: 2)
    }
    
    // MARK: - Shadow (alias for backward compatibility)
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let shadow = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
    
    // MARK: - Layout
    struct Layout {
        static let minimumTouchTarget: CGFloat = 44
        static let cardMinHeight: CGFloat = 60
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 44
        static let navigationBarHeight: CGFloat = 44
        static let tabBarHeight: CGFloat = 83
        static let qrCodeSize: CGFloat = 200
        static let inputFieldMaxWidth: CGFloat = 200
    }
}
