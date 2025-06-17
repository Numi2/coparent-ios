import SwiftUI

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var name = ""
    @State private var age = 0
    @State private var gender = User.Child.Gender.preferNotToSay
    @State private var interests = ""
    
    private var isFormValid: Bool {
        !name.isEmpty && age > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    
                    Stepper("Age: \(age)", value: $age, in: 0...18)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(User.Child.Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue.capitalized)
                                .tag(gender)
                        }
                    }
                }
                
                Section("Interests") {
                    TextField(
                        "Interests (comma-separated)",
                        text: $interests,
                        axis: .vertical
                    )
                    .lineLimit(3...)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addChild()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func addChild() {
        let childInterests = interests
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        viewModel.addChild(
            name: name,
            age: age,
            gender: gender,
            interests: childInterests
        )
        
        dismiss()
    }
}

#Preview {
    AddChildView(
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