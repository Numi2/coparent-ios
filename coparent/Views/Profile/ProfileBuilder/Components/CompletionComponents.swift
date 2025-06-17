import SwiftUI

// MARK: - Celebration Section

struct CelebrationSection: View {
    let animateContent: Bool
    let animateConfetti: Bool
    
    var body: some View {
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
}

// MARK: - Completion Summary Section

struct CompletionSummarySection: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @Environment(VerificationService.self) private var verificationService
    let animateContent: Bool
    
    var body: some View {
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
}

// MARK: - Profile Stats Section

struct ProfileStatsSection: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @Environment(VerificationService.self) private var verificationService
    let animateContent: Bool
    
    private let statsColumns = Array(
        repeating: GridItem(.flexible(), spacing: DesignSystem.Layout.spacing), 
        count: 2
    )
    
    var body: some View {
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
}

// MARK: - Next Steps Section

struct NextStepsSection: View {
    let animateContent: Bool
    
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
    
    var body: some View {
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
}

// MARK: - Profile Preview Section

struct ProfilePreviewSection: View {
    @Binding var showingProfilePreview: Bool
    let animateContent: Bool
    
    var body: some View {
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
}

// MARK: - Supporting Models

struct NextStep {
    let icon: String
    let title: String
    let description: String
    let action: String
}
