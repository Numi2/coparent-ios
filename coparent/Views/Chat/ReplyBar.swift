import SwiftUI
import SendbirdChatSDK

struct ReplyBar: View {
    let parentMessage: BaseMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Reply to")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                Text(parentMessage.sender?.nickname ?? "Unknown")
                    .font(DesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(parentMessage.createdAt, style: .time)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 6)
            
            // Message preview
            HStack(spacing: 12) {
                // Message type indicator
                messageTypeIcon
                    .foregroundColor(.secondary)
                
                // Message content preview
                messageContentPreview
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .padding(DesignSystem.Layout.padding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .fill(Color.blue.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var messageTypeIcon: some View {
        if let userMessage = parentMessage as? UserMessage {
            Image(systemName: "text.bubble")
                .font(.system(size: 16, weight: .medium))
        } else if let fileMessage = parentMessage as? FileMessage {
            if fileMessage.mimeType.starts(with: "image/") {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .medium))
            } else if fileMessage.mimeType == "audio/m4a" {
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .medium))
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    @ViewBuilder
    private var messageContentPreview: some View {
        if let userMessage = parentMessage as? UserMessage {
            Text(userMessage.message)
        } else if let fileMessage = parentMessage as? FileMessage {
            if fileMessage.mimeType.starts(with: "image/") {
                Text("📷 Photo")
                    .italic()
            } else if fileMessage.mimeType == "audio/m4a" {
                Text("🎵 Voice message")
                    .italic()
            } else {
                Text("📎 \(fileMessage.name)")
                    .italic()
            }
        } else {
            Text("Message")
                .italic()
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        // Text message preview
        ReplyBar(parentMessage: SampleData.sampleTextMessage)
        
        // Image message preview
        ReplyBar(parentMessage: SampleData.sampleImageMessage)
        
        // Voice message preview
        ReplyBar(parentMessage: SampleData.sampleVoiceMessage)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - Sample Data for Preview
private struct SampleData {
    static let sampleTextMessage: UserMessage = {
        let message = UserMessage()
        // In a real implementation, these would be set properly
        // This is simplified for preview purposes
        return message
    }()
    
    static let sampleImageMessage: FileMessage = {
        let message = FileMessage()
        // In a real implementation, these would be set properly
        return message
    }()
    
    static let sampleVoiceMessage: FileMessage = {
        let message = FileMessage()
        // In a real implementation, these would be set properly
        return message
    }()
}
