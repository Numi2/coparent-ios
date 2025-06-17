import SwiftUI
import SendbirdChatSDK

struct ThreadView: View {
    let channel: GroupChannel
    let parentMessage: BaseMessage
    @State private var chatService = SendbirdChatService.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePreview = false
    @FocusState private var isInputFocused: Bool
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isUploading = false
    @State private var toast: ToastData?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Parent message context
            ReplyContextBar(parentMessage: parentMessage) {
                dismiss()
            }
            
            Divider()
                .background(.ultraThinMaterial)
            
            // Thread messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatService.threadMessages, id: \.messageId) { message in
                            MessageBubbleView(message: message)
                                .id(message.messageId)
                        }
                        
                        // Loading indicator for thread
                        if chatService.isLoadingThread {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.threadMessages) { _ in
                    if let lastMessage = chatService.threadMessages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .background(.ultraThinMaterial)
            
            // Thread message input
            ThreadMessageInput(
                messageText: $messageText,
                isInputFocused: $isInputFocused,
                isUploading: $isUploading,
                showingImagePicker: $showingImagePicker,
                onSend: sendThreadMessage
            )
        }
        .navigationTitle("Thread")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    chatService.exitThread()
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("\(chatService.getThreadReplyCount(for: parentMessage)) replies")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ModernImagePicker(
                selectedImages: $selectedImages,
                maxSelection: 5
            ) {
                showingImagePicker = false
                if !selectedImages.isEmpty {
                    showingImagePreview = true
                }
            }
        }
        .sheet(isPresented: $showingImagePreview) {
            ImagePreviewView(
                images: $selectedImages,
                onSend: sendThreadImages,
                onCancel: {
                    showingImagePreview = false
                    selectedImages.removeAll()
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            do {
                try await chatService.fetchThreadMessages(for: parentMessage)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .toast($toast)
    }
    
    private func sendThreadMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                try await chatService.sendThreadMessage(messageText, to: parentMessage)
                await MainActor.run {
                    messageText = ""
                }
                toast = ToastData.success("Reply sent")
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func sendThreadImages(_ images: [UIImage]) {
        Task {
            isUploading = true
            defer { isUploading = false }
            
            do {
                for image in images {
                    try await chatService.sendThreadImage(image, to: parentMessage)
                }
                await MainActor.run {
                    selectedImages.removeAll()
                    showingImagePreview = false
                }
                toast = ToastData.success("Images sent to thread")
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct ReplyContextBar: View {
    let parentMessage: BaseMessage
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Parent message context
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Replying to \(parentMessage.sender?.nickname ?? "Unknown")")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.blue)
                }
                
                if let userMessage = parentMessage as? UserMessage {
                    Text(userMessage.message)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                } else if let fileMessage = parentMessage as? FileMessage {
                    HStack {
                        Image(systemName: fileMessage.mimeType.starts(with: "image/") ? "photo" : "doc")
                            .foregroundColor(.secondary)
                        Text(fileMessage.name)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.gray.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(DesignSystem.Layout.padding)
        .background(.ultraThinMaterial)
        .accessibilityLabel("Reply context: \(parentMessage.sender?.nickname ?? "Unknown")")
    }
}

struct ThreadMessageInput: View {
    @Binding var messageText: String
    @FocusState.Binding var isInputFocused: Bool
    @Binding var isUploading: Bool
    @Binding var showingImagePicker: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Image button
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo")
                    .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: DesignSystem.Layout.buttonHeight, 
                           height: DesignSystem.Layout.buttonHeight)
                    .background(Color.blue.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(isUploading)
            .accessibilityLabel("Add photo to thread")
            
            // Message text field
            TextField("Reply to thread...", text: $messageText)
                .textFieldStyle(GlassTextFieldStyle())
                .focused($isInputFocused)
                .disabled(isUploading)
                .onSubmit {
                    onSend()
                }
            
            // Send button
            Button(action: onSend) {
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: DesignSystem.Layout.buttonHeight, 
                               height: DesignSystem.Layout.buttonHeight)
                        .background(Color.blue.opacity(0.1))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                } else {
                    Image(systemName: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                          "arrow.up.circle" : "arrow.up.circle.fill")
                        .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: DesignSystem.Layout.buttonHeight, 
                               height: DesignSystem.Layout.buttonHeight)
                        .background(Color.blue.opacity(0.1))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .scaleEffect(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                        .animation(DesignSystem.Animation.spring, value: messageText.isEmpty)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
            .accessibilityLabel(isUploading ? "Uploading images to thread" : "Send reply to thread")
        }
        .padding(DesignSystem.Layout.padding)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    NavigationView {
        ThreadView(
            channel: GroupChannel(),
            parentMessage: createMockUserMessage()
        )
    }
}

#Preview("Reply Context Bar") {
    ReplyContextBar(
        parentMessage: createMockUserMessage(),
        onClose: {}
    )
}

#Preview("Thread Message Input") {
    @State var messageText = ""
    @State var isUploading = false
    @State var showingImagePicker = false
    @FocusState var isInputFocused: Bool
    
    return ThreadMessageInput(
        messageText: $messageText,
        isInputFocused: $isInputFocused,
        isUploading: $isUploading,
        showingImagePicker: $showingImagePicker,
        onSend: {}
    )
}

// MARK: - Preview Helpers
private func createMockUserMessage() -> BaseMessage {
    let mockMessage = UserMessage()
    return mockMessage
}