import Foundation
import CoreLocation

@Observable
class MatchService {
    private(set) var potentialMatches: [User] = []
    private(set) var currentMatch: User?
    private(set) var isLoading = false
    private(set) var error: Error?
    
    private let currentUser: User
    private let locationManager = CLLocationManager()
    
    init(currentUser: User) {
        self.currentUser = currentUser
    }
    
    func loadPotentialMatches() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Replace with actual API call
            let matches = try await fetchPotentialMatches()
            potentialMatches = sortMatchesByDistance(matches)
        } catch {
            self.error = error
        }
    }
    
    func like() async {
        guard let match = currentMatch else { return }
        
        do {
            // TODO: Replace with actual API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulated network delay
            
            if Bool.random() { // Simulated match
                NotificationCenter.default.post(
                    name: .newMatch,
                    object: nil,
                    userInfo: ["match": match]
                )
            }
            
            potentialMatches.removeAll { $0.id == match.id }
            currentMatch = potentialMatches.first
        } catch {
            self.error = error
        }
    }
    
    func pass() {
        guard let match = currentMatch else { return }
        potentialMatches.removeAll { $0.id == match.id }
        currentMatch = potentialMatches.first
    }
    
    private func fetchPotentialMatches() async throws -> [User] {
        // TODO: Replace with actual API call
        return [
            User(
                id: "2",
                name: "Sarah Smith",
                userType: .singleParent,
                email: "sarah@example.com",
                phoneNumber: "+1987654321",
                dateOfBirth: Date(),
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
                    User.Child(id: "3", name: "Sophia", age: 6, gender: .female, interests: ["dancing", "art"])
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
            // Add more mock users here
        ]
    }
    
    private func sortMatchesByDistance(_ matches: [User]) -> [User] {
        guard let currentLocation = currentUser.location.coordinates else {
            return matches
        }
        
        return matches.sorted { match1, match2 in
            guard let location1 = match1.location.coordinates,
                  let location2 = match2.location.coordinates else {
                return false
            }
            
            let distance1 = calculateDistance(
                from: currentLocation,
                to: location1
            )
            
            let distance2 = calculateDistance(
                from: currentLocation,
                to: location2
            )
            
            return distance1 < distance2
        }
    }
    
    private func calculateDistance(
        from location1: User.Location.Coordinates,
        to location2: User.Location.Coordinates
    ) -> CLLocationDistance {
        let location1 = CLLocation(
            latitude: location1.latitude,
            longitude: location1.longitude
        )
        
        let location2 = CLLocation(
            latitude: location2.latitude,
            longitude: location2.longitude
        )
        
        return location1.distance(from: location2)
    }
}

extension Notification.Name {
    static let newMatch = Notification.Name("newMatch")
} 