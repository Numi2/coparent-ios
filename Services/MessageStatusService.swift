import Foundation
import SwiftUI
import SendbirdChatSDK

@Observable
class MessageStatusService {
    static let shared = MessageStatusService()
    
    private init() {}
    
    func getMessageStatus(_ message: BaseMessage) -> MessageStatus {
        guard let userMessage = message as? UserMessage else {
            return .none
        }
        
        if userMessage.sendingStatus == .succeeded {
            if userMessage.readStatus == .read {
                return .read
            } else if userMessage.readStatus == .delivered {
                return .delivered
            } else {
                return .sent
            }
        } else if userMessage.sendingStatus == .failed {
            return .failed
        } else if userMessage.sendingStatus == .pending {
            return .sending
        }
        
        return .none
    }
    
    func getStatusIcon(_ status: MessageStatus) -> String {
        switch status {
        case .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .read:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle"
        case .none:
            return ""
        }
    }
    
    func getStatusColor(_ status: MessageStatus) -> Color {
        switch status {
        case .sending:
            return .gray
        case .sent:
            return .gray
        case .delivered:
            return .blue.opacity(0.7)
        case .read:
            return .blue
        case .failed:
            return .red
        case .none:
            return .clear
        }
    }
    
    // Convenience methods for UI
    func getStatusIcon(for message: BaseMessage) -> String {
        let status = getMessageStatus(message)
        return getStatusIcon(status)
    }
    
    func getStatusColor(for message: BaseMessage) -> Color {
        let status = getMessageStatus(message)
        return getStatusColor(status)
    }
}

enum MessageStatus {
    case sending
    case sent
    case delivered
    case read
    case failed
    case none
} 