import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var isEnabled = true
    @State private var showSound = true
    @State private var showBadge = true
    @State private var showAlert = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Push Notifications")) {
                Toggle("Enable Notifications", isOn: $isEnabled)
                    .onChange(of: isEnabled) { _ in
                        updateNotificationSettings()
                    }
                
                if isEnabled {
                    Toggle("Sound", isOn: $showSound)
                        .onChange(of: showSound) { _ in
                            updateNotificationSettings()
                        }
                    
                    Toggle("Badge", isOn: $showBadge)
                        .onChange(of: showBadge) { _ in
                            updateNotificationSettings()
                        }
                    
                    Toggle("Alert", isOn: $showAlert)
                        .onChange(of: showAlert) { _ in
                            updateNotificationSettings()
                        }
                }
            }
            
            Section(header: Text("About"), footer: Text("You can change these settings at any time.")) {
                Text("Notifications help you stay connected with your matches and never miss important messages.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        isEnabled = settings.authorizationStatus == .authorized
        showSound = settings.soundSetting == .enabled
        showBadge = settings.badgeSetting == .enabled
        showAlert = settings.alertSetting == .enabled
    }
    
    private func updateNotificationSettings() {
        Task {
            do {
                if isEnabled {
                    let options: UNAuthorizationOptions = [
                        showSound ? .sound : [],
                        showBadge ? .badge : [],
                        showAlert ? .alert : []
                    ].reduce([], { $0.union($1) })
                    
                    let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
                    if !authorized {
                        isEnabled = false
                        errorMessage = "Failed to enable notifications. Please check your system settings."
                        showError = true
                    }
                } else {
                    try await PushNotificationService.shared.unregisterDeviceToken()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
} 
