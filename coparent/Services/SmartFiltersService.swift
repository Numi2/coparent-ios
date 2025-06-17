import Foundation
import CoreLocation
import CoreData

@Observable
class SmartFiltersService {
    static let shared = SmartFiltersService()
    
    // MARK: - Filter State
    private(set) var currentFilters = FilterSet()
    private(set) var savedFilterSets: [FilterSet] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    // MARK: - Smart Recommendations
    private(set) var smartRecommendations: [SmartRecommendation] = []
    private(set) var compatibilityInsights: CompatibilityInsights?
    
    // MARK: - Location Services
    private let locationManager = CLLocationManager()
    private(set) var currentLocation: CLLocation?
    private(set) var isLocationEnabled = false
    
    // MARK: - Analytics
    private var filterUsageAnalytics: [String: Any] = [:]
    private var userBehaviorData: UserBehaviorData = UserBehaviorData()
    
    private init() {
        loadSavedFilters()
        setupLocationServices()
        loadUserBehaviorData()
    }
    
    // MARK: - Filter Management
    
    @MainActor
    func updateFilter(_ filter: FilterSet) {
        currentFilters = filter
        generateSmartRecommendations()
        trackFilterUsage(filter)
        saveCurrentFilter()
    }
    
    @MainActor
    func resetFilters() {
        currentFilters = FilterSet()
        smartRecommendations.removeAll()
        saveCurrentFilter()
    }
    
    @MainActor
    func saveFilterSet(name: String) throws {
        guard savedFilterSets.count < AppConfig.Filters.maxSavedFilterSets else {
            throw FilterError.maxSavedFiltersReached
        }
        
        var filterToSave = currentFilters
        filterToSave.name = name
        filterToSave.id = UUID().uuidString
        filterToSave.createdAt = Date()
        
        savedFilterSets.append(filterToSave)
        saveToPersistence()
    }
    
    @MainActor
    func loadFilterSet(_ filterSet: FilterSet) {
        currentFilters = filterSet
        generateSmartRecommendations()
    }
    
    @MainActor
    func deleteFilterSet(_ filterSet: FilterSet) {
        savedFilterSets.removeAll { $0.id == filterSet.id }
        saveToPersistence()
    }
    
    // MARK: - Compatibility Scoring
    
    func calculateCompatibilityScore(for user: User, with currentUser: User) -> Double {
        guard user.profileCompletion >= AppConfig.Matching.minimumProfileCompletionForScoring else {
            return 0.0
        }
        
        var totalScore: Double = 0.0
        
        // Parenting style compatibility
        let parentingScore = calculateParentingStyleScore(user.parentingStyle, currentUser.parentingStyle)
        totalScore += parentingScore * AppConfig.Matching.parentingStyleWeight
        
        // Interest overlap
        let interestScore = calculateInterestOverlapScore(user.interestStrings, currentUser.interestStrings)
        totalScore += interestScore * AppConfig.Matching.interestOverlapWeight
        
        // Lifestyle compatibility
        let lifestyleScore = calculateLifestyleScore(user, currentUser)
        totalScore += lifestyleScore * AppConfig.Matching.lifestyleWeight
        
        // Communication style
        let communicationScore = calculateCommunicationScore(user, currentUser)
        totalScore += communicationScore * AppConfig.Matching.communicationStyleWeight
        
        return min(totalScore * AppConfig.Matching.maxCompatibilityScore, AppConfig.Matching.maxCompatibilityScore)
    }
    
    // MARK: - Smart Recommendations
    
    @MainActor
    private func generateSmartRecommendations() {
        guard AppConfig.Filters.smartRecommendationsEnabled else { return }
        
        smartRecommendations.removeAll()
        
        // Age range recommendations based on successful matches
        if let ageRecommendation = generateAgeRangeRecommendation() {
            smartRecommendations.append(ageRecommendation)
        }
        
        // Distance recommendations based on activity
        if let distanceRecommendation = generateDistanceRecommendation() {
            smartRecommendations.append(distanceRecommendation)
        }
        
        // Interest-based recommendations
        if let interestRecommendation = generateInterestRecommendation() {
            smartRecommendations.append(interestRecommendation)
        }
        
        // Location-based recommendations
        if let locationRecommendation = generateLocationRecommendation() {
            smartRecommendations.append(locationRecommendation)
        }
    }
    
