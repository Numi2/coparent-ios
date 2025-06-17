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