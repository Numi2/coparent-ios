import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var name: String
    @State private var bio: String
    @State private var city: String
    @State private var state: String
    @State private var selectedParentingStyle: User.ParentingStyle
    @State private var selectedInterests: Set<User.Interest>
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.user.name)
        _bio = State(initialValue: viewModel.user.bio)
        _city = State(initialValue: viewModel.user.location.city)
        _state = State(initialValue: viewModel.user.location.state)
        _selectedParentingStyle = State(initialValue: viewModel.user.parentingStyle)
        _selectedInterests = State(initialValue: Set(viewModel.user.interests))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Photo") {
                    PhotosPicker(
                        selection: $viewModel.selectedPhotos,
                        maxSelectionCount: 1,
                        matching: .images
                    ) {
                        if let profileImage = viewModel.profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(5...)
                }
                
                Section("Location") {
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                }
                
                Section("Parenting Style") {
                    Picker("Style", selection: $selectedParentingStyle) {
                        ForEach(User.ParentingStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized)
                                .tag(style)
                        }
                    }
                }
                
                Section("Interests") {
                    ForEach(User.Interest.allCases, id: \.self) { interest in
                        Toggle(
                            interest.rawValue.capitalized,
                            isOn: Binding(
                                get: { selectedInterests.contains(interest) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedInterests.insert(interest)
                                    } else {
                                        selectedInterests.remove(interest)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                }
            }
            .task(id: viewModel.selectedPhotos) {
                await viewModel.loadProfileImage()
            }
        }
    }
    
    private func saveChanges() async {
        let location = User.Location(
            city: city,
            state: state,
            country: viewModel.user.location.country,
            coordinates: viewModel.user.location.coordinates
        )
        
        await viewModel.updateProfile(
            name: name,
            bio: bio,
            location: location,
            parentingStyle: selectedParentingStyle,
            interests: Array(selectedInterests)
        )
        
        dismiss()
    }
}

#Preview {
    EditProfileView(
        viewModel: ProfileViewModel(
            user: User(
                id: "1",
                name: "John Doe",
                userType: .singleParent,
                email: "john@example.com",
                phoneNumber: "+1234567890",
                dateOfBirth: Date(),
                profileImageURL: nil,
                bio: "Single father of two amazing kids. "
                    + "Love outdoor activities and cooking.",
                location: User.Location(
                    city: "San Francisco",
                    state: "CA",
                    country: "USA"
                ),
                parentingStyle: .authoritative,
                children: [],
                preferences: User.Preferences(
                    ageRange: 30...45,
                    distance: 50,
                    parentingStyles: [.authoritative, .gentle],
                    dealBreakers: []
                ),
                interests: [.outdoorActivities, .cooking, .sports],
                verificationStatus: .verified
            )
        )
    )
} 