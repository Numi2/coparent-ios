import SwiftUI

struct CompletionStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @Environment(VerificationService.self) private var verificationService
    @State private var animateContent = false
    @State private var animateConfetti = false
    @State private var showingProfilePreview = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 2) {
            // Celebration Animation
            celebrationSection
            
            // Profile Completion Summary
            completionSummarySection
            
            // Profile Stats
            profileStatsSection
            
            // Next Steps
            nextStepsSection
            
            // Profile Preview
            profilePreviewSection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
            
            // Start confetti animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(DesignSystem.Animation.spring) {
                    animateConfetti = true
                }
            }
        }
    }
    
    // MARK: - Celebration Section
    
    private var celebrationSection: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Confetti/Celebration Animation
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(animateContent ? 1.0 : 0.5)
                    .animation(
                        DesignSystem.Animation.spring.delay(0.2),
                        value: animateContent
                    )
                
                // Celebration Icon
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateContent ? 1.0 : 0.3)
                    .rotationEffect(.degrees(animateConfetti ? 15 : -15))
                    .animation(
                        DesignSystem.Animation.spring.delay(0.4),
                        value: animateContent
                    )
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateConfetti
                    )
                
                // Floating particles
                ForEach(0..<8, id: \.self) { index in
                    FloatingParticle(
                        delay: Double(index) * 0.1,
                        animate: animateConfetti
                    )
                }
            }
            
            VStack(spacing: 8) {
                Text("Congratulations!")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(
                        DesignSystem.Animation.spring.delay(0.6),
                        value: animateContent
                    )
                
                Text("Your amazing profile is complete and ready to help you find meaningful connections!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(
                        DesignSystem.Animation.spring.delay(0.8),
                        value: animateContent
                    )
            }
        }
    }
    
    // MARK: - Completion Summary Section
    
    private var completionSummarySection: some View {
        GlassCardView {
            VStack(spacing: DesignSystem.Layout.spacing) {
                HStack {
                    Text("Profile Completion")
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(profileBuilder.profileCompletion * 100))%")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                ProgressView(value: profileBuilder.profileCompletion, total: 1.0)
                    .progressViewStyle(GlassProgressViewStyle())
                    .scaleEffect(y: 3.0)
                
                HStack {
                    CompletionBadge(
                        title: "Photos",
                        isComplete: profileBuilder.hasMainPhoto,
                        icon: "camera.fill"
                    )
                    
                    CompletionBadge(
                        title: "Bio",
                        isComplete: profileBuilder.isAboutYouComplete,
                        icon: "text.quote"
                    )
                    
                    CompletionBadge(
                        title: "Interests",
                        isComplete: profileBuilder.hasSelectedInterests,
                        icon: "heart.fill"
                    )
                    
                    CompletionBadge(
                        title: "Verified",
                        isComplete: verificationService.getOverallVerificationScore() > 0.3,
                        icon: "checkmark.shield.fill"
                    )
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(DesignSystem.Animation.spring.delay(1.0), value: animateContent)
    }
    
    // MARK: - Profile Stats Section
    
    private var profileStatsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                
                Text("Your Profile Stats")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVGrid(columns: statsColumns, spacing: DesignSystem.Layout.spacing) {
                StatCard(
                    title: "Photos",
                    value: "\(profileBuilder.profileImages.count)",
                    subtitle: "Added",
                    icon: "photo.stack.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Interests",
                    value: "\(profileBuilder.selectedInterests.count)",
                    subtitle: "Selected",
                    icon: "heart.fill",
                    color: .pink
                )
                
                StatCard(
                    title: "Bio Length",
                    value: "\(profileBuilder.bio.count)",
                    subtitle: "Characters",
                    icon: "text.alignleft",
                    color: .green
                )
                
                StatCard(
                    title: "Verification",
                    value: "\(Int(verificationService.getOverallVerificationScore() * 100))%",
                    subtitle: "Complete",
                    icon: "shield.checkered",
                    color: .orange
                )
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(DesignSystem.Animation.spring.delay(1.2), value: animateContent)
    }
    
    // MARK: - Next Steps Section
    
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "arrow.forward.circle.fill")
                    .foregroundColor(.purple)
                
                Text("What's Next?")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    ForEach(nextSteps, id: \.title) { step in
                        NextStepRow(step: step)
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(DesignSystem.Animation.spring.delay(1.4), value: animateContent)
    }
    
    // MARK: - Profile Preview Section
    
    private var profilePreviewSection: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            Button("Preview Your Profile") {
                showingProfilePreview = true
            }
            .buttonStyle(GlassPrimaryButtonStyle())
            
            Text("See how your profile looks to potential matches")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(DesignSystem.Animation.spring.delay(1.6), value: animateContent)
        .sheet(isPresented: $showingProfilePreview) {
            ProfilePreviewView()
        }
    }
    
    // MARK: - Computed Properties
    
    private let statsColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Layout.spacing), count: 2)
    
    private let nextSteps = [
        NextStep(
            icon: "magnifyingglass",
            title: "Start Browsing",
            description: "Discover potential matches in your area",
            action: "Browse"
        ),
        NextStep(
            icon: "heart.circle.fill",
            title: "Get Matches",
            description: "Like profiles that interest you",
            action: "Match"
        ),
        NextStep(
            icon: "message.circle.fill",
            title: "Start Chatting",
            description: "Connect with your matches",
            action: "Chat"
        ),
        NextStep(
            icon: "person.2.circle.fill",
            title: "Meet People",
            description: "Plan safe meetups when you're ready",
            action: "Meet"
        )
    ]
}

// MARK: - Supporting Views

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
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(Array(profileBuilder.selectedInterests), id: \.self) { interest in
                                        Text(interest.displayName)
                                            .font(DesignSystem.Typography.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(DesignSystem.Layout.padding)
            }
            .navigationTitle("Profile Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct NextStep {
    let icon: String
    let title: String
    let description: String
    let action: String
}

#Preview {
    ScrollView {
        CompletionStepView()
            .padding()
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(ProfileBuilderViewModel())
    .environment(VerificationService())
}