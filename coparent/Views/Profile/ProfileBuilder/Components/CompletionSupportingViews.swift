import SwiftUI

// MARK: - Floating Particle

struct FloatingParticle: View {
    let delay: Double
    let animate: Bool
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.yellow, .orange, .pink, .purple].randomElement() ?? .blue,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 8, height: 8)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                if animate {
                    startAnimation()
                }
            }
            .onChange(of: animate) { _, newValue in
                if newValue {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        let randomAngle = Double.random(in: 0...(2 * .pi))
        let distance: CGFloat = CGFloat.random(in: 50...100)
        
        withAnimation(
            Animation.easeOut(duration: 2.0).delay(delay)
        ) {
            offset = CGSize(
                width: cos(randomAngle) * distance,
                height: sin(randomAngle) * distance
            )
            opacity = 1.0
        }
        
        withAnimation(
            Animation.easeIn(duration: 1.0).delay(delay + 1.0)
        ) {
            opacity = 0.0
        }
    }
}

// MARK: - Completion Badge

struct CompletionBadge: View {
    let title: String
    let isComplete: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(isComplete ? .green : .gray)
                .font(.title3)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(isComplete ? .green : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isComplete ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCardView {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Next Step Row

struct NextStepRow: View {
    let step: NextStep
    
    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing) {
            Image(systemName: step.icon)
                .foregroundColor(.purple)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                
                Text(step.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(step.action)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(8)
        }
    }
}

// MARK: - Profile Preview View

struct ProfilePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Layout.spacing * 2) {
                    // Profile Header
                    VStack(spacing: DesignSystem.Layout.spacing) {
                        if let firstImage = profileBuilder.profileImages.first {
                            Image(uiImage: firstImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                        }
                        
                        VStack(spacing: 8) {
                            Text(profileBuilder.name)
                                .font(DesignSystem.Typography.title)
                                .fontWeight(.bold)
                            
                            Text("\(profileBuilder.city), \(profileBuilder.state)")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Bio
                    if !profileBuilder.bio.isEmpty {
                        GlassCardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                
                                Text(profileBuilder.bio)
                                    .font(DesignSystem.Typography.body)
                            }
                        }
                    }
                    
                    // Interests
                    if !profileBuilder.selectedInterests.isEmpty {
                        GlassCardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                                Text("Interests")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100, maximum: 150))
                                ], spacing: 8) {
                                    ForEach(profileBuilder.selectedInterests, id: \.self) { interest in
                                        Text(interest)
                                            .font(DesignSystem.Typography.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    
                    // Children
                    if profileBuilder.hasChildren && !profileBuilder.children.isEmpty {
                        GlassCardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                                Text("Children")
                                    .font(DesignSystem.Typography.headline)
                                    .fontWeight(.semibold)
                                
                                ForEach(profileBuilder.children) { child in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(.blue.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(child.name.first ?? "?"))
                                                    .font(DesignSystem.Typography.headline)
                                                    .foregroundColor(.blue)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(child.name)
                                                .font(DesignSystem.Typography.callout)
                                                .fontWeight(.medium)
                                            
                                            Text("\(child.age) years old")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
