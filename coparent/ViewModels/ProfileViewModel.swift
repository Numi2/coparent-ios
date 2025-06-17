import Foundation
import SwiftUI
import PhotosUI

@Observable
class ProfileViewModel {
    private(set) var user: User
    private(set) var isLoading = false
    private(set) var error: Error?

    var selectedPhotos: [PhotosPickerItem] = []
    var profileImage: Image?

    init(user: User) {
        self.user = user
    }

    func updateProfile(
        name: String,
        bio: String,
        location: User.Location,
        parentingStyle: User.ParentingStyle,
        interests: [User.Interest]
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Update local user
            user.name = name
            user.bio = bio
            user.location = location
            user.parentingStyle = parentingStyle
            user.interests = interests

            // TODO: Implement API call to update profile
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulated network delay
        } catch {
            self.error = error
        }
    }

    func addChild(name: String, age: Int, gender: User.Child.Gender, interests: [String]) {
        let child = User.Child(
            id: UUID().uuidString,
            name: name,
            age: age,
            gender: gender,
            interests: interests
        )
        user.children.append(child)
    }

    func removeChild(at index: Int) {
        user.children.remove(at: index)
    }

    func updatePreferences(
        ageRange: ClosedRange<Int>,
        distance: Int,
        parentingStyles: [User.ParentingStyle],
        dealBreakers: [String]
    ) {
        user.preferences = User.Preferences(
            ageRange: ageRange,
            distance: distance,
            parentingStyles: parentingStyles,
            dealBreakers: dealBreakers
        )
    }

    func loadProfileImage() async {
        guard let item = selectedPhotos.first else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                    // TODO: Upload image to server and update profileImageURL
                }
            }
        } catch {
            self.error = error
        }
    }

    func requestVerification() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // TODO: Implement verification request
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulated network delay
            user.verificationStatus = .pending
        } catch {
            self.error = error
        }
    }
}
