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
    
    // MARK: - Advanced Chat Features
    private(set) var isLoadingOlderMessages = false
    private(set) var hasMoreMessages = true
    private(set) var searchResults: [BaseMessage] = []
    private(set) var isSearching = false
    private(set) var currentSearchQuery = ""
    
    static let shared = SendbirdChatService()
    
    private init() {
        setupDelegates()
    }
    
    private func setupDelegates() {
        SendbirdChat.addChannelDelegate(self, identifier: "SendbirdChatService")
        SendbirdChat.addConnectionDelegate(self, identifier: "SendbirdChatService")
    }
    
    // MARK: - Helper Methods for Other Services
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func setError(_ error: Error) {
        self.error = error
    }
    
    func setMessages(_ messages: [BaseMessage]) {
        self.messages = messages
    }
    
    func updateMessageInList(_ message: BaseMessage) {
        if let index = messages.firstIndex(where: { $0.messageId == message.messageId }) {
            messages[index] = message
        }
    }
    
    // MARK: - Core Chat Functionality
    
    func fetchChannels() async throws {
        guard SendbirdChat.isInitialized else {
            throw ChatServiceError.sdkNotInitialized
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
            throw ChatServiceError.sdkNotInitialized
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
            throw ChatServiceError.sdkNotInitialized
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
            throw ChatServiceError.sdkNotInitialized
        }
        
        do {
            let imageData = try prepareImageData(from: image)
            let params = createFileMessageParams(
                with: imageData, 
                fileName: "image_\(Date().timeIntervalSince1970).jpg"
            )
            
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
            throw ChatServiceError.sdkNotInitialized
        }
        
        do {
            // Send images sequentially to maintain order
            for (index, image) in images.enumerated() {
                let imageData = try prepareImageData(from: image)
                let params = createFileMessageParams(
                    with: imageData, 
                    fileName: "image_\(Date().timeIntervalSince1970)_\(index).jpg"
                )
                
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
            throw ChatServiceError.sdkNotInitialized
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
        guard SendbirdChat.currentUser != nil else {
            throw ChatServiceError.userNotAuthenticated
        }
        
        let params = FileMessageCreateParams()
        params.file = audioURL
        params.fileName = audioURL.lastPathComponent
        params.mimeType = "audio/m4a"
        
        do {
            let fileSize = try FileManager.default
                .attributesOfItem(atPath: audioURL.path)[.size] as? UInt64 ?? 0
            params.fileSize = fileSize
            
            _ = try await channel.sendFileMessage(params: params)
        } catch {
            throw ChatServiceError.failedToSendVoiceMessage(error.localizedDescription)
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
                updateMessageInList(updatedMessage)
            }
        } catch {
            throw ChatServiceError.failedToUpdateMessage(error.localizedDescription)
        }
    }
    
    func deleteMessage(_ message: BaseMessage) async throws {
        do {
            try await message.delete()
            
            await MainActor.run {
                messages.removeAll { $0.messageId == message.messageId }
            }
        } catch {
            throw ChatServiceError.failedToDeleteMessage(error.localizedDescription)
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
        
        for reaction in message.reactions where reaction.userIds.contains(currentUserId) {
            return reaction.key
        }
        return nil
    }
    
    func hasUserReacted(to message: BaseMessage, with key: String) -> Bool {
        guard let currentUserId = SendbirdChat.currentUser?.userId else { return false }
        
        return message.reactions.first { $0.key == key }?.userIds.contains(currentUserId) ?? false
    }
    
    // MARK: - Message Threading
    
    private(set) var currentThread: BaseMessage?
    private(set) var threadMessages: [BaseMessage] = []
    private(set) var isLoadingThread = false
    
    func fetchThreadMessages(for parentMessage: BaseMessage) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        guard let channel = currentChannel else {
            throw NSError(domain: "SendbirdChatService", code: -8, userInfo: [NSLocalizedDescriptionKey: "No current channel"])
        }
        
        isLoadingThread = true
        defer { isLoadingThread = false }
        
        do {
            let params = ThreadMessageListParams()
            params.prevResultSize = AppConfig.Chat.messagePageSize
            params.nextResultSize = 0
            params.includeReactions = true
            params.includeThreadInfo = true
            
            let threadedMessages = try await channel.getThreadedMessages(parentMessageId: parentMessage.messageId, params: params)
            
            await MainActor.run {
                self.currentThread = parentMessage
                self.threadMessages = threadedMessages
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -9, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch thread messages: \(error.localizedDescription)"])
        }
    }
    
    func sendThreadMessage(_ text: String, to parentMessage: BaseMessage) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        guard let channel = currentChannel else {
            throw NSError(domain: "SendbirdChatService", code: -8, userInfo: [NSLocalizedDescriptionKey: "No current channel"])
        }
        
        do {
            let params = UserMessageCreateParams(message: text)
            params.parentMessageId = parentMessage.messageId
            
            let message = try await channel.sendUserMessage(params: params)
            
            await MainActor.run {
                self.threadMessages.append(message)
                
                // Update parent message in main messages list to show thread indicator
                if let index = messages.firstIndex(where: { $0.messageId == parentMessage.messageId }) {
                    // Fetch updated parent message with thread info
                    Task {
                        do {
                            let messageParams = MessageRetrievalParams()
                            messageParams.messageId = parentMessage.messageId
                            messageParams.includeThreadInfo = true
                            messageParams.includeReactions = true
                            
                            if let updatedParent = try await channel.getMessage(params: messageParams) {
                                await MainActor.run {
                                    messages[index] = updatedParent
                                }
                            }
                        } catch {
                            print("Failed to update parent message with thread info: \(error)")
                        }
                    }
                }
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Failed to send thread message: \(error.localizedDescription)"])
        }
    }
    
    func sendThreadImage(_ image: UIImage, to parentMessage: BaseMessage) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(domain: "SendbirdChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK not initialized"])
        }
        
        guard let channel = currentChannel else {
            throw NSError(domain: "SendbirdChatService", code: -8, userInfo: [NSLocalizedDescriptionKey: "No current channel"])
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
            
            let params = FileMessageCreateParams()
            params.file = imageData
            params.fileName = "image_\(Date().timeIntervalSince1970).jpg"
            params.mimeType = "image/jpeg"
            params.parentMessageId = parentMessage.messageId
            
            let message = try await channel.sendFileMessage(params: params)
            
            await MainActor.run {
                self.threadMessages.append(message)
            }
        } catch {
            throw NSError(domain: "SendbirdChatService", code: -11, userInfo: [NSLocalizedDescriptionKey: "Failed to send thread image: \(error.localizedDescription)"])
        }
    }
    
    func exitThread() {
        currentThread = nil
        threadMessages.removeAll()
    }
    
    func getThreadInfo(for message: BaseMessage) -> ThreadInfo? {
        return message.threadInfo
    }
    
    func hasThread(for message: BaseMessage) -> Bool {
        return message.threadInfo?.replyCount ?? 0 > 0
    }
    
    func getThreadReplyCount(for message: BaseMessage) -> Int {
        return Int(message.threadInfo?.replyCount ?? 0)
    }
    
    // MARK: - Advanced Chat Features
    
    /// Refreshes messages for pull-to-refresh functionality
    func refreshMessages() async throws {
        guard let channel = currentChannel else {
            throw NSError(domain: "SendbirdChatService", code: -8, userInfo: [NSLocalizedDescriptionKey: "No current channel"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let params = MessageListParams()
            params.prevResultSize = AppConfig.Chat.messagePageSize
            params.nextResultSize = 0
            params.includeReactions = true
            params.includeThreadInfo = true
            
            let newMessages = try await channel.getMessages(params: params)
            
            await MainActor.run {
                self.messages = newMessages
                self.hasMoreMessages = newMessages.count == AppConfig.Chat.messagePageSize
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Loads older messages for infinite scrolling
    func loadOlderMessages() async throws {
        guard let channel = currentChannel else {
            throw NSError(domain: "SendbirdChatService", code: -8, userInfo: [NSLocalizedDescriptionKey: "No current channel"])
        }
        
        guard !isLoadingOlderMessages && hasMoreMessages else { return }
        
        isLoadingOlderMessages = true
        defer { isLoadingOlderMessages = false }
        
        do {
            let params = MessageListParams()
            params.prevResultSize = AppConfig.Chat.messagePageSize
            params.nextResultSize = 0
            params.includeReactions = true
            params.includeThreadInfo = true
            
            // Use the oldest message as timestamp reference
            if let oldestMessage = messages.first {
                params.inclusiveTimestamp = oldestMessage.createdAt - 1
            }
            
            let olderMessages = try await channel.getMessages(params: params)
            
            await MainActor.run {
                // Prepend older messages to maintain chronological order
                self.messages = olderMessages + self.messages
                self.hasMoreMessages = olderMessages.count == AppConfig.Chat.messagePageSize
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Searches messages in the current channel
    func searchMessages(query: String) async throws {
        guard let channel = currentChannel else {
            throw NSError(domain: "SendbirdChatService", code: -8, userInfo: [NSLocalizedDescriptionKey: "No current channel"])
        }
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.currentSearchQuery = ""
                self.isSearching = false
            }
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            let params = MessageSearchQueryParams()
            params.keyword = query
            params.channelUrl = channel.channelUrl
            params.order = .timestamp
            params.reverse = true // Most recent first
            params.limit = 50
            params.messageTimestampFrom = 0
            params.messageTimestampTo = Int64(Date().timeIntervalSince1970 * 1000)
            
            let searchQuery = SendbirdChat.createMessageSearchQuery(params: params)
            let results = try await searchQuery.loadNextPage()
            
            await MainActor.run {
                self.searchResults = results
                self.currentSearchQuery = query
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Clears search results and returns to normal message view
    func clearSearch() {
        searchResults = []
        currentSearchQuery = ""
        isSearching = false
    }
    
    /// Gets the currently displayed messages (either search results or regular messages)
    var displayedMessages: [BaseMessage] {
        return currentSearchQuery.isEmpty ? messages : searchResults
    }
    
    /// Checks if we're currently in search mode
    var isInSearchMode: Bool {
        return !currentSearchQuery.isEmpty
    }
    
    // MARK: - Private Helper Methods
    
    private func prepareImageData(from image: UIImage) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ChatServiceError.failedToCompressImage
        }
        
        if imageData.count > AppConfig.Chat.maxImageSize {
            throw ChatServiceError.imageSizeExceedsLimit
        }
        
        return imageData
    }
    
    private func createFileMessageParams(with data: Data, fileName: String) -> FileMessageCreateParams {
        let params = FileMessageCreateParams()
        params.file = data
        params.fileName = fileName
        params.mimeType = "image/jpeg"
        return params
    }
}

// MARK: - ChannelDelegate
extension SendbirdChatService: GroupChannelDelegate {
    func channel(_ channel: GroupChannel, didReceive message: BaseMessage) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl {
                messages.append(message)
            }
            
            updateChannelInList(channel)
        }
    }
    
    func channelDidUpdate(_ channel: GroupChannel) {
        Task { @MainActor in
            updateChannelInList(channel)
            
            if channel.channelUrl == currentChannel?.channelUrl {
                currentChannel = channel
            }
        }
    }
    
    func channel(_ channel: GroupChannel, didUpdate message: BaseMessage) {
        Task { @MainActor in
            if channel.channelUrl == currentChannel?.channelUrl {
                updateMessageInList(message)
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
            if channel.channelUrl == currentChannel?.channelUrl {
                updateMessageInList(message)
            }
        }
    }
    
    func channel(_ channel: GroupChannel, userDidStartTyping user: User) {
        Task { @MainActor in
            handleTypingStart(in: channel, by: user)
        }
    }
    
    func channel(_ channel: GroupChannel, userDidStopTyping user: User) {
        Task { @MainActor in
            handleTypingStop(in: channel, by: user)
        }
    }
    
    func channel(_ channel: GroupChannel, updatedReaction reactionEvent: ReactionEvent) {
        Task { @MainActor in
            await handleReactionUpdate(in: channel, event: reactionEvent)
        }
    }
    
    func channel(
        _ channel: GroupChannel, 
        didReceiveThreadInfo threadInfoUpdateEvent: ThreadInfoUpdateEvent
    ) {
        Task { @MainActor in
            await handleThreadInfoUpdate(in: channel, event: threadInfoUpdateEvent)
        }
    }
    
    // MARK: - Private Delegate Helper Methods
    
    private func updateChannelInList(_ channel: GroupChannel) {
        if let index = channels.firstIndex(where: { $0.channelUrl == channel.channelUrl }) {
            channels.remove(at: index)
            channels.insert(channel, at: 0)
        }
    }
    
    private func handleTypingStart(in channel: GroupChannel, by user: User) {
        if channel.channelUrl == currentChannel?.channelUrl,
           user.userId != SendbirdChat.currentUser?.userId,
           !typingUsers.contains(user.userId) {
            typingUsers.append(user.userId)
        }
    }
    
    private func handleTypingStop(in channel: GroupChannel, by user: User) {
        if channel.channelUrl == currentChannel?.channelUrl {
            typingUsers.removeAll { $0 == user.userId }
        }
    }
    
    private func handleReactionUpdate(
        in channel: GroupChannel, 
        event: ReactionEvent
    ) async {
        if channel.channelUrl == currentChannel?.channelUrl,
           let index = messages.firstIndex(where: { $0.messageId == event.messageId }) {
            // Fetch the updated message with latest reactions
            let params = MessageRetrievalParams()
            params.messageId = event.messageId
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
    
    private func handleThreadInfoUpdate(
        in channel: GroupChannel, 
        event: ThreadInfoUpdateEvent
    ) async {
        if channel.channelUrl == currentChannel?.channelUrl {
            // Update parent message in main messages list
            if let index = messages.firstIndex(where: { 
                $0.messageId == event.targetMessageId 
            }) {
                let params = MessageRetrievalParams()
                params.messageId = event.targetMessageId
                params.includeThreadInfo = true
                params.includeReactions = true
                
                do {
                    if let updatedMessage = try await channel.getMessage(params: params) {
                        messages[index] = updatedMessage
                    }
                } catch {
                    print("Failed to fetch updated parent message with thread info: \(error)")
                }
            }
            
            // Notify threading service about the update
            let threadingService = SendbirdThreadingService.shared
            if let currentThread = threadingService.currentThread,
               currentThread.messageId == event.targetMessageId {
                do {
                    try await threadingService.fetchThreadMessages(for: currentThread)
                } catch {
                    print("Failed to refresh thread messages: \(error)")
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

// MARK: - Chat Service Errors
enum ChatServiceError: LocalizedError {
    case sdkNotInitialized
    case userNotAuthenticated
    case failedToCompressImage
    case imageSizeExceedsLimit
    case failedToSendVoiceMessage(String)
    case failedToUpdateMessage(String)
    case failedToDeleteMessage(String)
    
    var errorDescription: String? {
        switch self {
        case .sdkNotInitialized:
            return "SDK not initialized"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .failedToCompressImage:
            return "Failed to compress image"
        case .imageSizeExceedsLimit:
            return "Image size exceeds maximum allowed size"
        case .failedToSendVoiceMessage(let message):
            return "Failed to send voice message: \(message)"
        case .failedToUpdateMessage(let message):
            return "Failed to update message: \(message)"
        case .failedToDeleteMessage(let message):
            return "Failed to delete message: \(message)"
        }
    }
} 
