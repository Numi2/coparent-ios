import Foundation
import SendbirdChatSDK
import UIKit

@Observable
class SendbirdThreadingService {
    private let chatService: SendbirdChatService
    
    private(set) var currentThread: BaseMessage?
    private(set) var threadMessages: [BaseMessage] = []
    private(set) var isLoadingThread = false
    
    static let shared = SendbirdThreadingService()
    
    private init() {
        self.chatService = SendbirdChatService.shared
    }
    
    // MARK: - Message Threading
    
    func fetchThreadMessages(for parentMessage: BaseMessage) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -1, 
                userInfo: [
                    NSLocalizedDescriptionKey: "SDK not initialized"
                ]
            )
        }
        
        guard let channel = chatService.currentChannel else {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -8, 
                userInfo: [
                    NSLocalizedDescriptionKey: "No current channel"
                ]
            )
        }
        
        isLoadingThread = true
        defer { isLoadingThread = false }
        
        do {
            let params = ThreadMessageListParams()
            params.prevResultSize = AppConfig.Chat.messagePageSize
            params.nextResultSize = 0
            params.includeReactions = true
            params.includeThreadInfo = true
            
            let threadedMessages = try await channel.getThreadedMessages(
                parentMessageId: parentMessage.messageId, 
                params: params
            )
            
            await MainActor.run {
                self.currentThread = parentMessage
                self.threadMessages = threadedMessages
            }
        } catch {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -9, 
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to fetch thread messages: \(error.localizedDescription)"
                ]
            )
        }
    }
    
    func sendThreadMessage(_ text: String, to parentMessage: BaseMessage) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -1, 
                userInfo: [
                    NSLocalizedDescriptionKey: "SDK not initialized"
                ]
            )
        }
        
        guard let channel = chatService.currentChannel else {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -8, 
                userInfo: [
                    NSLocalizedDescriptionKey: "No current channel"
                ]
            )
        }
        
        do {
            let params = UserMessageCreateParams(message: text)
            params.parentMessageId = parentMessage.messageId
            
            let message = try await channel.sendUserMessage(params: params)
            
            await MainActor.run {
                self.threadMessages.append(message)
                updateParentMessageThreadInfo(parentMessage, in: channel)
            }
        } catch {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -10, 
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to send thread message: \(error.localizedDescription)"
                ]
            )
        }
    }
    
    func sendThreadImage(_ image: UIImage, to parentMessage: BaseMessage) async throws {
        guard SendbirdChat.isInitialized else {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -1, 
                userInfo: [
                    NSLocalizedDescriptionKey: "SDK not initialized"
                ]
            )
        }
        
        guard let channel = chatService.currentChannel else {
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -8, 
                userInfo: [
                    NSLocalizedDescriptionKey: "No current channel"
                ]
            )
        }
        
        do {
            // Compress image if needed
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                throw NSError(
                    domain: "SendbirdThreadingService", 
                    code: -2, 
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to compress image"
                    ]
                )
            }
            
            // Check file size
            if imageData.count > AppConfig.Chat.maxImageSize {
                throw NSError(
                    domain: "SendbirdThreadingService", 
                    code: -3, 
                    userInfo: [
                        NSLocalizedDescriptionKey: "Image size exceeds maximum allowed size"
                    ]
                )
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
            throw NSError(
                domain: "SendbirdThreadingService", 
                code: -11, 
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to send thread image: \(error.localizedDescription)"
                ]
            )
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
    
    // MARK: - Private Methods
    
    private func updateParentMessageThreadInfo(
        _ parentMessage: BaseMessage, 
        in channel: GroupChannel
    ) {
        // Update parent message in main messages list to show thread indicator
        Task {
            do {
                let messageParams = MessageRetrievalParams()
                messageParams.messageId = parentMessage.messageId
                messageParams.includeThreadInfo = true
                messageParams.includeReactions = true
                
                if let updatedParent = try await channel.getMessage(params: messageParams) {
                    await MainActor.run {
                        chatService.updateMessageInList(updatedParent)
                    }
                }
            } catch {
                print("Failed to update parent message with thread info: \(error)")
            }
        }
    }
}