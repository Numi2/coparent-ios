import SwiftUI

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
                    .frame(height: 300)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: DesignSystem.Layout.cornerRadius
                        )
                    )

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
                                    Text(
                                        "\(formatDistance(to: coordinates)) km away " +
                                        "in \(user.location.city), \(user.location.state)"
                                    )
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
            bio: "Single mother looking for a co-parent. Love outdoor activities, " +
                 "cooking, and spending quality time with my daughter. Looking for " +
                 "someone who shares similar values and parenting philosophy.",
            location: User.Location(
                city: "San Jose",
                state: "CA",
                country: "USA",
                coordinates: User.Location.Coordinates(
                    latitude: 37.3382,
                    longitude: -121.8863
                )
            ),
            parentingStyle: .gentle,
            children: [
                User.Child(
                    id: "1",
                    name: "Sophia",
                    age: 6,
                    gender: .female,
                    interests: ["dancing", "art"]
                ),
                User.Child(
                    id: "2",
                    name: "Emma",
                    age: 4,
                    gender: .female,
                    interests: ["music", "dancing"]
                )
            ],
            preferences: User.Preferences(
                ageRange: 28...42,
                distance: 30,
                parentingStyles: [.gentle, .authoritative],
                dealBreakers: []
            ),
            interests: [
                .outdoorActivities, .cooking, .music, .reading,
                .artsAndCrafts, .healthAndFitness
            ],
            verificationStatus: .verified
        ),
        onLike: {},
        onPass: {},
        onSuperLike: {},
        canUseSuperLike: true,
        isPremium: true
    )
}
