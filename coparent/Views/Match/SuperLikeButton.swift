import SwiftUI

struct SuperLikeButton: View {
    let onSuperLike: () -> Void
    let isEnabled: Bool
    let isPremium: Bool
    let cooldownTimeRemaining: TimeInterval
    
    @State private var isPressed = false
    @State private var pulseAnimation = false
    @State private var glowAnimation = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // Haptic feedback for premium feel
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.success)
                
                onSuperLike()
            }
        }) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(glowAnimation ? 0.6 : 0.3),
                                Color.purple.opacity(glowAnimation ? 0.4 : 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                    .opacity(isPremium && isEnabled ? 1 : 0.3)
                
                // Main button background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isPremium && isEnabled ? 
                                        [.blue, .purple] : [.gray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(isPressed ? 0.95 : (pulseAnimation ? 1.05 : 1.0))
                
                // Button content
                buttonContent
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            isPressed = isPressing
        } perform: {}
        .disabled(!isEnabled)
        .onAppear {
            startAnimations()
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        if cooldownTimeRemaining > 0 {
            // Cooldown timer
            VStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
                
                Text(formatCooldownTime(cooldownTimeRemaining))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.gray)
            }
        } else if !isPremium {
            // Locked state for non-premium users
            VStack(spacing: 2) {
                Image(systemName: "star")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        } else {
            // Active super like state
            Image(systemName: "star.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var accessibilityLabel: String {
        if cooldownTimeRemaining > 0 {
            return "Super Like unavailable, cooldown \(formatCooldownTime(cooldownTimeRemaining)) remaining"
        } else if !isPremium {
            return "Super Like requires premium subscription"
        } else {
            return "Super Like"
        }
    }
    
    private var accessibilityHint: String {
        if cooldownTimeRemaining > 0 {
            return "Wait for cooldown to finish"
        } else if !isPremium {
            return "Tap to upgrade to premium"
        } else {
            return "Double tap to send super like"
        }
    }
    
    private func formatCooldownTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func startAnimations() {
        // Only animate if premium and enabled
        guard isPremium && isEnabled else { return }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        // Glow animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
    }
}

#Preview("Super Like Button - Premium Active") {
    VStack(spacing: 30) {
        SuperLikeButton(
            onSuperLike: { print("Super like activated!") },
            isEnabled: true,
            isPremium: true,
            cooldownTimeRemaining: 0
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.1))
}

#Preview("Super Like Button - Cooldown") {
    VStack(spacing: 30) {
        SuperLikeButton(
            onSuperLike: { print("Super like activated!") },
            isEnabled: false,
            isPremium: true,
            cooldownTimeRemaining: 3661 // 1 hour, 1 minute, 1 second
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.1))
}

#Preview("Super Like Button - Non-Premium") {
    VStack(spacing: 30) {
        SuperLikeButton(
            onSuperLike: { print("Upgrade to premium!") },
            isEnabled: false,
            isPremium: false,
            cooldownTimeRemaining: 0
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.1))
}