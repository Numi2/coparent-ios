import SwiftUI

@Observable
class AppState {
    var isOnboarded = false
    var currentUser: User?
    var onboardingStep: OnboardingStep = .welcome
    
    enum OnboardingStep {
        case welcome
        case userType
        case basicInfo
        case terms
        case complete
    }
}

struct User {
    var id: String
    var name: String
    var userType: UserType
    var email: String?
    var phoneNumber: String?
    
    enum UserType {
        case singleParent
        case coParent
        case potentialCoParent
    }
}

@main
struct CoParentApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if !appState.isOnboarded {
                OnboardingView()
                    .environment(appState)
            } else {
                MainTabView()
                    .environment(appState)
            }
        }
    }
} 