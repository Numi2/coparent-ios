import SwiftUI

struct SuperLikeView: View {
    let isVisible: Bool
    let onComplete: () -> Void
    
    @State private var animationPhase: CGFloat = 0
    @State private var particleAnimation: Bool = false
    @State private var scaleEffect: CGFloat = 0.5
    @State private var rotationEffect: Double = 0
    @State private var opacityEffect: Double = 0
    
    var body: some View {
        ZStack {
            // Star burst effect background
            if isVisible {
                starBurstEffect
                
                // Main super like indicator
                superLikeIndicator
            }
        }
        .onChange(of: isVisible) { visible in
            if visible {
                startAnimation()
            } else {
                resetAnimation()
            }
        }
    }
    
    @ViewBuilder
    private var starBurstEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                StarParticle(
                    angle: Double(index) * 45,
                    isAnimating: particleAnimation
                )
            }
        }
    }
    
    @ViewBuilder
    private var superLikeIndicator: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.6),
                            Color.blue.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .opacity(opacityEffect)
            
            // Main circle background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .scaleEffect(scaleEffect)
                .opacity(opacityEffect)
            
            // Star icon
            Image(systemName: "star.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(scaleEffect)
                .rotationEffect(.degrees(rotationEffect))
                .opacity(opacityEffect)
            
            // "SUPER LIKE" text
            VStack {
                Spacer()
                
                Text("SUPER LIKE")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .opacity(opacityEffect)
                    .offset(y: 100)
            }
        }
    }
    
    private func startAnimation() {
        // Start particle animation
        withAnimation(.easeOut(duration: 0.6)) {
            particleAnimation = true
        }
        
        // Start main indicator animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            scaleEffect = 1.0
            opacityEffect = 1.0
        }
        
        // Star rotation animation
        withAnimation(.easeInOut(duration: 0.8)) {
            rotationEffect = 360
        }
        
        // Complete the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                scaleEffect = 0.5
                opacityEffect = 0
                particleAnimation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }
    
    private func resetAnimation() {
        scaleEffect = 0.5
        opacityEffect = 0
        rotationEffect = 0
        particleAnimation = false
    }
}

struct StarParticle: View {
    let angle: Double
    let isAnimating: Bool
    
    @State private var particleOffset: CGFloat = 0
    @State private var particleOpacity: Double = 1
    @State private var particleScale: CGFloat = 1
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.yellow)
            .scaleEffect(particleScale)
            .opacity(particleOpacity)
            .offset(x: cos(angle * .pi / 180) * particleOffset,
                   y: sin(angle * .pi / 180) * particleOffset)
            .onChange(of: isAnimating) { animating in
                if animating {
                    startParticleAnimation()
                } else {
                    resetParticleAnimation()
                }
            }
    }
    
    private func startParticleAnimation() {
        withAnimation(.easeOut(duration: 0.8)) {
            particleOffset = 80
            particleOpacity = 0
            particleScale = 0.3
        }
    }
    
    private func resetParticleAnimation() {
        particleOffset = 0
        particleOpacity = 1
        particleScale = 1
    }
}

#Preview("Super Like Animation") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        SuperLikeView(isVisible: true) {
            print("Super like animation completed")
        }
    }
}

#Preview("Star Particle") {
    StarParticle(angle: 45, isAnimating: true)
        .padding(100)
}