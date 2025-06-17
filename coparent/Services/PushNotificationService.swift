import Foundation
import UserNotifications
import SendbirdChatSDK

class PushNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func registerDeviceToken(_ deviceToken: Data) async throws {
        let tokenString = deviceToken
            .map { String(format: "%02.2hhx", $0) }
            .joined()
        try await SendbirdChat.registerPushToken(tokenString, unique: true)
    }
    
    func unregisterDeviceToken() async throws {
        try await SendbirdChat.unregisterPushToken()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification when app is in foreground
        completionHagitndler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        if let payload = response.notification.request.content.userInfo as? [String: Any] {
            handleNotificationPayload(payload)
        }
        completionHandler()
    }
    
    private func handleNotificationPayload(_ payload: [String: Any]) {
        // Handle different types of notifications
        if let channelUrl = payload["channel_url"] as? String {
            // Navigate to specific chat channel
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenChatChannel"),
                object: nil,
                userInfo: ["channelUrl": channelUrl]
            )
        }
    }
} 
