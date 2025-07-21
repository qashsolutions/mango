import SwiftUI

struct VoiceCommandButton: View {
    let action: () -> Void
    let context: VoiceInteractionContext
    
    @State private var isPressed: Bool = false
    @State private var showPulse: Bool = false
    @State private var voiceManager = VoiceInteractionManager.shared
    
    private let buttonSize: CGFloat = 56
    private let iconSize: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Pulse animation when voice is available
            if Configuration.Voice.showPulseAnimation && !voiceManager.isListening {
                Circle()
                    .fill(AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low))
                    .frame(width: buttonSize, height: buttonSize)
                    .scaleEffect(showPulse ? 1.5 : 1.0)
                    .opacity(showPulse ? 0 : 0.8)
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false),
                        value: showPulse
                    )
            }
            
            // Main button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }) {
                ZStack {
                    // Background
                    Circle()
                        .fill(voiceManager.isListening ? AppTheme.Colors.voiceActive : AppTheme.Colors.primary)
                        .frame(width: buttonSize, height: buttonSize)
                    
                    // Icon
                    Image(systemName: voiceManager.isListening ? AppIcons.voiceRecording : AppIcons.voiceInput)
                        .font(AppTheme.Typography.title)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .scaleEffect(voiceManager.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: voiceManager.isListening)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .shadow(
                    color: voiceManager.isListening ? AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.medium) : AppTheme.Shadow.large.color,
                    radius: voiceManager.isListening ? AppTheme.Shadow.large.radius * 1.5 : AppTheme.Shadow.large.radius,
                    x: AppTheme.Shadow.large.x,
                    y: AppTheme.Shadow.large.y
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            if Configuration.Voice.showPulseAnimation {
                showPulse = true
            }
        }
    }
}

// MARK: - Floating Voice Command Button
struct FloatingVoiceCommandButton: View {
    let action: () -> Void
    let context: VoiceInteractionContext
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 40, y: UIScreen.main.bounds.height - 200)
    
    var body: some View {
        VoiceCommandButton(action: action, context: context)
            .position(position)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            position.x += value.translation.width
                            position.y += value.translation.height
                            dragOffset = .zero
                            isDragging = false
                            
                            // Snap to edges
                            snapToEdge()
                        }
                    }
            )
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
    
    private func snapToEdge() {
        let screenBounds = UIScreen.main.bounds
        let margin: CGFloat = 20
        let buttonRadius: CGFloat = 28
        
        // Determine closest edge
        let distanceToLeft = position.x
        let distanceToRight = screenBounds.width - position.x
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            // Snap horizontally
            if distanceToLeft < distanceToRight {
                position.x = margin + buttonRadius
            } else {
                position.x = screenBounds.width - margin - buttonRadius
            }
            
            // Constrain vertically
            position.y = max(margin + buttonRadius + 100, min(screenBounds.height - margin - buttonRadius - 100, position.y))
        }
    }
}

// MARK: - Mini Voice Button
struct MiniVoiceButton: View {
    let action: () -> Void
    @State private var isPressed: Bool = false
    @State private var voiceManager = VoiceInteractionManager.shared
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            Image(systemName: voiceManager.isListening ? AppIcons.voiceRecording : AppIcons.voiceInput)
                .font(AppTheme.Typography.body)
                .foregroundColor(voiceManager.isListening ? AppTheme.Colors.voiceActive : AppTheme.Colors.primary)
                .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                .background(
                    Circle()
                        .fill(voiceManager.isListening ? AppTheme.Colors.voiceActive.opacity(AppTheme.Opacity.low) : AppTheme.Colors.primaryBackground)
                )
                .overlay(
                    Circle()
                        .stroke(voiceManager.isListening ? AppTheme.Colors.voiceActive : AppTheme.Colors.primary.opacity(AppTheme.Opacity.low), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Recording Indicator
struct RecordingIndicator: View {
    @State private var isAnimating: Bool = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.tiny) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(AppTheme.Colors.onPrimary)
                    .frame(width: 2, height: isAnimating ? 12 : 6)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Voice Button Group
struct VoiceButtonGroup: View {
    let primaryAction: () -> Void
    let secondaryActions: [(title: String, icon: String, action: () -> Void)]
    
    @State private var isExpanded: Bool = false
    @State private var voiceManager = VoiceInteractionManager.shared
    
    var body: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Spacing.medium) {
            // Secondary actions
            if isExpanded {
                ForEach(secondaryActions.indices, id: \.self) { index in
                    HStack(spacing: AppTheme.Spacing.small) {
                        Text(secondaryActions[index].title)
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.extraSmall)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(
                                        color: AppTheme.Shadow.small.color,
                                        radius: AppTheme.Shadow.small.radius,
                                        x: AppTheme.Shadow.small.x,
                                        y: AppTheme.Shadow.small.y
                                    )
                            )
                        
                        Button(action: secondaryActions[index].action) {
                            Image(systemName: secondaryActions[index].icon)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.onSurface)
                                .frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)
                                .background(AppTheme.Colors.cardBackground)
                                .clipShape(Circle())
                                .shadow(
                                    color: AppTheme.Shadow.small.color,
                                    radius: AppTheme.Shadow.small.radius,
                                    x: AppTheme.Shadow.small.x,
                                    y: AppTheme.Shadow.small.y
                                )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8).delay(Double(index) * 0.05), value: isExpanded)
                }
            }
            
            // Primary voice button
            ZStack(alignment: .topTrailing) {
                VoiceCommandButton(
                    action: voiceManager.isListening ? {} : primaryAction,
                    context: .general
                )
                
                // Expand/collapse button
                if !secondaryActions.isEmpty && !voiceManager.isListening {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? AppIcons.close : AppIcons.plus)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.onPrimary)
                            .frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)
                            .background(AppTheme.Colors.secondary)
                            .clipShape(Circle())
                    }
                    .offset(x: -AppTheme.Spacing.tiny, y: -AppTheme.Spacing.tiny)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()
        
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            // Standard voice button
            VoiceCommandButton(
                action: {},
                context: .conflictQuery
            )
            
            // Mini voice button
            HStack {
                Text(AppStrings.Voice.askAnything)
                    .font(AppTheme.Typography.body)
                Spacer()
                MiniVoiceButton(action: {})
            }
            .padding()
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            
            // Voice button group
            VoiceButtonGroup(
                primaryAction: {},
                secondaryActions: [
                    (title: AppStrings.Medications.addMedication, icon: AppIcons.medications, action: {}),
                    (title: AppStrings.Supplements.addSupplement, icon: AppIcons.supplements, action: {}),
                    (title: AppStrings.Conflicts.checkConflicts, icon: AppIcons.conflicts, action: {})
                ]
            )
        }
        .padding()
        
        // Floating button
        FloatingVoiceCommandButton(
            action: {},
            context: .general
        )
    }
}
