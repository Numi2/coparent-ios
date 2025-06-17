import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            switch appState.onboardingStep {
            case .welcome:
                WelcomeView()
            case .userType:
                UserTypeView()
            case .basicInfo:
                BasicInfoView()
            case .terms:
                TermsView()
            case .complete:
                OnboardingCompleteView()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
} 