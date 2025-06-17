import Foundation
import SendbirdChatSDK

@Observable
class SendbirdReactionsService {
    private let chatService: SendbirdChatService
    
    static let shared = SendbirdReactionsService()
    
    private init() {
        self.chatService = SendbirdChatService.shared
    }
    
    // MARK: - Message Reactions
    
    func addReaction(to message: BaseMessage, key: String) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(
                domain: "SendbirdReactionsService", 
                code: -1, 
                userInfo: [
                    NSLocalizedDescriptionKey: "SDK not initialized"
                ]
            )
        }
        
        do {
            let updatedMessage = try await message.addReaction(key: key)
            
            await MainActor.run {
                chatService.updateMessageInList(updatedMessage)
            }
        } catch {
            throw NSError(
                domain: "SendbirdReactionsService", 
                code: -6, 
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to add reaction: \(error.localizedDescription)"
                ]
            )
        }
    }
    
    func removeReaction(from message: BaseMessage, key: String) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(
                domain: "SendbirdReactionsService", 
                code: -1, 
                userInfo: [
                    NSLocalizedDescriptionKey: "SDK not initialized"
                ]
            )
        }
        
        do {
            let updatedMessage = try await message.deleteReaction(key: key)
            
            await MainActor.run {
                chatService.updateMessageInList(updatedMessage)
            }
        } catch {
            throw NSError(
                domain: "SendbirdReactionsService", 
                code: -7, 
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to remove reaction: \(error.localizedDescription)"
                ]
            )
        }
    }
    
    func getUserReactionKey(for message: BaseMessage) -> String? {
        guard let currentUserId = SendbirdChat.currentUser?.userId else { 
            return nil 
        }
        
        for reaction in message.reactions where reaction.userIds.contains(currentUserId) {
            return reaction.key
        }
        return nil
    }
    
    func hasUserReacted(to message: BaseMessage, with key: String) -> Bool {
        guard let currentUserId = SendbirdChat.currentUser?.userId else { 
            return false 
        }
        
        return message.reactions
            .first { $0.key == key }?
            .userIds
            .contains(currentUserId) ?? false
    }
}
