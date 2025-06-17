import Foundation
import SendbirdChatSDK
import UIKit

@Observable
class SendbirdChatService {
    private(set) var channels: [GroupChannel] = []
    private(set) var currentChannel: GroupChannel?
    private(set) var messages: [BaseMessage] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var typingUsers: [String] = []
    
    static let shared = SendbirdChatService()
    
    private init() {
        setupDelegates()
    }
    
    private func setupDelegates() {
        SendbirdChat.addChannelDelegate(self, identifier: "SendbirdChatService")
        SendbirdChat.addConnectionDelegate(self, identifier: "SendbirdChatService")
    }
    
    func fetchChannels() async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let params = GroupChannelListQueryParams()
            params.includeEmpty = false
            params.order = .latestLastMessage
            params.limit = 20
            
            let query = GroupChannel.createMyGroupChannelListQuery(params: params)
            let channels = try await query.loadNextPage()
            
            await MainActor.run {
                self.channels = channels
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchMessages(for channel: GroupChannel) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let params = MessageListParams()
            params.prevResultSize = AppConfig.Chat.messagePageSize
            params.nextResultSize = 0
            params.includeReactions = true
            params.includeThreadInfo = true
            
            let messages = try await channel.getMessages(params: params)
            
            await MainActor.run {
                self.currentChannel = channel
                self.messages = messages
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func sendMessage(_ text: String, in channel: GroupChannel) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            let params = UserMessageCreateParams(message: text)
            let message = try await channel.sendUserMessage(params: params)
            
            await MainActor.run {
                self.messages.append(message)
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func sendImage(_ image: UIImage, in channel: GroupChannel) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            // Compress image if needed
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                throw NSError(domain: "SendbirdChatService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            // Check file size
            if imageData.count > AppConfig.Chat.maxImageSize {
                throw NSError(domain: "SendbirdChatService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Image size exceeds maximum allowed size"])
            }
            
            // Create file message params
            let params = FileMessageCreateParams()
            params.file = imageData
            params.fileName = "image_\(Date().timeIntervalSince1970).jpg"
            params.mimeType = "image/jpeg"
            
            // Send file message
            let message = try await channel.sendFileMessage(params: params)
            
            await MainActor.run {
                self.messages.append(message)
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func sendImages(_ images: [UIImage], in channel: GroupChannel) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            // Send images sequentially to maintain order
            for (index, image) in images.enumerated() {
                // Compress image if needed
                guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                    throw NSError(domain: "SendbirdChatService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image \(index + 1)"])
                }
                
                // Check file size
                if imageData.count > AppConfig.Chat.maxImageSize {
                    throw NSError(domain: "SendbirdChatService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Image \(index + 1) size exceeds maximum allowed size"])
                }
                
                // Create file message params
                let params = FileMessageCreateParams()
                params.file = imageData
                params.fileName = "image_\(Date().timeIntervalSince1970)_\(index).jpg"
                params.mimeType = "image/jpeg"
                
                // Send file message
                let message = try await channel.sendFileMessage(params: params)
                
                await MainActor.run {
                    self.messages.append(message)
                }
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func createChannel(with userIds: [String]) async throws -> GroupChannel {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            let params = GroupChannelCreateParams()
            params.userIds = userIds
            params.isDistinct = true
            params.name = nil // Let Sendbird generate a name
            
            let channel = try await GroupChannel.createChannel(params: params)
            
            await MainActor.run {
                self.channels.insert(channel, at: 0)
            }
            
            return channel
        } catch {
            self.error = error
            throw error
        }
    }
    
    func sendVoiceMessage(_ audioURL: URL, in channel: GroupChannel) async throws {
        guard let currentUser = SendbirdChat.currentUser else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let params = FileMessageCreateParams()
        params.file = audioURL
        params.fileName = audioURL.lastPathComponent
        params.mimeType = "audio/m4a"
        params.fileSize = try FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? UInt64 ?? 0
        
        do {
            _ = try await channel.sendFileMessage(params: params)
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to send voice message: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Typing Indicators
    
    func startTyping(in channel: GroupChannel) {
        channel.startTyping()
    }
    
    func endTyping(in channel: GroupChannel) {
        channel.endTyping()
    }
    
    var isAnyoneTyping: Bool {
        !typingUsers.isEmpty
    }
    
    // MARK: - Message Operations
    
    func updateMessage(_ message: UserMessage, with newText: String) async throws {
        do {
            let params = UserMessageUpdateParams(message: newText)
            let updatedMessage = try await message.update(params: params)
            
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.messageId == message.messageId }) {
                    messages[index] = updatedMessage
                }
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to update message: \(error.localizedDescription)"])
        }
    }
    
    func deleteMessage(_ message: BaseMessage) async throws {
        do {
            try await message.delete()
            
            await MainActor.run {
                messages.removeAll { $0.messageId == message.messageId }
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to delete message: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Message Reactions
    
    func addReaction(to message: BaseMessage, key: String) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            let updatedMessage = try await message.addReaction(key: key)
            
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.messageId == message.messageId }) {
                    messages[index] = updatedMessage
                }
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to add reaction: \(error.localizedDescription)"])
        }
    }
    
