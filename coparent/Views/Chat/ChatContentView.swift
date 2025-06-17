import SwiftUI
import SendbirdChatSDK

struct ChatContentView: View {
    @ObservedObject var chatService: SendbirdChatService
    @Binding var scrollPositionId: Int64?
    let onError: (String) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Loading indicator for older messages
                    if chatService.isLoadingOlderMessages {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading older messages...")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    
                    ForEach(chatService.messages, id: \.messageId) { message in
                        MessageBubbleView(message: message)
                            .id(message.messageId)
                            .onAppear {
                                // Infinite scrolling: Load older messages when near the top
                                if message == chatService.messages.first,
                                   chatService.hasMoreMessages,
                                   !chatService.isLoadingOlderMessages {
                                    Task {
                                        do {
                                            try await chatService.loadOlderMessages()
                                        } catch {
                                            onError(error.localizedDescription)
                                        }
                                    }
                                }
                            }
                    }
                    
                    // Typing indicator
                    if chatService.isAnyoneTyping {
                        TypingIndicatorView()
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding()
            }
            .refreshable {
                // Pull-to-refresh functionality
                do {
                    try await chatService.refreshMessages()
                } catch {
                    onError(error.localizedDescription)
                }
            }
            .onChange(of: chatService.messages) { _ in
                scrollToLatestMessage(proxy: proxy, animated: true)
            }
            .onChange(of: scrollPositionId) { _ in
                if let messageId = scrollPositionId {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(messageId, anchor: .center)
                    }
                    scrollPositionId = nil
                }
            }
        }
    }
    
    private func scrollToLatestMessage(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastMessage = chatService.messages.last else { return }
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
        }
    }
}

#Preview {
    ChatContentView(
        chatService: SendbirdChatService.shared,
        scrollPositionId: .constant(nil),
        onError: { _ in }
    )
} 