    // MARK: - Location Services
    
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    @MainActor
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    @MainActor
    func updateLocation() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        locationManager.requestLocation()
    }
    
    // MARK: - Travel Mode
    
    @MainActor
    func enableTravelMode(location: CLLocation, duration: TimeInterval) {
        currentFilters.travelMode = TravelMode(
            isEnabled: true,
            location: location,
            radius: AppConfig.Location.travelModeRadius,
            endDate: Date().addingTimeInterval(duration)
        )
        saveCurrentFilter()
    }
    
    @MainActor
    func disableTravelMode() {
        currentFilters.travelMode = nil
        saveCurrentFilter()
    }
    
    // MARK: - Filter Analytics
    
    private func trackFilterUsage(_ filter: FilterSet) {
        guard AppConfig.Filters.filterAnalyticsEnabled else { return }
        
        let analytics: [String: Any] = [
            "age_range_min": filter.ageRange.lowerBound,
            "age_range_max": filter.ageRange.upperBound,
            "max_distance": filter.maxDistance,
            "parenting_styles_count": filter.selectedParentingStyles.count,
            "interests_count": filter.selectedInterests.count,
            "deal_breakers_count": filter.dealBreakers.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        filterUsageAnalytics = analytics
        // TODO: Send to analytics service
    }
    
    // MARK: - Persistence
    
    private func loadSavedFilters() {
        if let data = UserDefaults.standard.data(forKey: "savedFilterSets"),
           let filters = try? JSONDecoder().decode([FilterSet].self, from: data) {
            savedFilterSets = filters
        }
        
        if let data = UserDefaults.standard.data(forKey: "currentFilters"),
           let filters = try? JSONDecoder().decode(FilterSet.self, from: data) {
            currentFilters = filters
        }
    }
    
    private func saveCurrentFilter() {
        if let data = try? JSONEncoder().encode(currentFilters) {
            UserDefaults.standard.set(data, forKey: "currentFilters")
        }
    }
    
    private func saveToPersistence() {
        if let data = try? JSONEncoder().encode(savedFilterSets) {
            UserDefaults.standard.set(data, forKey: "savedFilterSets")
        }
    }
    
    private func loadUserBehaviorData() {
        if let data = UserDefaults.standard.data(forKey: "userBehaviorData"),
           let behavior = try? JSONDecoder().decode(UserBehaviorData.self, from: data) {
            userBehaviorData = behavior
        }
    }
    
    // MARK: - Machine Learning Recommendations
    
    private func generateAgeRangeRecommendation() -> SmartRecommendation? {
        let successfulMatches = userBehaviorData.successfulMatches
        guard !successfulMatches.isEmpty else { return nil }
        
        let ages = successfulMatches.compactMap { $0.age }
        let averageAge = ages.reduce(0, +) / Double(ages.count)
        let suggestedRange = (averageAge - 5)...(averageAge + 5)
        
        return SmartRecommendation(
            type: .ageRange,
            title: "Suggested Age Range",
            description: "Based on your successful matches, try \(Int(suggestedRange.lowerBound))-\(Int(suggestedRange.upperBound))",
            suggestedValue: suggestedRange,
            confidence: calculateConfidence(for: ages)
        )
    }
    
    private func generateDistanceRecommendation() -> SmartRecommendation? {
        let matches = userBehaviorData.successfulMatches
        guard !matches.isEmpty else { return nil }
        
        let distances = matches.compactMap { $0.distance }
        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        
        return SmartRecommendation(
            type: .distance,
            title: "Optimal Distance",
            description: "Most of your matches are within \(Int(averageDistance))km",
            suggestedValue: averageDistance,
            confidence: calculateConfidence(for: distances)
        )
    }
    
    private func generateInterestRecommendation() -> SmartRecommendation? {
        let interests = userBehaviorData.preferredInterests
        guard !interests.isEmpty else { return nil }
        
        return SmartRecommendation(
            type: .interests,
            title: "Popular Interests",
            description: "Include \(interests.prefix(3).joined(separator: ", ")) in your filters",
            suggestedValue: interests,
            confidence: 0.8
        )
    }
    
    private func generateLocationRecommendation() -> SmartRecommendation? {
        guard let location = currentLocation,
              isLocationEnabled else { return nil }
        
        return SmartRecommendation(
            type: .location,
            title: "Nearby Matches",
            description: "There are more active users in your current area",
            suggestedValue: location,
            confidence: 0.7
        )
    }
    
    // MARK: - Compatibility Calculation Helpers
    
    private func calculateParentingStyleScore(_ style1: User.ParentingStyle, _ style2: User.ParentingStyle) -> Double {
        // Define compatibility matrix for parenting styles
        let compatibilityMatrix: [User.ParentingStyle: [User.ParentingStyle: Double]] = [
            .authoritative: [
                .authoritative: 1.0, .permissive: 0.7, .authoritarian: 0.3, .uninvolved: 0.1,
                .attachment: 0.8, .gentle: 0.9, .freeRange: 0.5, .traditional: 0.6,
                .modern: 0.8, .eclectic: 0.7
            ],
            .permissive: [
                .permissive: 1.0, .authoritative: 0.7, .authoritarian: 0.2, .uninvolved: 0.4,
                .attachment: 0.6, .gentle: 0.8, .freeRange: 0.9, .traditional: 0.3,
                .modern: 0.7, .eclectic: 0.8
            ],
            .authoritarian: [
                .authoritarian: 1.0, .authoritative: 0.3, .permissive: 0.2, .uninvolved: 0.1,
                .attachment: 0.2, .gentle: 0.1, .freeRange: 0.1, .traditional: 0.8,
                .modern: 0.2, .eclectic: 0.3
            ],
            .uninvolved: [
                .uninvolved: 1.0, .permissive: 0.4, .authoritative: 0.1, .authoritarian: 0.1,
                .attachment: 0.1, .gentle: 0.2, .freeRange: 0.3, .traditional: 0.2,
                .modern: 0.3, .eclectic: 0.4
            ],
            .attachment: [
                .attachment: 1.0, .authoritative: 0.8, .gentle: 0.9, .permissive: 0.6,
                .authoritarian: 0.2, .uninvolved: 0.1, .freeRange: 0.4, .traditional: 0.5,
                .modern: 0.8, .eclectic: 0.7
            ],
            .gentle: [
                .gentle: 1.0, .attachment: 0.9, .authoritative: 0.9, .permissive: 0.8,
                .authoritarian: 0.1, .uninvolved: 0.2, .freeRange: 0.6, .traditional: 0.4,
                .modern: 0.8, .eclectic: 0.8
            ],
            .freeRange: [
                .freeRange: 1.0, .permissive: 0.9, .authoritative: 0.5, .gentle: 0.6,
                .attachment: 0.4, .authoritarian: 0.1, .uninvolved: 0.3, .traditional: 0.2,
                .modern: 0.7, .eclectic: 0.8
            ],
            .traditional: [
                .traditional: 1.0, .authoritarian: 0.8, .authoritative: 0.6, .attachment: 0.5,
                .permissive: 0.3, .gentle: 0.4, .freeRange: 0.2, .uninvolved: 0.2,
                .modern: 0.4, .eclectic: 0.5
            ],
            .modern: [
                .modern: 1.0, .authoritative: 0.8, .gentle: 0.8, .attachment: 0.8,
                .permissive: 0.7, .freeRange: 0.7, .traditional: 0.4, .authoritarian: 0.2,
                .uninvolved: 0.3, .eclectic: 0.9
            ],
            .eclectic: [
                .eclectic: 1.0, .modern: 0.9, .authoritative: 0.7, .gentle: 0.8,
                .permissive: 0.8, .attachment: 0.7, .freeRange: 0.8, .traditional: 0.5,
                .authoritarian: 0.3, .uninvolved: 0.4
            ]
        ]
        
        return compatibilityMatrix[style1]?[style2] ?? 0.5 // Default moderate compatibility
    }
    
    private func calculateInterestOverlapScore(_ interests1: [String], _ interests2: [String]) -> Double {
        let set1 = Set(interests1)
        let set2 = Set(interests2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
    
    private func calculateLifestyleScore(_ user1: User, _ user2: User) -> Double {
        // Placeholder for lifestyle compatibility
        // Would include factors like activity level, social preferences, etc.
        return 0.7
    }
    
    private func calculateCommunicationScore(_ user1: User, _ user2: User) -> Double {
        // Placeholder for communication style compatibility
        // Would analyze messaging patterns, response times, etc.
        return 0.8
    }
    
    private func calculateConfidence(for values: [Double]) -> Double {
        guard values.count > 1 else { return 0.5 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = higher confidence
        return max(0.3, min(1.0, 1.0 - (standardDeviation / mean)))
    }
}

// MARK: - CLLocationManagerDelegate

extension SmartFiltersService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            generateSmartRecommendations()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            isLocationEnabled = status == .authorizedWhenInUse || status == .authorizedAlways
            
            if isLocationEnabled {
                updateLocation()
            }
        }
    }
}

