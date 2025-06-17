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
} 