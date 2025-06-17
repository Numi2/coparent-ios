import SwiftUI

struct PreferencesStepView: View {
    @State private var animateContent = false
    @State private var newDealBreaker = ""
    @State private var toast: ToastData?
    @FocusState private var isDealBreakerFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Preferences Overview
            PreferencesOverviewSection(animateContent: animateContent)
            
            // Age Range Section
            AgeRangeSection(animateContent: animateContent)
            
            // Distance Section
            DistanceSection(animateContent: animateContent)
            
            // Parenting Styles Section
            ParentingStylesSection(animateContent: animateContent)
            
            // Deal Breakers Section
            DealBreakersSection(
                newDealBreaker: $newDealBreaker,
                toast: $toast,
                isDealBreakerFocused: $isDealBreakerFocused,
                animateContent: animateContent
            )
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
        }
        .toast($toast)
    }
}

#Preview("Preferences Step") {
    PreferencesStepView()
        .environment(ProfileBuilderViewModel())
        .padding()
}
