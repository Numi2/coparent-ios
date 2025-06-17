import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ProfileViewModel
    @State private var showingEditProfile = false
    @State private var showingAddChild = false
    @State private var showingPreferences = false
    
    init(user: User) {
        _viewModel = State(initialValue: ProfileViewModel(user: user))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                
                Divider()
                
                aboutSection
                
                Divider()
                
                childrenSection
                
                Divider()
                
                preferencesSection
                
                Divider()
                
                verificationSection
            }
            .padding()
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditProfile = true
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingPreferences) {
            PreferencesView(viewModel: viewModel)
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $viewModel.selectedPhotos, maxSelectionCount: 1, matching: .images) {
                if let profileImage = viewModel.profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.gray)
                }
            }
            
            Text(viewModel.user.name)
                .font(.title2)
                .bold()
            
            Text(viewModel.user.userType.rawValue.capitalized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.title3)
                .bold()
            
            Text(viewModel.user.bio)
                .font(.body)
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                Text("\(viewModel.user.location.city), \(viewModel.user.location.state)")
            }
            .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "heart.circle.fill")
                Text("Parenting Style: \(viewModel.user.parentingStyle.rawValue.capitalized)")
            }
            .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(viewModel.user.interests, id: \.self) { interest in
                    Text(interest.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Children")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button(action: { showingAddChild = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            if viewModel.user.children.isEmpty {
                Text("No children added yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.user.children) { child in
                    ChildRow(child: child)
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Preferences")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button(action: { showingPreferences = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Age Range: \(viewModel.user.preferences.ageRange.lowerBound)-\(viewModel.user.preferences.ageRange.upperBound)")
                Text("Distance: \(viewModel.user.preferences.distance) km")
                Text("Parenting Styles: \(viewModel.user.preferences.parentingStyles.map { $0.rawValue.capitalized }.joined(separator: ", "))")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
    
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Verification")
                .font(.title3)
                .bold()
            
            switch viewModel.user.verificationStatus {
            case .unverified:
                Button("Request Verification") {
                    Task {
                        await viewModel.requestVerification()
                    }
                }
                .buttonStyle(.borderedProminent)
            case .pending:
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Verification Pending")
                }
                .foregroundStyle(.orange)
            case .verified:
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Verified")
                }
                .foregroundStyle(.green)
            case .rejected:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "xmark.seal.fill")
                        Text("Verification Rejected")
                    }
                    .foregroundStyle(.red)
                    
                    Button("Try Again") {
                        Task {
                            await viewModel.requestVerification()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct ChildRow: View {
    let child: User.Child
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                
                HStack {
                    Text("\(child.age) years old")
                    Text("•")
                    Text(child.gender.rawValue.capitalized)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if !child.interests.isEmpty {
                Text(child.interests.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = layout(sizes: sizes, proposal: proposal).positions
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: positions[index], proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (positions: [CGPoint], size: CGSize) {
        guard let width = proposal.width else { return ([], .zero) }
        
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            if currentX + size.width > width {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + rowHeight)
        }
        
        return (positions, CGSize(width: width, height: maxY))
    }
}

#Preview {
    NavigationStack {
        ProfileView(user: User(
            id: "1",
            name: "John Doe",
            userType: .singleParent,
            email: "john@example.com",
            phoneNumber: "+1234567890",
            dateOfBirth: Date(),
            profileImageURL: nil,
            bio: "Single father of two amazing kids. Love outdoor activities and cooking.",
            location: User.Location(city: "San Francisco", state: "CA", country: "USA"),
            parentingStyle: .authoritative,
            children: [
                User.Child(id: "1", name: "Emma", age: 8, gender: .female, interests: ["soccer", "art"]),
                User.Child(id: "2", name: "Liam", age: 5, gender: .male, interests: ["swimming", "music"])
            ],
            preferences: User.Preferences(
                ageRange: 30...45,
                distance: 50,
                parentingStyles: [.authoritative, .gentle],
                dealBreakers: ["Smoking", "Excessive drinking"]
            ),
            interests: [.outdoorActivities, .cooking, .sports],
            verificationStatus: .verified
        ))
    }
} 