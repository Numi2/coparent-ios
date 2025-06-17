import SwiftUI

struct MatchCardView: View {
    let user: User
    let onLike: () -> Void
    let onPass: () -> Void
    let onSuperLike: () -> Void
    let canUseSuperLike: Bool
    let isPremium: Bool
    let superLikeCooldownTimeRemaining: TimeInterval
    let compatibilityScore: Double

    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var isShowingDetails = false
    @State private var dragAmount = CGSize.zero
    @State private var showingSuperLikeAnimation = false

    var body: some View {
        ZStack {
            // Main card
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )

            // Card content
            VStack(spacing: 0) {
                // Profile image section
                profileImageSection

                // Profile info section
                profileInfoSection
                    .padding(DesignSystem.Layout.padding)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))

            // Swipe feedback overlay
            swipeFeedbackOverlay

            // Super Like Button (bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    SuperLikeButton(
                        onSuperLike: {
                            showingSuperLikeAnimation = true
                        },
                        isEnabled: canUseSuperLike,
                        isPremium: isPremium,
                        cooldownTimeRemaining: superLikeCooldownTimeRemaining
                    )
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }

            // Super Like Animation Overlay
            SuperLikeView(isVisible: showingSuperLikeAnimation) {
                showingSuperLikeAnimation = false
                onSuperLike()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 600)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(isShowingDetails ? 0.95 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isShowingDetails)
        .gesture(swipeGesture)
        .onTapGesture {
            withAnimation(.spring()) {
                isShowingDetails = true
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            ProfileDetailView(
                user: user,
                onLike: onLike,
                onPass: onPass,
                onSuperLike: {
                    showingSuperLikeAnimation = true
                },
                canUseSuperLike: canUseSuperLike,
                isPremium: isPremium
            )
        }
    }

    @ViewBuilder
    private var profileImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Profile image
            AsyncImage(url: user.profileImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(height: 400)
            .clipped()

            // Compatibility Score (top-left)
            VStack {
                HStack {
                    CompatibilityIndicator(score: compatibilityScore)
                        .padding(12)

                    Spacer()
                }
                Spacer()
            }

            // Verification badge (top-right)
            if user.verificationStatus == .verified {
                VStack {
                    HStack {
                        Spacer()

                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(.white)
                            .clipShape(Circle())
                            .padding(12)
                    }
                    Spacer()
                }
            }

            // Age badge (bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    Text("\(calculateAge(from: user.dateOfBirth))")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(12)
                }
            }
        }
    }

    @ViewBuilder
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name and location
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)

                if let coordinates = user.location.coordinates {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(
                            "\(formatDistance(to: coordinates)) km away • " +
                            "\(user.location.city)"
                        )
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                    }
                }
            }

            // Bio preview
            Text(user.bio)
                .font(DesignSystem.Typography.body)
                .lineLimit(2)
                .foregroundColor(.primary)

            // Parenting style
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text(user.parentingStyle.rawValue.capitalized)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            // Interests preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(user.interests.prefix(3), id: \.self) { interest in
                        InterestTag(interest: interest)
                    }

                    if user.interests.count > 3 {
                        Text("+\(user.interests.count - 3) more")
                            .font(DesignSystem.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.2))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 2)
            }

            // Children preview
            if !user.children.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .foregroundColor(.orange)

                    if user.children.count == 1 {
                        Text("1 child")
                    } else {
                        Text("\(user.children.count) children")
                    }
                }
                .font(DesignSystem.Typography.callout)
                .foregroundColor(.primary)
            }
        }
    }

    @ViewBuilder
    private var swipeFeedbackOverlay: some View {
        // Super Like overlay (swipe up)
        if offset.height < -50 {
            VStack {
                HStack {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "star.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(min(abs(offset.height) / 150, 1.3))
                    .animation(.spring(), value: offset.height)

                    Spacer()
                }
                .padding(.top, 50)

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
                    .padding(.top, 16)

                Spacer()
            }
        }

        // Like overlay (swipe right)
        if offset.width > 50 {
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.9))
                            .frame(width: 80, height: 80)

                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(min(offset.width / 150, 1.2))
                    .animation(.spring(), value: offset.width)

                    Spacer()
                }
                Spacer()
            }
        }

        // Pass overlay (swipe left)
        if offset.width < -50 {
            VStack {
                Spacer()
                HStack {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.9))
                            .frame(width: 80, height: 80)

                        Image(systemName: "xmark")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(min(abs(offset.width) / 150, 1.2))
                    .animation(.spring(), value: offset.width)

                    Spacer()
                }
                Spacer()
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                offset = gesture.translation

                // Different rotation for vertical vs horizontal swipes
                if abs(gesture.translation.height) > abs(gesture.translation.width) {
                    // Vertical swipe - no rotation for super like
                    rotation = 0
                } else {
                    // Horizontal swipe - normal rotation
                    rotation = Double(gesture.translation.width / 20)
                }

                // Haptic feedback for swipe zones
                let threshold: CGFloat = 100

                if abs(gesture.translation.width) > threshold &&
                   abs(dragAmount.width) <= threshold {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } else if abs(gesture.translation.height) > threshold &&
                          abs(dragAmount.height) <= threshold && canUseSuperLike {
                    // Special haptic for super like
                    let impactFeedback = UINotificationFeedbackGenerator()
                    impactFeedback.notificationOccurred(.success)
                }

                dragAmount = gesture.translation
            }
            .onEnded { gesture in
                withAnimation(.spring()) {
                    let threshold: CGFloat = 100

                    // Check for super like (swipe up)
                    if gesture.translation.height < -threshold && canUseSuperLike {
                        showingSuperLikeAnimation = true
                        // Reset card position like other gesture endings
                        offset = .zero
                        rotation = 0
                    }
                    // Check for horizontal swipes
                    else if abs(gesture.translation.width) > threshold {
                        if gesture.translation.width > 0 {
                            onLike()
                        } else {
                            onPass()
                        }
                    } else {
                        // Return to center
                        offset = .zero
                        rotation = 0
                    }
                }
                dragAmount = .zero
            }
    }

}
