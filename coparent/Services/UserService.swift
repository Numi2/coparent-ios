import Foundation
#if false // TODO: Re-enable when Firebase is added
import FirebaseFirestore
#endif

class UserService: ObservableObject {
    #if false // TODO: Re-enable when Firebase is added
    private let db = Firestore.firestore()
    #endif
    @Published var cachedUsers: [String: User] = [:]
    
    func fetchUser(id: String) async throws -> User {
        // Check cache first
        if let cachedUser = cachedUsers[id] {
            return cachedUser
        }
        
        #if false // TODO: Re-enable when Firebase is added
        // Fetch from Firestore
        let document = try await db.collection("users").document(id).getDocument()
        guard let user = try? document.data(as: User.self) else {
            throw NSError(
                domain: "UserService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not found"]
            )
        }
        
        // Cache the user
        await MainActor.run {
            cachedUsers[id] = user
        }
        
        return user
        #else
        // Mock implementation for testing
        let mockUser = User(
            id: id,
            name: "Mock User",
            userType: .singleParent,
            email: "mock@example.com",
            phoneNumber: "+1234567890",
            dateOfBirth: Date().addingTimeInterval(-30 * 365 * 24 * 60 * 60),
            profileImageURL: nil,
            bio: "Mock user for testing",
            location: User.Location(city: "Mock City", state: "MC", country: "USA", coordinates: nil),
            parentingStyle: .gentle,
            children: [],
            preferences: User.Preferences(ageRange: 25...45, distance: 50, parentingStyles: [.gentle], dealBreakers: []),
            interests: [.cooking],
            verificationStatus: .verified
        )
        
        await MainActor.run {
            cachedUsers[id] = mockUser
        }
        
        return mockUser
        #endif
    }
    
    func fetchUsers(ids: [String]) async throws -> [User] {
        var users: [User] = []
        
        for id in ids {
            do {
                let user = try await fetchUser(id: id)
                users.append(user)
            } catch {
                print("Failed to fetch user \(id): \(error)")
            }
        }
        
        return users
    }
    
    func clearCache() {
        cachedUsers.removeAll()
    }
} 
