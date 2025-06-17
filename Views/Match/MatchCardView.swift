import SwiftUI

struct MatchCardView: View {
    let user: User
    let onLike: () -> Void
    let onPass: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(radius: 10)
            
            VStack(spacing: 0) {
                if let profileImage = user.profileImageURL {
                    AsyncImage(url: profileImage) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(height: 400)
                    .clipped()
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 400)
                        .foregroundStyle(.gray)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(user.name)
                            .font(.title)
                            .bold()
                        
                        Text("\(calculateAge(from: user.dateOfBirth))")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let location = user.location.coordinates {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                            Text("\(formatDistance(to: location)) km away")
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(user.bio)
                        .font(.body)
                        .lineLimit(3)
                    
                    HStack {
                        ForEach(user.interests.prefix(3), id: \.self) { interest in
                            Text(interest.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if !user.children.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Children")
                                .font(.headline)
                            
                            ForEach(user.children) { child in
                                HStack {
                                    Text(child.name)
                                        .font(.subheadline)
                                    
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(child.age) years old")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .offset(x: offset.width, y: 0)
        .rotationEffect(.degrees(Double(offset.width / 40)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    withAnimation {
                        color = offset.width > 0 ? .green : .red
                    }
                }
                .onEnded { _ in
                    withAnimation {
                        swipeCard(width: offset.width)
                    }
                }
        )
    }
    
    private func swipeCard(width: CGFloat) {
        switch width {
        case -500...(-150):
            offset = CGSize(width: -500, height: 0)
            onPass()
        case 150...500:
            offset = CGSize(width: 500, height: 0)
            onLike()
        default:
            offset = .zero
        }
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
    
    private func formatDistance(to location: User.Location.Coordinates) -> String {
        // TODO: Implement actual distance calculation
        return "5"
    }
}

#Preview {
    MatchCardView(
        user: User(
            id: "1",
            name: "Sarah Smith",
            userType: .singleParent,
            email: "sarah@example.com",
            phoneNumber: "+1987654321",
            dateOfBirth: Date().addingTimeInterval(-30 * 365 * 24 * 60 * 60),
            profileImageURL: nil,
            bio: "Single mother looking for a co-parent. Love outdoor activities and cooking.",
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
            interests: [.outdoorActivities, .cooking, .music],
            verificationStatus: .verified
        ),
        onLike: {},
        onPass: {}
    )
    .frame(height: 600)
    .padding()
} 