import Foundation
import CoreLocation

@Observable
class MatchService {
    private(set) var potentialMatches: [User] = []
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
            await MainActor.run {
                potentialMatches = sortMatchesByDistance(matches)
            }
        } catch {
            self.error = error
        }
    }
    
    func like() async {
        guard !potentialMatches.isEmpty else { return }
        let match = potentialMatches[0]
        
        do {
            // TODO: Replace with actual API call
            try await Task.sleep(nanoseconds: 500_000_000) // Simulated network delay
            
            if Bool.random() { // Simulated match
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .newMatch,
                        object: nil,
                        userInfo: ["match": match]
                    )
                }
            }
            
            await MainActor.run {
                potentialMatches.removeFirst()
            }
        } catch {
            self.error = error
        }
    }
    
    func pass() {
        guard !potentialMatches.isEmpty else { return }
        potentialMatches.removeFirst()
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
                dateOfBirth: Date().addingTimeInterval(-32 * 365 * 24 * 60 * 60),
                profileImageURL: nil,
                bio: "Single mother looking for a co-parent. Love outdoor activities, cooking, and spending quality time with my daughter.",
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
                interests: [.outdoorActivities, .cooking, .music, .artsAndCrafts],
                verificationStatus: .verified
            ),
            User(
                id: "3",
                name: "Michael Johnson",
                userType: .singleParent,
                email: "michael@example.com",
                phoneNumber: "+1555123456",
                dateOfBirth: Date().addingTimeInterval(-29 * 365 * 24 * 60 * 60),
                profileImageURL: nil,
                bio: "Father of two who believes in balanced parenting. Work in tech but love outdoor adventures on weekends.",
                location: User.Location(
                    city: "Palo Alto",
                    state: "CA",
                    country: "USA",
                    coordinates: User.Location.Coordinates(latitude: 37.4419, longitude: -122.1430)
                ),
                parentingStyle: .authoritative,
                children: [
                    User.Child(id: "4", name: "Ethan", age: 8, gender: .male, interests: ["coding", "soccer"]),
                    User.Child(id: "5", name: "Lily", age: 5, gender: .female, interests: ["reading", "swimming"])
                ],
                preferences: User.Preferences(
                    ageRange: 25...40,
                    distance: 40,
                    parentingStyles: [.authoritative, .gentle],
                    dealBreakers: []
                ),
                interests: [.technology, .outdoorActivities, .sports, .education],
                verificationStatus: .verified
            ),
            User(
                id: "4",
                name: "Emily Chen",
                userType: .coParent,
                email: "emily@example.com",
                phoneNumber: "+1444987654",
                dateOfBirth: Date().addingTimeInterval(-31 * 365 * 24 * 60 * 60),
                profileImageURL: nil,
                bio: "Looking for a co-parenting partner to share the wonderful journey of raising children. Pediatric nurse who loves nature.",
                location: User.Location(
                    city: "Mountain View",
                    state: "CA",
                    country: "USA",
                    coordinates: User.Location.Coordinates(latitude: 37.3861, longitude: -122.0839)
                ),
                parentingStyle: .gentle,
                children: [],
                preferences: User.Preferences(
                    ageRange: 27...45,
                    distance: 35,
                    parentingStyles: [.gentle, .attachment],
                    dealBreakers: []
                ),
                interests: [.healthAndFitness, .nature, .reading, .communityService],
                verificationStatus: .verified
            ),
            User(
                id: "5",
                name: "David Rodriguez",
                userType: .singleParent,
                email: "david@example.com",
                phoneNumber: "+1333555777",
                dateOfBirth: Date().addingTimeInterval(-34 * 365 * 24 * 60 * 60),
                profileImageURL: nil,
                bio: "Single dad who loves cooking with my son and exploring new places. Looking for someone who values family time.",
                location: User.Location(
                    city: "Sunnyvale",
                    state: "CA",
                    country: "USA",
                    coordinates: User.Location.Coordinates(latitude: 37.3688, longitude: -122.0363)
                ),
                parentingStyle: .modern,
                children: [
                    User.Child(id: "6", name: "Diego", age: 7, gender: .male, interests: ["cooking", "photography"])
                ],
                preferences: User.Preferences(
                    ageRange: 28...40,
                    distance: 25,
                    parentingStyles: [.modern, .gentle],
                    dealBreakers: []
                ),
                interests: [.cooking, .travel, .music, .photography],
                verificationStatus: .verified
            )
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