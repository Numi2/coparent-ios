import SwiftUI

struct MatchView: View {
    @Environment(AppState.self) private var appState
    @State private var matchService: MatchService
    @State private var showingMatchAlert = false
    @State private var matchedUser: User?
    
    init(user: User) {
        _matchService = State(initialValue: MatchService(currentUser: user))
    }
    
    var body: some View {
        ZStack {
            if matchService.isLoading {
                ProgressView()
            } else if let currentMatch = matchService.currentMatch {
                MatchCardView(
                    user: currentMatch,
                    onLike: {
                        Task {
                            await matchService.like()
                        }
                    },
                    onPass: {
                        matchService.pass()
                    }
                )
                .padding()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.gray)
                    
                    Text("No More Matches")
                        .font(.title2)
                        .bold()
                    
                    Text("Check back later for new potential matches")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("Discover")
        .task {
            await matchService.loadPotentialMatches()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newMatch)) { notification in
            if let match = notification.userInfo?["match"] as? User {
                matchedUser = match
                showingMatchAlert = true
            }
        }
        .alert("It's a Match! 🎉", isPresented: $showingMatchAlert) {
            Button("Start Chat") {
                // TODO: Navigate to chat
            }
            Button("Keep Swiping", role: .cancel) {}
        } message: {
            if let match = matchedUser {
                Text("You and \(match.name) have matched! Start a conversation now.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MatchView(user: User(
            id: "1",
            name: "John Doe",
            userType: .singleParent,
            email: "john@example.com",
            phoneNumber: "+1234567890",
            dateOfBirth: Date(),
            profileImageURL: nil,
            bio: "Single father of two amazing kids. Love outdoor activities and cooking.",
            location: User.Location(city: "San Francisco", state: "CA", country: "USA"),
            parentingStyle: .authoritative,
            children: [],
            preferences: User.Preferences(
                ageRange: 30...45,
                distance: 50,
                parentingStyles: [.authoritative, .gentle],
                dealBreakers: []
            ),
            interests: [.outdoorActivities, .cooking, .sports],
            verificationStatus: .verified
        ))
    }
} 