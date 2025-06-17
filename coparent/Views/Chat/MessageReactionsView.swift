import SwiftUI
import SendbirdChatSDK

struct MessageReactionsView: View {
    let message: BaseMessage
    @State private var chatService = SendbirdChatService.shared
    @State private var toast: ToastData?
    
    private var reactions: [Reaction] {
        message.reactions.filter { !$0.userIds.isEmpty }
    }
    
    var body: some View {
        if !reactions.isEmpty {
            HStack(spacing: 8) {
                ForEach(Array(reactions.enumerated()), id: \.offset) { index, reaction in
                    ReactionCountView(
                        reaction: reaction,
                        message: message,
                        toast: $toast
                    )
                }
            }
            .toast($toast)
        }
    }
}

struct ReactionCountView: View {
    let reaction: Reaction
    let message: BaseMessage
    @Binding var toast: ToastData?
    @State private var chatService = SendbirdChatService.shared
    @State private var isAnimating = false
    
    private var hasUserReacted: Bool {
        guard let currentUserId = SendbirdChat.currentUser?.userId else { return false }
        return reaction.userIds.contains(currentUserId)
    }
    
    private var reactionCount: Int {
        reaction.userIds.count
    }
    
    var body: some View {
        Button(action: {
            toggleReaction()
        }) {
            HStack(spacing: 4) {
                Text(reaction.key)
                    .font(.system(size: 14))
                
                if reactionCount > 1 {
                    Text("\(reactionCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(hasUserReacted ? .white : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(hasUserReacted ? 
                          Color.blue.opacity(0.8) : 
                          Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(hasUserReacted ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(DesignSystem.Animation.spring, value: isAnimating)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Reaction \(reaction.key), \(reactionCount) users")
        .accessibilityHint(hasUserReacted ? "Double tap to remove your reaction" : "Double tap to add this reaction")
    }
    
    private func toggleReaction() {
        // Animate button press
        withAnimation(DesignSystem.Animation.easeOut) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(DesignSystem.Animation.easeIn) {
                isAnimating = false
            }
        }
        
        Task {
            do {
                if hasUserReacted {
                    try await chatService.removeReaction(from: message, key: reaction.key)
                    toast = ToastData.info("Reaction removed")
                } else {
                    try await chatService.addReaction(to: message, key: reaction.key)
                    toast = ToastData.success("Reaction added")
                }
            } catch {
                toast = ToastData.error("Failed to update reaction")
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Preview with multiple reactions
        MessageReactionsView(message: createMockMessageWithReactions())
        
        // Preview with single reaction
        MessageReactionsView(message: createMockMessageWithSingleReaction())
        
        // Preview with user's own reaction
        MessageReactionsView(message: createMockMessageWithUserReaction())
    }
    .padding()
    .background(Color(.systemBackground))
}

// MARK: - Preview Helpers
private func createMockMessageWithReactions() -> BaseMessage {
    let mockMessage = UserMessage()
    // Note: In real implementation, reactions would be populated by Sendbird
    // This is just for preview purposes
    return mockMessage
}

private func createMockMessageWithSingleReaction() -> BaseMessage {
    let mockMessage = UserMessage()
    return mockMessage
}

private func createMockMessageWithUserReaction() -> BaseMessage {
    let mockMessage = UserMessage()
    return mockMessage
}