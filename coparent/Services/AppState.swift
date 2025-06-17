@MainActor
class AppState: ObservableObject {
    private let pushNotificationService = PushNotificationService.shared
    
    init() {
        // Initialize push notifications
        Task {
            do {
                let authorized = try await pushNotificationService.requestAuthorization()
                if authorized {
                    pushNotificationService.registerForRemoteNotifications()
                }
            } catch {
                print(
                    "Failed to request push notification authorization: \(error)"
                )
            }
        }
    }
} 
