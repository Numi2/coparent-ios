import SwiftUI
import SendbirdChatSDK

struct ReactionPickerView: View {
    let message: BaseMessage
    @State private var chatService = SendbirdChatService.shared
    @Binding var isPresented: Bool
    @State private var toast: ToastData?
    
    // Common emoji reactions
    private let commonReactions = ["👍", "❤️", "😂", "😮", "😢", "😡", "🎉", "👏"]
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Handle for drag gesture
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Title
            Text("Add Reaction")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            // Reaction grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: DesignSystem.Layout.spacing) {
                ForEach(commonReactions, id: \.self) { emoji in
                    ReactionButton(
                        emoji: emoji,
                        message: message,
                        isPresented: $isPresented,
                        toast: $toast
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Layout.padding)
            
            // Close button
            Button("Close") {
                withAnimation(DesignSystem.Animation.spring) {
                    isPresented = false
                }
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.horizontal, DesignSystem.Layout.padding)
            .padding(.bottom, DesignSystem.Layout.padding)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(DesignSystem.Layout.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        .toast($toast)
    }
}

struct ReactionButton: View {
    let emoji: String
    let message: BaseMessage
    @Binding var isPresented: Bool
    @Binding var toast: ToastData?
    @State private var chatService = SendbirdChatService.shared
    @State private var isAnimating = false
    
    private var hasUserReacted: Bool {
        chatService.hasUserReacted(to: message, with: emoji)
    }
    
    var body: some View {
        Button(action: {
            addReaction()
        }) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(hasUserReacted ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(hasUserReacted ? Color.blue : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(DesignSystem.Animation.spring, value: isAnimating)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("React with \(emoji)")
        .accessibilityHint(hasUserReacted ? "Double tap to remove reaction" : "Double tap to add reaction")
    }
    
    private func addReaction() {
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
                    try await chatService.removeReaction(from: message, key: emoji)
                    toast = ToastData.info("Reaction removed")
                } else {
                    try await chatService.addReaction(to: message, key: emoji)
                    toast = ToastData.success("Reaction added")
                }
                
                // Close picker after successful reaction
                withAnimation(DesignSystem.Animation.spring) {
                    isPresented = false
                }
            } catch {
                toast = ToastData.error("Failed to add reaction")
            }
        }
    }
}

#Preview {
    // Create a mock message for preview
    struct MockPreview: View {
        @State private var isPresented = true
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                if isPresented {
                    VStack {
                        Spacer()
                        ReactionPickerView(
                            message: createMockMessage(),
                            isPresented: $isPresented
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        
        private func createMockMessage() -> BaseMessage {
            // This is a simplified mock for preview purposes
            // In real app, this would be a proper Sendbird message
            let mockMessage = UserMessage()
            return mockMessage
        }
    }
    
    return MockPreview()
}