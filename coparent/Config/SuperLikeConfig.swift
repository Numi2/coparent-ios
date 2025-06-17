import Foundation

/// Configuration settings for Super Like feature
enum SuperLikeConfig {

    // MARK: - Daily Limits

    /// Maximum super likes per day for free users
    static let freeSuperLikesPerDay: Int = 1

    /// Maximum super likes per day for premium users
    static let premiumSuperLikesPerDay: Int = 5

    // MARK: - Cooldown Settings

    /// Cooldown period in hours before super likes refresh
    static let cooldownHours: Int = 24

    /// Grace period in minutes for super like refresh (allows slight timing variations)
    static let refreshGracePeriodMinutes: Int = 5

    // MARK: - Match Probability

    /// Enhanced match probability for free users using super like (60%)
    static let freeUserSuperLikeMatchProbability: Double = 0.6

    /// Enhanced match probability for premium users using super like (80%)
    static let premiumUserSuperLikeMatchProbability: Double = 0.8

    /// Regular like match probability for comparison (30%)
    static let regularLikeMatchProbability: Double = 0.3

    // MARK: - Animation Settings

    /// Duration for super like animation sequence
    static let animationDuration: Double = 1.8

    /// Number of star particles in burst effect
    static let particleCount: Int = 8

    /// Duration for star particle animation
    static let particleAnimationDuration: Double = 0.8

    /// Super like overlay fade duration
    static let overlayFadeDuration: Double = 0.3

    // MARK: - UI Configuration

    /// Swipe threshold for super like activation (vertical distance)
    static let superLikeSwipeThreshold: CGFloat = 100

    /// Super like button size for action bar
    static let buttonSize: CGFloat = 60

    /// Super like button size for floating overlay
    static let floatingButtonSize: CGFloat = 50

    // MARK: - Haptic Feedback

    /// Enable specialized haptic feedback for super likes
    static let enableHapticFeedback: Bool = true

    /// Haptic feedback intensity for super like activation
    static let hapticFeedbackStyle: HapticFeedbackStyle = .success

    // MARK: - Analytics

    /// Enable super like analytics tracking
    static let enableAnalytics: Bool = true

    /// Analytics event names
    enum AnalyticsEvents {
        static let superLikeUsed = "super_like_used"
        static let superLikeMatch = "super_like_match_success"
        static let superLikeNoMatch = "super_like_no_match"
        static let superLikeCooldownHit = "super_like_cooldown_reached"
        static let premiumUpgradePrompt = "super_like_premium_prompt_shown"
    }

    // MARK: - Storage Keys

    /// UserDefaults keys for persistence
    enum StorageKeys {
        static let superLikesRemaining = "superLikesRemaining"
        static let nextSuperLikeAvailable = "nextSuperLikeAvailable"
        static let lastSuperLikeRefresh = "lastSuperLikeRefresh"
        static let isPremiumUser = "isPremiumUser"
        static let totalSuperLikesUsed = "totalSuperLikesUsed"
        static let superLikeMatchCount = "superLikeMatchCount"
    }

    // MARK: - Premium Features

    /// Features exclusive to premium users
    enum PremiumFeatures {
        /// Enhanced super like animation effects
        static let enhancedAnimations: Bool = true

        /// Priority in match queue after super like
        static let matchQueuePriority: Bool = true

        /// See who super liked you
        static let showSuperLikeActivity: Bool = true

        /// Unlimited rewinds on super like mistakes
        static let unlimitedRewinds: Bool = true
    }

    // MARK: - Helper Types

    enum HapticFeedbackStyle {
        case light, medium, heavy, success, warning, error

        var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle? {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            default: return nil
            }
        }

        var notificationStyle: UINotificationFeedbackGenerator.FeedbackType? {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            default: return nil
            }
        }
    }
}

// MARK: - Development Configuration

#if DEBUG
extension SuperLikeConfig {
    /// Debug settings for testing
    enum Debug {
        /// Reduced cooldown for testing (5 minutes instead of 24 hours)
        static let testCooldownMinutes: Int = 5

        /// Increased match probability for testing
        static let testMatchProbability: Double = 0.9

        /// Enable debug logging
        static let enableDebugLogging: Bool = true

        /// Reset super likes on app launch for testing
        static let resetOnLaunch: Bool = false
    }
}
#endif
