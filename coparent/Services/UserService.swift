import Foundation
import FirebaseFirestore

class UserService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var cachedUsers: [String: User] = [:]
    
    func fetchUser(id: String) async throws -> User {
        // Check cache first
        if let cachedUser = cachedUsers[id] {
            return cachedUser
        }
        
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