// MARK: - Supporting Types

struct FilterSet: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String?
    var ageRange: ClosedRange<Double> = AppConfig.Filters.defaultAgeRangeMin...AppConfig.Filters.defaultAgeRangeMax
    var maxDistance: Double = AppConfig.Filters.defaultMaxDistance
    var selectedParentingStyles: Set<User.ParentingStyle> = []
    var selectedInterests: Set<String> = []
    var dealBreakers: Set<DealBreaker> = []
    var isVerifiedOnly: Bool = false
    var hasPhotosOnly: Bool = true
    var minimumCompatibilityScore: Double = AppConfig.Filters.compatibilityThreshold
    var travelMode: TravelMode?
    var createdAt: Date = Date()
    var lastUsed: Date = Date()
    
    // Custom encoding for ClosedRange
    enum CodingKeys: String, CodingKey {
        case id, name, maxDistance, selectedParentingStyles, selectedInterests
        case dealBreakers, isVerifiedOnly, hasPhotosOnly, minimumCompatibilityScore
        case travelMode, createdAt, lastUsed
        case ageRangeMin, ageRangeMax
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        maxDistance = try container.decode(Double.self, forKey: .maxDistance)
        selectedParentingStyles = try container.decode(Set<User.ParentingStyle>.self, forKey: .selectedParentingStyles)
        selectedInterests = try container.decode(Set<String>.self, forKey: .selectedInterests)
        dealBreakers = try container.decode(Set<DealBreaker>.self, forKey: .dealBreakers)
        isVerifiedOnly = try container.decode(Bool.self, forKey: .isVerifiedOnly)
        hasPhotosOnly = try container.decode(Bool.self, forKey: .hasPhotosOnly)
        minimumCompatibilityScore = try container.decode(Double.self, forKey: .minimumCompatibilityScore)
        travelMode = try container.decodeIfPresent(TravelMode.self, forKey: .travelMode)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUsed = try container.decode(Date.self, forKey: .lastUsed)
        
        let ageMin = try container.decode(Double.self, forKey: .ageRangeMin)
        let ageMax = try container.decode(Double.self, forKey: .ageRangeMax)
        ageRange = ageMin...ageMax
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(maxDistance, forKey: .maxDistance)
        try container.encode(selectedParentingStyles, forKey: .selectedParentingStyles)
        try container.encode(selectedInterests, forKey: .selectedInterests)
        try container.encode(dealBreakers, forKey: .dealBreakers)
        try container.encode(isVerifiedOnly, forKey: .isVerifiedOnly)
        try container.encode(hasPhotosOnly, forKey: .hasPhotosOnly)
        try container.encode(minimumCompatibilityScore, forKey: .minimumCompatibilityScore)
        try container.encodeIfPresent(travelMode, forKey: .travelMode)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastUsed, forKey: .lastUsed)
        try container.encode(ageRange.lowerBound, forKey: .ageRangeMin)
        try container.encode(ageRange.upperBound, forKey: .ageRangeMax)
    }
}

