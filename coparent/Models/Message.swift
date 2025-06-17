import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    var isRead: Bool
    var type: MessageType
    
    enum MessageType: String, Codable {
        case text
        case image
        case system
    }
}

struct Chat: Identifiable, Codable {
    let id: String
    let participants: [String] // User IDs
    let lastMessage: Message?
    let createdAt: Date
    var updatedAt: Date
    var unreadMessages: [String: Int] // [userId: count]
    
    var unreadCount: Int {
        guard let currentUserId = AuthService.shared.currentUser?.id else { return 0 }
        return unreadMessages[currentUserId] ?? 0
    }
    
    mutating func incrementUnreadCount(for userId: String) {
        unreadMessages[userId, default: 0] += 1
    }
    
    mutating func resetUnreadCount(for userId: String) {
        unreadMessages[userId] = 0
    }
}

extension Message {
    static func createSystemMessage(
        for chatId: String,
        content: String
    ) -> Message {
        Message(
            id: UUID().uuidString,
            senderId: "system",
            receiverId: chatId,
            content: content,
            timestamp: Date(),
            isRead: true,
            type: .system
        )
    }
}
