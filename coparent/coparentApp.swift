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

    func initializeServices() async {
        do {
            try await SendbirdService.shared.initialize()
        } catch {
            print("Failed to initialize Sendbird: \(error)")
        }
    }

    func connectToSendbird() async {
        guard let user = currentUser else { return }

        do {
            try await SendbirdService.shared.connect(userId: user.id, nickname: user.name)
        } catch {
            print("Failed to connect to Sendbird: \(error)")
        }
    }
}

// User model is defined in Models/User.swift

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
        .task {
            await appState.initializeServices()
        }
    }
}
