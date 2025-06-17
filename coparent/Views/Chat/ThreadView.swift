import SwiftUI
import SendbirdChatSDK

struct ThreadView: View {
    let parentMessage: BaseMessage
    let channel: GroupChannel
    @State private var chatService = SendbirdChatService.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePreview = false
    @FocusState private var isInputFocused: Bool
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isUploading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Parent message context
                ReplyBar(parentMessage: parentMessage)
                    .padding(.horizontal)
                    .padding(.top, 8)

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
                threadMessageInput
            }
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        chatService.exitThread()
                        dismiss()
                    }
                    .font(DesignSystem.Typography.body.weight(.medium))
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
        }
    }

    @ViewBuilder
    private var threadMessageInput: some View {
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
            TextField("Reply in thread", text: $messageText)
                .textFieldStyle(GlassTextFieldStyle())
                .focused($isInputFocused)
                .disabled(isUploading)
                .onSubmit {
                    sendThreadMessage()
                }

            // Send button
            Button(action: sendThreadMessage) {
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
            .accessibilityLabel(isUploading ? "Uploading images" : "Send thread message")
        }
        .padding(DesignSystem.Layout.padding)
        .background(.ultraThinMaterial)
    }

    private func sendThreadMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            do {
                try await chatService.sendThreadMessage(messageText, to: parentMessage)
                await MainActor.run {
                    messageText = ""
                }
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
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    ThreadView(
        parentMessage: SampleData.sampleUserMessage,
        channel: SampleData.sampleChannel
    )
}

// MARK: - Sample Data for Preview
private struct SampleData {
    static let sampleUserMessage: UserMessage = {
        // This would normally be created from Sendbird, simplified for preview
        return UserMessage()
    }()

    static let sampleChannel: GroupChannel = {
        // This would normally be created from Sendbird, simplified for preview
        return GroupChannel()
    }()
}
