import SwiftUI

struct ActionButton: View {
    let title: String
    let action: () -> Void
    let style: ActionButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    
    init(
        title: String,
        action: @escaping () -> Void,
        style: ActionButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let icon = style.icon {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.body)
                }
                
                Text(title)
                    .font(AppTheme.Typography.headline)
            }
            .foregroundColor(style.foregroundColor)
            .frame(height: AppTheme.Layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(ActionButtonPressStyle())
    }
}

// MARK: - Action Button Styles
enum ActionButtonStyle {
    case primary
    case secondary
    case destructive
    case success
    case warning
    case ghost
    case outline
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return AppTheme.Colors.primary
        case .secondary:
            return AppTheme.Colors.secondary
        case .destructive:
            return AppTheme.Colors.error
        case .success:
            return AppTheme.Colors.success
        case .warning:
            return AppTheme.Colors.warning
        case .ghost:
            return Color.clear
        case .outline:
            return Color.clear
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary:
            return AppTheme.Colors.onPrimary
        case .secondary:
            return AppTheme.Colors.onSecondary
        case .destructive:
            return AppTheme.Colors.onError
        case .success:
            return AppTheme.Colors.onSuccess
        case .warning:
            return AppTheme.Colors.onWarning
        case .ghost:
            return AppTheme.Colors.primary
        case .outline:
            return AppTheme.Colors.primary
        }
    }
    
    var borderColor: Color {
        switch self {
        case .outline:
            return AppTheme.Colors.primary
        case .ghost:
            return Color.clear
        default:
            return backgroundColor
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outline:
            return 1.5
        default:
            return 0
        }
    }
    
    var icon: String? {
        switch self {
        case .success:
            return "checkmark"
        case .destructive:
            return "trash"
        case .warning:
            return "exclamationmark.triangle"
        default:
            return nil
        }
    }
}

// MARK: - Button Press Style
struct ActionButtonPressStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Action Button
struct CompactActionButton: View {
    let title: String
    let action: () -> Void
    let style: ActionButtonStyle
    let isLoading: Bool
    
    init(
        title: String,
        action: @escaping () -> Void,
        style: ActionButtonStyle = .primary,
        isLoading: Bool = false
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.extraSmall) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let icon = style.icon {
                    Image(systemName: icon)
                        .font(AppTheme.Typography.caption)
                }
                
                Text(title)
                    .font(AppTheme.Typography.caption1)
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.extraSmall)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .disabled(isLoading)
        .buttonStyle(ActionButtonPressStyle())
    }
}

// MARK: - Icon Action Button
struct IconActionButton: View {
    let icon: String
    let action: () -> Void
    let style: ActionButtonStyle
    let size: IconButtonSize
    
    init(
        icon: String,
        action: @escaping () -> Void,
        style: ActionButtonStyle = .primary,
        size: IconButtonSize = .medium
    ) {
        self.icon = icon
        self.action = action
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(style.foregroundColor)
                .frame(width: size.buttonSize, height: size.buttonSize)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: style.borderWidth)
                )
                .cornerRadius(size.cornerRadius)
        }
        .buttonStyle(ActionButtonPressStyle())
    }
}

enum IconButtonSize {
    case small
    case medium
    case large
    
    var buttonSize: CGFloat {
        switch self {
        case .small:
            return 32
        case .medium:
            return 40
        case .large:
            return 48
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 18
        case .large:
            return 22
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return AppTheme.CornerRadius.small
        case .medium:
            return AppTheme.CornerRadius.medium
        case .large:
            return AppTheme.CornerRadius.large
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.onPrimary)
                .frame(width: AppTheme.Sizing.iconLarge, height: AppTheme.Sizing.iconLarge)
                .background(AppTheme.Colors.primary)
                .cornerRadius(28)
                .shadow(
                    color: AppTheme.Colors.shadow,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(ActionButtonPressStyle())
    }
}

// MARK: - Specialized Action Buttons
struct VoiceActionButton: View {
    let onVoiceResult: (String) -> Void
    let context: VoiceInteractionContext
    
    var body: some View {
        CompactActionButton(
            title: AppStrings.Voice.useVoice,
            action: {},
            style: .ghost
        )
        .overlay(
            VoiceInputButton(context: context, onResult: onVoiceResult)
                .scaleEffect(0.6)
        )
    }
}

// MARK: - Button Group
struct ActionButtonGroup: View {
    let buttons: [ActionButtonGroupItem]
    let axis: Axis
    let spacing: CGFloat
    
    init(
        buttons: [ActionButtonGroupItem],
        axis: Axis = .horizontal,
        spacing: CGFloat = AppTheme.Spacing.medium
    ) {
        self.buttons = buttons
        self.axis = axis
        self.spacing = spacing
    }
    
    var body: some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: spacing) {
                    ForEach(buttons.indices, id: \.self) { index in
                        buttons[index].button
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    ForEach(buttons.indices, id: \.self) { index in
                        buttons[index].button
                    }
                }
            }
        }
    }
}

struct ActionButtonGroupItem {
    let button: AnyView
    
    init<Button: View>(@ViewBuilder button: () -> Button) {
        self.button = AnyView(button())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.large) {
            // Standard Action Buttons
            Group {
                ActionButton(title: "Primary Action", action: {})
                
                ActionButton(
                    title: "Secondary Action",
                    action: {},
                    style: .secondary
                )
                
                ActionButton(
                    title: "Destructive Action",
                    action: {},
                    style: .destructive
                )
                
                ActionButton(
                    title: "Loading Action",
                    action: {},
                    isLoading: true
                )
                
                ActionButton(
                    title: "Disabled Action",
                    action: {},
                    isDisabled: true
                )
            }
            
            Divider()
            
            // Compact Buttons
            HStack(spacing: AppTheme.Spacing.medium) {
                CompactActionButton(title: "Save", action: {})
                CompactActionButton(title: "Cancel", action: {}, style: .ghost)
            }
            
            Divider()
            
            // Icon Buttons
            HStack(spacing: AppTheme.Spacing.medium) {
                IconActionButton(icon: "plus", action: {})
                IconActionButton(icon: "pencil", action: {}, style: .secondary)
                IconActionButton(icon: "trash", action: {}, style: .destructive)
            }
            
            Divider()
            
            // Floating Action Button
            FloatingActionButton(icon: "plus", action: {})
            
            Divider()
            
            // Specialized Buttons
            SyncActionButton()
        }
        .padding()
    }
    .background(AppTheme.Colors.background)
}