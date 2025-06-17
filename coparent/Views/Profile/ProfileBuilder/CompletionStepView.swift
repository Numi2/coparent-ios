import SwiftUI

struct CompletionStepView: View {
    @State private var animateContent = false
    @State private var animateConfetti = false
    @State private var showingProfilePreview = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 2) {
            // Celebration Animation
            CelebrationSection(
                animateContent: animateContent,
                animateConfetti: animateConfetti
            )
            
            // Profile Completion Summary
            CompletionSummarySection(animateContent: animateContent)
            
            // Profile Stats
            ProfileStatsSection(animateContent: animateContent)
            
            // Next Steps
            NextStepsSection(animateContent: animateContent)
            
            // Profile Preview
            ProfilePreviewSection(
                showingProfilePreview: $showingProfilePreview,
                animateContent: animateContent
            )
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
}

#Preview("Completion Step") {
    CompletionStepView()
        .environment(ProfileBuilderViewModel())
        .environment(VerificationService.shared)
        .padding()
}
