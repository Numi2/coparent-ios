import SwiftUI
import SendbirdChatSDK

struct ThreadIndicatorView: View {
    let message: BaseMessage
    let onTapThread: () -> Void
    @State private var chatService = SendbirdChatService.shared
    
    private var threadReplyCount: Int {
        chatService.getThreadReplyCount(for: message)
    }
    
    private var hasThread: Bool {
        chatService.hasThread(for: message)
    }
    
    var body: some View {
        if hasThread {
            Button(action: onTapThread) {
                HStack(spacing: 8) {
                    // Thread icon
                    Image(systemName: "text.bubble.rtl")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    // Reply count and text
                    Text(replyCountText)
                        .font(DesignSystem.Typography.caption.weight(.medium))
                        .foregroundColor(.blue)
                    
                    // Arrow indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(0.95)
                .animation(DesignSystem.Animation.spring, value: hasThread)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("View thread with \(threadReplyCount) \(threadReplyCount == 1 ? "reply" : "replies")")
            .accessibilityHint("Double tap to open thread conversation")
        }
    }
    
    private var replyCountText: String {
        if threadReplyCount == 1 {
            return "1 reply"
        } else {
            return "\(threadReplyCount) replies"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        // Message with thread
        ThreadIndicatorView(
            message: SampleData.sampleMessageWithThread,
            onTapThread: {
                print("Thread tapped")
            }
        )
        
        // Message with multiple replies
        ThreadIndicatorView(
            message: SampleData.sampleMessageWithMultipleReplies,
            onTapThread: {
                print("Thread tapped")
            }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - Sample Data for Preview
private struct SampleData {
    static let sampleMessageWithThread: BaseMessage = {
        let message = UserMessage()
        // In a real implementation, this would have proper thread info
        return message
    }()
    
    static let sampleMessageWithMultipleReplies: BaseMessage = {
        let message = UserMessage()
        // In a real implementation, this would have proper thread info
        return message
    }()
}
