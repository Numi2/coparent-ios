import SwiftUI

struct WelcomeStepView: View {
    @State private var animateContent = false
    @State private var animateFeatures = false

    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 2) {
            // Welcome Animation
            VStack(spacing: DesignSystem.Layout.spacing) {
                // Main illustration or animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(
                            DesignSystem.Animation.spring.delay(0.2),
                            value: animateContent
                        )

                    Image(systemName: "heart.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .animation(
                            DesignSystem.Animation.spring.delay(0.4),
                            value: animateContent
                        )
                }

                Text("Welcome to Co-Parent!")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(
                        DesignSystem.Animation.spring.delay(0.6),
                        value: animateContent
                    )

                Text("Let's create a profile that shows the real you and helps you find meaningful connections.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(
                        DesignSystem.Animation.spring.delay(0.8),
                        value: animateContent
                    )
            }

            // Features List
            VStack(spacing: DesignSystem.Layout.spacing) {
                ForEach(features.indices, id: \.self) { index in
                    FeatureRowView(
                        icon: features[index].icon,
                        title: features[index].title,
                        description: features[index].description
                    )
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(x: animateFeatures ? 0 : -30)
                    .animation(
                        DesignSystem.Animation.spring.delay(Double(index) * 0.1 + 1.0),
                        value: animateFeatures
                    )
                }
            }

            // Quick Tips
            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Quick Tips")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        TipView(text: "Be authentic - genuine profiles get more matches")
                        TipView(text: "Add multiple photos showing different sides of you")
                        TipView(text: "Write a bio that tells your story")
                    }
                }
            }
            .opacity(animateFeatures ? 1 : 0)
            .offset(y: animateFeatures ? 0 : 30)
            .animation(
                DesignSystem.Animation.spring.delay(1.5),
                value: animateFeatures
            )
        }
        .onAppear {
            animateContent = true
            animateFeatures = true
        }
    }

    private let features = [
        Feature(
            icon: "person.crop.circle.badge.plus",
            title: "Complete Profile",
            description: "Build a comprehensive profile that shows who you are"
        ),
        Feature(
            icon: "camera.circle.fill",
            title: "Photo Verification",
            description: "Verify your photos to build trust with other users"
        ),
        Feature(
            icon: "shield.checkered",
            title: "Safety First",
            description: "Multiple verification methods keep everyone safe"
        ),
        Feature(
            icon: "heart.circle.fill",
            title: "Find Connections",
            description: "Meet other co-parents who share your values"
        )
    ]
}

// MARK: - Supporting Views

struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .background(.ultraThinMaterial)
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)

                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct TipView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)

            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Supporting Types

struct Feature {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    WelcomeStepView()
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