struct TravelMode: Codable, Equatable {
    let isEnabled: Bool
    let location: CLLocation
    let radius: Double
    let endDate: Date
    
    enum CodingKeys: String, CodingKey {
        case isEnabled, radius, endDate
        case latitude, longitude
    }
    
    init(isEnabled: Bool, location: CLLocation, radius: Double, endDate: Date) {
        self.isEnabled = isEnabled
        self.location = location
        self.radius = radius
        self.endDate = endDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        radius = try container.decode(Double.self, forKey: .radius)
        endDate = try container.decode(Date.self, forKey: .endDate)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(radius, forKey: .radius)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(location.coordinate.latitude, forKey: .latitude)
        try container.encode(location.coordinate.longitude, forKey: .longitude)
    }
}

enum DealBreaker: String, CaseIterable, Codable {
    case smoking
    case drinking
    case pets
    case religion
    case politics
    case moreChildren
    case longDistance
    case differentParentingStyle
}

struct SmartRecommendation: Identifiable, Equatable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let suggestedValue: Any
    let confidence: Double
    
    enum RecommendationType {
        case ageRange
        case distance
        case interests
        case location
        case parentingStyle
    }
    
    static func == (lhs: SmartRecommendation, rhs: SmartRecommendation) -> Bool {
        lhs.id == rhs.id
    }
}

