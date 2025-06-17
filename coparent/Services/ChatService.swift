import Foundation
#if false // TODO: Re-enable when Firebase is added
import FirebaseFirestore
import FirebaseFirestoreSwift
#endif

class ChatService: ObservableObject {
    #if false // TODO: Re-enable when Firebase is added
    private let db = Firestore.firestore()
    #endif
    @Published var chats: [Chat] = []
    @Published var currentChat: Chat?
    @Published var messages: [Message] = []
    
    func fetchChats(for userId: String) async throws {
        #if false // TODO: Re-enable when Firebase is added
        let snapshot = try await db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        let chats = try snapshot.documents.compactMap { document -> Chat? in
            try document.data(as: Chat.self)
        }
        
        await MainActor.run {
            self.chats = chats
        }
        #else
        // Mock implementation for testing
        await MainActor.run {
            self.chats = []
        }
        #endif
    }
    
    func fetchMessages(for chatId: String) async throws {
        #if false // TODO: Re-enable when Firebase is added
        let snapshot = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        let messages = try snapshot.documents.compactMap { document -> Message? in
            try document.data(as: Message.self)
        }
        
        await MainActor.run {
            self.messages = messages
        }
        #else
        // Mock implementation for testing
        await MainActor.run {
            self.messages = []
        }
        #endif
    }
    
    func sendMessage(_ message: Message, in chatId: String) async throws {
        #if false // TODO: Re-enable when Firebase is added
        try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .document(message.id)
            .setData(from: message)
        
        // Update chat's last message and timestamp
        try await db.collection("chats")
            .document(chatId)
            .updateData([
                "lastMessage": message,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        
        // Add message to local state
        await MainActor.run {
            self.messages.append(message)
        }
        #else
        // Mock implementation for testing
        await MainActor.run {
            self.messages.append(message)
        }
        #endif
    }
    
    func markMessagesAsRead(in chatId: String, for userId: String) async throws {
        #if false // TODO: Re-enable when Firebase is added
        let snapshot = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.updateData([
                "isRead": true
            ])
        }
        #endif
        // Mock implementation - no-op for testing
    }
    
    func createChat(with participants: [String]) async throws -> Chat {
        let chat = Chat(
            id: UUID().uuidString,
            participants: participants,
            lastMessage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        #if false // TODO: Re-enable when Firebase is added
        try await db.collection("chats")
            .document(chat.id)
            .setData(from: chat)
        
        // Add system message
        let systemMessage = Message.createSystemMessage(
            for: chat.id,
            content: "Chat started"
        )
        
        try await sendMessage(systemMessage, in: chat.id)
        #endif
        
        return chat
    }
    
    func deleteChat(_ chatId: String) async throws {
        #if false // TODO: Re-enable when Firebase is added
        // Delete all messages
        let messagesSnapshot = try await db.collection("chats")
            .document(chatId)
            .collection("messages")
            .getDocuments()
        
        for document in messagesSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete chat document
        try await db.collection("chats")
            .document(chatId)
            .delete()
        #endif
        
        // Update local state
        await MainActor.run {
            self.chats.removeAll { $0.id == chatId }
            if self.currentChat?.id == chatId {
                self.currentChat = nil
                self.messages = []
            }
        }
    }
} 