    func removeReaction(from message: BaseMessage, key: String) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        do {
            let updatedMessage = try await message.deleteReaction(key: key)
            
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.messageId == message.messageId }) {
                    messages[index] = updatedMessage
                }
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -7, userInfo: [NSLocalizedDescriptionKey: "Failed to remove reaction: \(error.localizedDescription)"])
        }
    }
    
    func getUserReactionKey(for message: BaseMessage) -> String? {
        guard let currentUserId = SendbirdChat.currentUser?.userId else { return nil }
        
        for reaction in message.reactions {
            if reaction.userIds.contains(currentUserId) {
                return reaction.key
            }
        }
        return nil
    }
    
    func hasUserReacted(to message: BaseMessage, with key: String) -> Bool {
        guard let currentUserId = SendbirdChat.currentUser?.userId else { return false }
        
        return message.reactions.first { $0.key == key }?.userIds.contains(currentUserId) ?? false
    }
}

// MARK: - ChannelDelegate
extension SendbirdChatService: GroupChannelDelegate {
    func channel(_ channel: GroupChannel, didReceive message: BaseMessage) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl {
                messages.append(message)
            }
            
            // Update channel list
            if let index = channels.firstIndex(where: { $0.channelUrl == channel.channelUrl }) {
                channels.remove(at: index)
                channels.insert(channel, at: 0)
            }
        }
    }
    
    func channelDidUpdate(_ channel: GroupChannel) {
        Task { @MainActor in
            if let index = channels.firstIndex(where: { $0.channelUrl == channel.channelUrl }) {
                channels[index] = channel
            }
            
            if channel.channelUrl == currentChannel?.channelUrl {
                currentChannel = channel
            }
        }
    }
    
    func channel(_ channel: GroupChannel, didUpdate message: BaseMessage) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl,
               let index = messages.firstIndex(where: { $0.messageId == message.messageId }) {
                messages[index] = message
            }
        }
    }
    
    func channel(_ channel: GroupChannel, messageWasDeleted messageId: Int64) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl {
                messages.removeAll { $0.messageId == messageId }
            }
        }
    }
    
    func channel(_ channel: GroupChannel, didUpdateReadStatus message: BaseMessage) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl,
               let index = messages.firstIndex(where: { $0.messageId == message.messageId }) {
                messages[index] = message
            }
        }
    }
    
    func channel(_ channel: GroupChannel, userDidStartTyping user: User) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl,
               user.userId != SendbirdChat.currentUser?.userId,
               !typingUsers.contains(user.userId) {
                typingUsers.append(user.userId)
            }
        }
    }
    
    func channel(_ channel: GroupChannel, userDidStopTyping user: User) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl {
                typingUsers.removeAll { $0 == user.userId }
            }
        }
    }
    
    func channel(_ channel: GroupChannel, updatedReaction reactionEvent: ReactionEvent) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl,
               let index = messages.firstIndex(where: { $0.messageId == reactionEvent.messageId }) {
                // Fetch the updated message with latest reactions
                let params = MessageRetrievalParams()
                params.messageId = reactionEvent.messageId
                params.includeReactions = true
                
                do {
                    if let updatedMessage = try await channel.getMessage(params: params) {
                        messages[index] = updatedMessage
                    }
                } catch {
                    print("Failed to fetch updated message with reactions: \(error)")
                }
            }
        }
    }
}

// MARK: - ConnectionDelegate
extension SendbirdChatService: ConnectionDelegate {
    func didSucceedReconnection() {
        Task {
            do {
                try await fetchChannels()
                if let channel = currentChannel {
                    try await fetchMessages(for: channel)
                }
            } catch {
                print("Failed to reload data after reconnection: \(error)")
            }
        }
    }
} 