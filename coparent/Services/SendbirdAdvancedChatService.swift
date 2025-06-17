import Foundation
import SendbirdChatSDK

@Observable
class SendbirdAdvancedChatService {
    private let chatService: SendbirdChatService
    
    // MARK: - Advanced Chat Features
    private(set) var isLoadingOlderMessages = false
    private(set) var hasMoreMessages = true
    private(set) var searchResults: [BaseMessage] = []
    private(set) var isSearching = false
    private(set) var currentSearchQuery = ""
    
    static let shared = SendbirdAdvancedChatService()
    
    private init() {
        self.chatService = SendbirdChatService.shared
    }
    
    // MARK: - Message Pagination
    
    /// Refreshes messages for pull-to-refresh functionality
    func refreshMessages() async throws {
        guard let channel = chatService.currentChannel else {
            throw NSError(
                domain: "SendbirdAdvancedChatService", 
                code: -8, 
                userInfo: [
                    NSLocalizedDescriptionKey: "No current channel"
                ]
            )
        }
        
        chatService.setLoading(true)
        defer { chatService.setLoading(false) }
        
        do {
            let params = MessageListParams()
            params.prevResultSize = AppConfig.Chat.messagePageSize
            params.nextResultSize = 0
            params.includeReactions = true
            params.includeThreadInfo = true
            
            let newMessages = try await channel.getMessages(params: params)
            
            await MainActor.run {
                chatService.setMessages(newMessages)
                self.hasMoreMessages = newMessages.count == AppConfig.Chat.messagePageSize
            }
        } catch {
            chatService.setError(error)
            throw error
        }
    }
    
    /// Loads older messages for infinite scrolling
    func loadOlderMessages() async throws {
        guard let channel = chatService.currentChannel else {
            throw NSError(
                domain: "SendbirdAdvancedChatService", 
                code: -8, 
                userInfo: [
                    NSLocalizedDescriptionKey: "No current channel"
                ]
            )
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
            if let oldestMessage = chatService.messages.first {
                params.inclusiveTimestamp = oldestMessage.createdAt - 1
            }
            
            let olderMessages = try await channel.getMessages(params: params)
            
            await MainActor.run {
                // Prepend older messages to maintain chronological order
                let updatedMessages = olderMessages + chatService.messages
                chatService.setMessages(updatedMessages)
                self.hasMoreMessages = olderMessages.count == AppConfig.Chat.messagePageSize
            }
        } catch {
            chatService.setError(error)
            throw error
        }
    }
    
    // MARK: - Message Search
    
    /// Searches messages in the current channel
    func searchMessages(query: String) async throws {
        guard let channel = chatService.currentChannel else {
            throw NSError(
                domain: "SendbirdAdvancedChatService", 
                code: -8, 
                userInfo: [
                    NSLocalizedDescriptionKey: "No current channel"
                ]
            )
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
            chatService.setError(error)
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
        return currentSearchQuery.isEmpty ? chatService.messages : searchResults
    }
    
    /// Checks if we're currently in search mode
    var isInSearchMode: Bool {
        return !currentSearchQuery.isEmpty
    }
}