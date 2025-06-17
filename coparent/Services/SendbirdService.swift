import Foundation
import SendbirdChatSDK

@Observable
class SendbirdService {
    private(set) var isInitialized = false
    private(set) var isConnected = false
    private(set) var error: Error?
    
    static let shared = SendbirdService()
    
    private init() {}
    
    func initialize() async throws {
        guard !isInitialized else { return }
        
        do {
            // Initialize Sendbird SDK
            let params = InitParams(
                applicationId: AppConfig.Sendbird.appId,
                isLocalCachingEnabled: AppConfig.Sendbird.isLocalCachingEnabled
            )
            
            try await SendbirdChat.initialize(params: params)
            isInitialized = true
        } catch {
            self.error = error
            throw error
        }
    }
    
    func connect(userId: String, nickname: String? = nil) async throws {
        guard isInitialized else {
            throw NSError(domain: "SendbirdService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            let user = try await SendbirdChat.connect(userId: userId, nickname: nickname)
            isConnected = true
            return user
        } catch {
            self.error = error
            throw error
        }
    }
    
    func disconnect() async {
        guard isConnected else { return }
        
        do {
            try await SendbirdChat.disconnect()
            isConnected = false
        } catch {
            self.error = error
        }
    }
} 