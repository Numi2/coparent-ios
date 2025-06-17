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
                            "\(formatDistance(to: coordinates)) km away • "
                            + "\(user.location.city)"
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
                
                if abs(gesture.translation.width) > threshold && abs(dragAmount.width) <= threshold {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } else if abs(gesture.translation.height) > threshold && abs(dragAmount.height) <= threshold && canUseSuperLike {
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
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents(
            [.year],
            from: date,
            to: Date()
        )
        return ageComponents.year ?? 0
    }
    
    private func formatDistance(to coordinates: CLLocationCoordinate2D) -> Int {
        // TODO: Implement actual distance calculation
        return Int.random(in: 1...50)
    }
}

struct InterestTag: View {
    let interest: String
    
    var body: some View {
        Text(interest)
            .font(DesignSystem.Typography.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

struct CompatibilityIndicator: View {
    let score: Double
    
    private var scorePercentage: Int {
        Int(score)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0..<40:
            return .red
        case 40..<60:
            return .orange
        case 60..<80:
            return .yellow
        default:
            return .green
        }
    }
    
    private var compatibilityLevel: String {
        switch score {
        case 0..<40:
            return "Low"
        case 40..<60:
            return "Medium"
        case 60..<80:
            return "Good"
        default:
            return "Great"
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        LinearGradient(
                            colors: [scoreColor, scoreColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: score)
                
                Text("\(scorePercentage)")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(compatibilityLevel)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct ProfileDetailView: View {
    let user: User
    let onLike: () -> Void
    let onPass: () -> Void
    let onSuperLike: () -> Void
    let canUseSuperLike: Bool
    let isPremium: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    // Profile image
                    AsyncImage(url: user.profileImageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ZStack {
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
                    
                    // Profile details
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                        // Basic info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(user.name)
                                    .font(DesignSystem.Typography.largeTitle)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if user.verificationStatus == .verified {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                        Text("Verified")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Text("\(calculateAge(from: user.dateOfBirth)) years old")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(.secondary)
                            
                            if let coordinates = user.location.coordinates {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    Text("\(formatDistance(to: coordinates)) km away in \(user.location.city), \(user.location.state)")
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .glassCard()
                        
                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.semibold)
                            
                            Text(user.bio)
                                .font(DesignSystem.Typography.body)
                        }
                        .glassCard()
                        
                        // Parenting style
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parenting Style")
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text(user.parentingStyle.rawValue.capitalized)
                                    .font(DesignSystem.Typography.body)
                            }
                        }
                        .glassCard()
                        
                        // Children
                        if !user.children.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Children")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(user.children) { child in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(.blue.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(child.name.first ?? "?"))
                                                    .font(DesignSystem.Typography.headline)
                                                    .foregroundColor(.blue)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(child.name)
                                                .font(DesignSystem.Typography.callout)
                                                .fontWeight(.medium)
                                            
                                            Text("\(child.age) years old")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .glassCard()
                        }
                        
                        // Interests
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100, maximum: 150))
                            ], spacing: 8) {
                                ForEach(user.interests, id: \.self) { interest in
                                    InterestTag(interest: interest)
                                }
                            }
                        }
                        .glassCard()
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Action buttons
                HStack(spacing: DesignSystem.Layout.spacing) {
                    // Pass button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        onPass()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(.red)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Super Like button (if available)
                    if canUseSuperLike {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            onSuperLike()
                        }) {
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .background(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .disabled(!isPremium)
                        .opacity(isPremium ? 1.0 : 0.6)
                        
                        Spacer()
                    }
                    
                    // Like button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        onLike()
                    }) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
    
    private func formatDistance(to location: User.Location.Coordinates) -> String {
        // TODO: Implement actual distance calculation based on user's location
        return "\(Int.random(in: 1...25))"
    }
}

#Preview("Match Card") {
    MatchCardView(
        user: User(
            id: "1",
            name: "Sarah Smith",
            userType: .singleParent,
            email: "sarah@example.com",
            phoneNumber: "+1987654321",
            dateOfBirth: Date().addingTimeInterval(-30 * 365 * 24 * 60 * 60),
            profileImageURL: nil,
            bio: "Single mother looking for a co-parent. Love outdoor activities, cooking, and spending quality time with my daughter. Looking for someone who shares similar values and parenting philosophy.",
            location: User.Location(
                city: "San Jose",
                state: "CA",
                country: "USA",
                coordinates: User.Location.Coordinates(latitude: 37.3382, longitude: -121.8863)
            ),
            parentingStyle: .gentle,
            children: [
                User.Child(id: "1", name: "Sophia", age: 6, gender: .female, interests: ["dancing", "art"])
            ],
            preferences: User.Preferences(
                ageRange: 28...42,
                distance: 30,
                parentingStyles: [.gentle, .authoritative],
                dealBreakers: []
            ),
            interests: [.outdoorActivities, .cooking, .music, .reading, .artsAndCrafts],
            verificationStatus: .verified
        ),
        onLike: {},
        onPass: {},
        onSuperLike: {},
        canUseSuperLike: true,
        isPremium: true,
        superLikeCooldownTimeRemaining: 0,
        compatibilityScore: 0.85
    )
    .padding()
}

#Preview("Profile Detail") {
    ProfileDetailView(
        user: User(
            id: "1",
            name: "Sarah Smith",
            userType: .singleParent,
            email: "sarah@example.com",
            phoneNumber: "+1987654321",
            dateOfBirth: Date().addingTimeInterval(-30 * 365 * 24 * 60 * 60),
            profileImageURL: nil,
            bio: "Single mother looking for a co-parent. Love outdoor activities, cooking, and spending quality time with my daughter. Looking for someone who shares similar values and parenting philosophy.",
            location: User.Location(
                city: "San Jose",
                state: "CA",
                country: "USA",
                coordinates: User.Location.Coordinates(latitude: 37.3382, longitude: -121.8863)
            ),
            parentingStyle: .gentle,
            children: [
                User.Child(id: "1", name: "Sophia", age: 6, gender: .female, interests: ["dancing", "art"]),
                User.Child(id: "2", name: "Emma", age: 4, gender: .female, interests: ["music", "dancing"])
            ],
            preferences: User.Preferences(
                ageRange: 28...42,
                distance: 30,
                parentingStyles: [.gentle, .authoritative],
                dealBreakers: []
            ),
            interests: [.outdoorActivities, .cooking, .music, .reading, .artsAndCrafts, .healthAndFitness],
            verificationStatus: .verified
        ),
        onLike: {},
        onPass: {},
        onSuperLike: {},
        canUseSuperLike: true,
        isPremium: true
    )
} 