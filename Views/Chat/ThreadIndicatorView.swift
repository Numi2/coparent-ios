import SwiftUI
import SendbirdChatSDK

struct ThreadIndicatorView: View {
    let message: BaseMessage
    let onThreadTap: () -> Void
    @State private var chatService = SendbirdChatService.shared
    
    private var replyCount: Int {
        chatService.getThreadReplyCount(for: message)
    }
    
    private var hasThread: Bool {
        chatService.hasThread(for: message)
    }
    
    var body: some View {
        if hasThread {
            Button(action: onThreadTap) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("\(replyCount) \(replyCount == 1 ? "reply" : "replies")")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Thread with \(replyCount) replies. Double tap to view.")
            .accessibilityHint("Opens the thread conversation")
        }
    }
}

struct ThreadPreviewView: View {
    let message: BaseMessage
    let onThreadTap: () -> Void
    @State private var chatService = SendbirdChatService.shared
    
    private var replyCount: Int {
        chatService.getThreadReplyCount(for: message)
    }
    
    private var lastRepliedAt: Date? {
        message.threadInfo?.lastRepliedAt
    }
    
    var body: some View {
        if chatService.hasThread(for: message) {
            Button(action: onThreadTap) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("\(replyCount) \(replyCount == 1 ? "reply" : "replies")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        if let lastRepliedAt = lastRepliedAt {
                            Text(lastRepliedAt, style: .relative)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue.opacity(0.6))
                    }
                    
                    // Show preview of latest thread participants
                    if let threadInfo = message.threadInfo,
                       !threadInfo.mostRepliedUsers.isEmpty {
                        HStack(spacing: 4) {
                            Text("Latest:")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text(threadInfo.mostRepliedUsers.prefix(3).compactMap { $0.nickname }.joined(separator: ", "))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Thread with \(replyCount) replies. Last activity \(lastRepliedAt?.formatted(.relative(presentation: .named)) ?? "recently"). Double tap to view.")
        }
    }
}

#Preview("Thread Indicator") {
    VStack(spacing: 16) {
        ThreadIndicatorView(
            message: createMockMessageWithThread(),
            onThreadTap: {}
        )
        
        ThreadPreviewView(
            message: createMockMessageWithThread(),
            onThreadTap: {}
        )
    }
    .padding()
}

// MARK: - Preview Helpers
private func createMockMessageWithThread() -> BaseMessage {
    let mockMessage = UserMessage()
    // Note: In real implementation, threadInfo would be populated by Sendbird
    // This is just for preview purposes
    return mockMessage
}