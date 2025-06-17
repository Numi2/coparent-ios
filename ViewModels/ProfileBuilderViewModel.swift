import Foundation
import SwiftUI
import PhotosUI

@Observable
class ProfileBuilderViewModel {
    // MARK: - Basic Info
    var name: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var userType: User.UserType = .singleParent
    
    // MARK: - Location
    var city: String = ""
    var state: String = ""
    var country: String = "USA"
    
    // MARK: - Photos
    var selectedPhotos: [PhotosPickerItem] = []
    var profileImages: [UIImage] = []
    var mainPhotoIndex: Int = 0
    
    // MARK: - About You
    var bio: String = ""
    var parentingStyle: User.ParentingStyle = .authoritative
    var profession: String = ""
    var education: String = ""
    
    // MARK: - Children
    var children: [ChildData] = []
    
    // MARK: - Interests
    var selectedInterests: Set<User.Interest> = []
    
    // MARK: - Preferences
    var ageRange: ClosedRange<Int> = 25...45
    var maxDistance: Int = 50
    var preferredParentingStyles: Set<User.ParentingStyle> = []
    var dealBreakers: [String] = []
    
    // MARK: - State
    private(set) var isLoading = false
    private(set) var error: Error?
    
    // MARK: - Validation Properties
    
    var isBasicInfoComplete: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email) &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasMainPhoto: Bool {
        !profileImages.isEmpty
    }
    
    var isAboutYouComplete: Bool {
        !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        bio.count >= 50 // Minimum bio length
    }
    
    var hasSelectedInterests: Bool {
        selectedInterests.count >= 3 // Minimum 3 interests
    }
    
    var isPreferencesComplete: Bool {
        !preferredParentingStyles.isEmpty
    }
    
    var profileCompletion: Double {
        var completionScore: Double = 0.0
        let totalSteps: Double = 6.0 // Main required steps
        
        if isBasicInfoComplete { completionScore += 1.0 }
        if hasMainPhoto { completionScore += 1.0 }
        if isAboutYouComplete { completionScore += 1.0 }
        if !children.isEmpty { completionScore += 1.0 }
        if hasSelectedInterests { completionScore += 1.0 }
        if isPreferencesComplete { completionScore += 1.0 }
        
        return completionScore / totalSteps
    }
    
    // MARK: - Photo Management
    
    func loadProfileImages() async {
        guard !selectedPhotos.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var loadedImages: [UIImage] = []
        
        for item in selectedPhotos {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
        
        await MainActor.run {
            self.profileImages = loadedImages
        }
    }
    
    func reorderPhotos(from source: IndexSet, to destination: Int) {
        profileImages.move(fromOffsets: source, toOffset: destination)
        
        // Update main photo index if needed
        if source.contains(mainPhotoIndex) {
            mainPhotoIndex = destination > mainPhotoIndex ? destination - 1 : destination
        }
    }
    
    func removePhoto(at index: Int) {
        profileImages.remove(at: index)
        
        // Update main photo index if needed
        if mainPhotoIndex >= profileImages.count {
            mainPhotoIndex = max(0, profileImages.count - 1)
        }
    }
    
    func setMainPhoto(at index: Int) {
        guard index < profileImages.count else { return }
        mainPhotoIndex = index
    }
    
    // MARK: - Children Management
    
    func addChild(name: String, age: Int, gender: User.Child.Gender, interests: [String]) {
        let child = ChildData(
            id: UUID().uuidString,
            name: name,
            age: age,
            gender: gender,
            interests: interests
        )
        children.append(child)
    }
    
    func removeChild(at index: Int) {
        guard index < children.count else { return }
        children.remove(at: index)
    }
    
    func updateChild(at index: Int, name: String, age: Int, gender: User.Child.Gender, interests: [String]) {
        guard index < children.count else { return }
        children[index] = ChildData(
            id: children[index].id,
            name: name,
            age: age,
            gender: gender,
            interests: interests
        )
    }
    
    // MARK: - Interest Management
    
    func toggleInterest(_ interest: User.Interest) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    func addCustomInterest(_ interest: String) {
        // In a real app, you might add custom interests to a separate array
        // For now, we'll work with the predefined interests
    }
    
    // MARK: - Preference Management
    
    func toggleParentingStyle(_ style: User.ParentingStyle) {
        if preferredParentingStyles.contains(style) {
            preferredParentingStyles.remove(style)
        } else {
            preferredParentingStyles.insert(style)
        }
    }
    
    func addDealBreaker(_ dealBreaker: String) {
        let trimmed = dealBreaker.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !dealBreakers.contains(trimmed) {
            dealBreakers.append(trimmed)
        }
    }
    
    func removeDealBreaker(at index: Int) {
        guard index < dealBreakers.count else { return }
        dealBreakers.remove(at: index)
    }
    
    // MARK: - Profile Creation
    
    func createProfile() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate required fields
        guard isBasicInfoComplete else {
            throw ProfileCreationError.incompleteBasicInfo
        }
        
        guard hasMainPhoto else {
            throw ProfileCreationError.noPhotos
        }
        
        guard isAboutYouComplete else {
            throw ProfileCreationError.incompleteAboutYou
        }
        
        guard hasSelectedInterests else {
            throw ProfileCreationError.noInterests
        }
        
        // Create User object
        let user = User(
            id: UUID().uuidString,
            name: name,
            userType: userType,
            email: email,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            dateOfBirth: dateOfBirth,
            profileImageURL: nil, // Will be set after uploading photos
            bio: bio,
            location: User.Location(
                city: city,
                state: state,
                country: country,
                coordinates: nil // Will be geocoded later
            ),
            parentingStyle: parentingStyle,
            children: children.map { childData in
                User.Child(
                    id: childData.id,
                    name: childData.name,
                    age: childData.age,
                    gender: childData.gender,
                    interests: childData.interests
                )
            },
            preferences: User.Preferences(
                ageRange: ageRange,
                distance: maxDistance,
                parentingStyles: Array(preferredParentingStyles),
                dealBreakers: dealBreakers
            ),
            interests: Array(selectedInterests),
            verificationStatus: .unverified
        )
        
        // Simulate profile creation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // TODO: Implement actual profile creation logic
        // - Upload photos to cloud storage
        // - Create user profile in database
        // - Send verification emails/SMS
        // - Update local user state
    }
    
    // MARK: - Smart Suggestions
    
    func getInterestSuggestions() -> [User.Interest] {
        // Return interests not yet selected
        let allInterests = Set(User.Interest.allCases)
        let remaining = allInterests.subtracting(selectedInterests)
        return Array(remaining).shuffled().prefix(5).map { $0 }
    }
    
    func getParentingStyleSuggestions() -> [User.ParentingStyle] {
        // Return compatible parenting styles based on selected ones
        let allStyles = Set(User.ParentingStyle.allCases)
        let remaining = allStyles.subtracting(preferredParentingStyles)
        return Array(remaining).shuffled().prefix(3).map { $0 }
    }
    
    // MARK: - Utility Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func reset() {
        name = ""
        email = ""
        phoneNumber = ""
        city = ""
        state = ""
        bio = ""
        profession = ""
        education = ""
        selectedPhotos = []
        profileImages = []
        children = []
        selectedInterests = []
        preferredParentingStyles = []
        dealBreakers = []
        mainPhotoIndex = 0
        error = nil
    }
}

// MARK: - Supporting Types

struct ChildData: Identifiable, Codable {
    let id: String
    var name: String
    var age: Int
    var gender: User.Child.Gender
    var interests: [String]
}

enum ProfileCreationError: LocalizedError {
    case incompleteBasicInfo
    case noPhotos
    case incompleteAboutYou
    case noInterests
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .incompleteBasicInfo:
            return "Please complete all basic information fields"
        case .noPhotos:
            return "Please add at least one photo"
        case .incompleteAboutYou:
            return "Please write a bio of at least 50 characters"
        case .noInterests:
            return "Please select at least 3 interests"
        case .networkError:
            return "Network connection error"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}