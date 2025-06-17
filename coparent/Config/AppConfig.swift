import Foundation

enum AppConfig {
    enum Sendbird {
        static let appId = "YOUR_APP_ID" // TODO: Replace with actual Sendbird App ID
        static let isLocalCachingEnabled = true
    }
    
    enum Chat {
        static let messagePageSize = 50
        static let maxMessageLength = 1000
        static let maxImageSize = 10 * 1024 * 1024 // 10MB
    }
    
    enum Filters {
        static let defaultAgeRangeMin: Double = 25
        static let defaultAgeRangeMax: Double = 45
        static let defaultMaxDistance: Double = 50
        static let maxFilterDistance: Double = 200
        static let minFilterDistance: Double = 5
        static let compatibilityThreshold: Double = 0.7
        static let maxSavedFilterSets = 5
        static let filterAnalyticsEnabled = true
        static let smartRecommendationsEnabled = true
        static let locationBasedNotifications = true
    }
    
    enum Matching {
        static let maxCompatibilityScore: Double = 100.0
        static let parentingStyleWeight: Double = 0.4
        static let interestOverlapWeight: Double = 0.3
        static let lifestyleWeight: Double = 0.2
        static let communicationStyleWeight: Double = 0.1
        static let minimumProfileCompletionForScoring: Double = 0.6
    }
    
    enum Location {
        static let defaultSearchRadius: Double = 50
        static let maxSearchRadius: Double = 500
        static let locationUpdateInterval: TimeInterval = 300 // 5 minutes
        static let travelModeRadius: Double = 100
        static let geocodingCacheTimeout: TimeInterval = 86400 // 24 hours
    }
}