struct CompatibilityInsights: Codable {
    let averageScore: Double
    let topFactors: [CompatibilityFactor]
    let improvementSuggestions: [String]
    let lastUpdated: Date
}

struct CompatibilityFactor: Codable {
    let name: String
    let score: Double
    let weight: Double
    let description: String
}

struct UserBehaviorData: Codable {
    var successfulMatches: [MatchAnalytics] = []
    var preferredInterests: [String] = []
    var averageResponseTime: TimeInterval = 0
    var mostActiveTimeOfDay: Int = 12
    var preferredAgeRange: ClosedRange<Double> = 25...45
    var preferredDistance: Double = 50
    
    enum CodingKeys: String, CodingKey {
        case successfulMatches, preferredInterests, averageResponseTime
        case mostActiveTimeOfDay, preferredDistance
        case preferredAgeRangeMin, preferredAgeRangeMax
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        successfulMatches = try container.decode([MatchAnalytics].self, forKey: .successfulMatches)
        preferredInterests = try container.decode([String].self, forKey: .preferredInterests)
        averageResponseTime = try container.decode(TimeInterval.self, forKey: .averageResponseTime)
        mostActiveTimeOfDay = try container.decode(Int.self, forKey: .mostActiveTimeOfDay)
        preferredDistance = try container.decode(Double.self, forKey: .preferredDistance)
        
        let ageMin = try container.decode(Double.self, forKey: .preferredAgeRangeMin)
        let ageMax = try container.decode(Double.self, forKey: .preferredAgeRangeMax)
        preferredAgeRange = ageMin...ageMax
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(successfulMatches, forKey: .successfulMatches)
        try container.encode(preferredInterests, forKey: .preferredInterests)
        try container.encode(averageResponseTime, forKey: .averageResponseTime)
        try container.encode(mostActiveTimeOfDay, forKey: .mostActiveTimeOfDay)
        try container.encode(preferredDistance, forKey: .preferredDistance)
        try container.encode(preferredAgeRange.lowerBound, forKey: .preferredAgeRangeMin)
        try container.encode(preferredAgeRange.upperBound, forKey: .preferredAgeRangeMax)
    }
}

struct MatchAnalytics: Codable, Identifiable {
    let id = UUID()
    let userId: String
    let age: Double?
    let distance: Double?
    let interests: [String]
    let parentingStyle: User.ParentingStyle
    let matchDate: Date
    let conversationStarted: Bool
    let responseTime: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case userId, age, distance, interests, parentingStyle
        case matchDate, conversationStarted, responseTime
    }
}

enum FilterError: LocalizedError {
    case maxSavedFiltersReached
    case invalidFilterConfiguration
    case locationPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .maxSavedFiltersReached:
            return "Maximum number of saved filter sets reached"
        case .invalidFilterConfiguration:
            return "Invalid filter configuration"
        case .locationPermissionDenied:
            return "Location permission is required for location-based filtering"
        }
    }
}
