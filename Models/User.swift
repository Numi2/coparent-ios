import Foundation

struct User: Identifiable, Codable {
    let id: String
    var name: String
    var userType: UserType
    var email: String?
    var phoneNumber: String?
    var dateOfBirth: Date
    var profileImageURL: URL?
    var bio: String
    var location: Location
    var parentingStyle: ParentingStyle
    var children: [Child]
    var preferences: Preferences
    var interests: [Interest]
    var verificationStatus: VerificationStatus
    
    // Computed properties for filtering and compatibility
    var profileCompletion: Double {
        var completionScore: Double = 0.0
        let totalFields: Double = 8.0
        
        // Basic required fields
        if !name.isEmpty { completionScore += 1.0 }
        if !bio.isEmpty { completionScore += 1.0 }
        if profileImageURL != nil { completionScore += 1.0 }
        if !children.isEmpty { completionScore += 1.0 }
        if !interests.isEmpty { completionScore += 1.0 }
        if verificationStatus == .verified { completionScore += 1.0 }
        if email != nil && !email!.isEmpty { completionScore += 1.0 }
        if phoneNumber != nil && !phoneNumber!.isEmpty { completionScore += 1.0 }
        
        return completionScore / totalFields
    }
    
    var interestStrings: [String] {
        interests.map { $0.rawValue }
    }
    
    struct Location: Codable {
        var city: String
        var state: String
        var country: String
        var coordinates: Coordinates?
        
        struct Coordinates: Codable {
            var latitude: Double
            var longitude: Double
        }
    }
    
    struct Child: Codable, Identifiable {
        let id: String
        var name: String
        var age: Int
        var gender: Gender
        var interests: [String]
        
        enum Gender: String, Codable {
            case male
            case female
            case other
            case preferNotToSay
        }
    }
    
    struct Preferences: Codable {
        var ageRange: ClosedRange<Int>
        var distance: Int // in kilometers
        var parentingStyles: [ParentingStyle]
        var dealBreakers: [String]
        
        enum CodingKeys: String, CodingKey {
            case ageRangeMin
            case ageRangeMax
            case distance
            case parentingStyles
            case dealBreakers
        }
        
        init(ageRange: ClosedRange<Int>, distance: Int, parentingStyles: [ParentingStyle], dealBreakers: [String]) {
            self.ageRange = ageRange
            self.distance = distance
            self.parentingStyles = parentingStyles
            self.dealBreakers = dealBreakers
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let min = try container.decode(Int.self, forKey: .ageRangeMin)
            let max = try container.decode(Int.self, forKey: .ageRangeMax)
            ageRange = min...max
            distance = try container.decode(Int.self, forKey: .distance)
            parentingStyles = try container.decode([ParentingStyle].self, forKey: .parentingStyles)
            dealBreakers = try container.decode([String].self, forKey: .dealBreakers)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(ageRange.lowerBound, forKey: .ageRangeMin)
            try container.encode(ageRange.upperBound, forKey: .ageRangeMax)
            try container.encode(distance, forKey: .distance)
            try container.encode(parentingStyles, forKey: .parentingStyles)
            try container.encode(dealBreakers, forKey: .dealBreakers)
        }
    }
    
    enum UserType: String, Codable {
        case singleParent
        case coParent
        case potentialCoParent
    }
    
    enum ParentingStyle: String, Codable, CaseIterable {
        case authoritative
        case permissive
        case authoritarian
        case uninvolved
        case attachment
        case gentle
        case freeRange
        case traditional
        case modern
        case eclectic
    }
    
    enum Interest: String, Codable, CaseIterable {
        case outdoorActivities
        case artsAndCrafts
        case sports
        case music
        case reading
        case cooking
        case travel
        case technology
        case nature
        case communityService
        case education
        case healthAndFitness
    }
    
    enum VerificationStatus: String, Codable {
        case unverified
        case pending
        case verified
        case rejected
    }
}