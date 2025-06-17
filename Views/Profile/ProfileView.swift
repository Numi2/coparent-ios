import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    @State private var showingAddChild = false
    @State private var showingPreferences = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Layout.spacing * 2) {
                // Profile Header
                VStack(spacing: DesignSystem.Layout.spacing) {
                    // Profile Image
                    Button(action: { showingImagePicker = true }) {
                        if let image = viewModel.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                                )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .glassCard()
                    
                    // Name and Location
                    VStack(spacing: DesignSystem.Layout.spacing / 2) {
                        Text(viewModel.name)
                            .font(DesignSystem.Typography.title2)
                        
                        Text(viewModel.location)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .glassCard()
                
                // About Me
                GlassCardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                        Text("About Me")
                            .font(DesignSystem.Typography.headline)
                        
                        Text(viewModel.about)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Parenting Style
                GlassCardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                        Text("Parenting Style")
                            .font(DesignSystem.Typography.headline)
                        
                        ForEach(viewModel.parentingStyles, id: \.self) { style in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                Text(style)
                                    .font(DesignSystem.Typography.body)
                            }
                        }
                    }
                }
                
                // Children
                GlassCardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                        Text("Children")
                            .font(DesignSystem.Typography.headline)
                        
                        ForEach(viewModel.children) { child in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                VStack(alignment: .leading) {
                                    Text(child.name)
                                        .font(DesignSystem.Typography.body)
                                    Text("Age: \(child.age)")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Edit Profile Button
                Button(action: { showingEditProfile = true }) {
                    Text("Edit Profile")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Layout.buttonHeight)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.Layout.cornerRadius)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.horizontal)
            }
            .padding()
        }
        .glassBackground()
        .navigationTitle("Profile")
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $viewModel.profileImage)
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