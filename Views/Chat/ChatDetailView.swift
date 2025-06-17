import SwiftUI
import SendbirdChatSDK
import Foundation

struct ChatDetailView: View {
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
    @State private var showingVoiceMessageView = false
    @State private var typingTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatService.messages, id: \.messageId) { message in
                            MessageBubbleView(message: message)
                                .id(message.messageId)
                        }
                        
                        // Typing indicator
                        if chatService.isAnyoneTyping {
                            TypingIndicatorView()
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.messages) { _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
                .background(.ultraThinMaterial)
            
            // Message Input
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
                .accessibilityLabel("Add photo")
                
                // Voice message button
                Button(action: { showingVoiceMessageView = true }) {
                    Image(systemName: "mic")
                        .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: DesignSystem.Layout.buttonHeight, 
                               height: DesignSystem.Layout.buttonHeight)
                        .background(Color.blue.opacity(0.1))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(isUploading)
                .accessibilityLabel("Record voice message")
                
                // Message text field
                TextField("Message", text: $messageText)
                    .textFieldStyle(GlassTextFieldStyle())
                    .focused($isInputFocused)
                    .disabled(isUploading)
                    .onSubmit {
                        sendMessage()
                    }
                    .onChange(of: messageText) { oldValue, newValue in
                        handleTypingIndicator(oldText: oldValue, newText: newValue)
                    }
                
                // Send button
                Button(action: sendMessage) {
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
                .accessibilityLabel(isUploading ? "Uploading images" : "Send message")
            }
            .padding(DesignSystem.Layout.padding)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(channel.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
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
                onSend: sendImages,
                onCancel: {
                    showingImagePreview = false
                    selectedImages.removeAll()
                }
            )
        }
        .sheet(isPresented: $showingVoiceMessageView) {
            VoiceMessageView { url in
                Task {
                    do {
                        try await chatService.sendVoiceMessage(url, in: channel)
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
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
                try await chatService.fetchMessages(for: channel)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                try await chatService.sendMessage(messageText, in: channel)
                await MainActor.run {
                    messageText = ""
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func sendImages(_ images: [UIImage]) {
        Task {
            isUploading = true
            defer { isUploading = false }
            
            do {
                if images.count == 1 {
                    try await chatService.sendImage(images[0], in: channel)
                } else {
                    try await chatService.sendImages(images, in: channel)
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
    
    private func handleTypingIndicator(oldText: String, newText: String) {
        guard let channel = chatService.currentChannel else { return }
        
        // Cancel previous timer
        typingTimer?.invalidate()
        
        // If user is typing (text is not empty and changed)
        if !newText.isEmpty && oldText != newText {
            chatService.startTyping(in: channel)
            
            // Set timer to stop typing after 3 seconds of inactivity
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                chatService.endTyping(in: channel)
            }
        } else if newText.isEmpty {
            // Stop typing if text becomes empty
            chatService.endTyping(in: channel)
        }
    }
}

struct MessageBubbleView: View {
    let message: BaseMessage
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var messageStatusService = MessageStatusService.shared
    @State private var showingEditMessage = false
    @State private var showingDeleteConfirmation = false
    @State private var editText = ""
    @State private var toast: ToastData?
    
    private var isCurrentUser: Bool {
        message.sender?.userId == SendbirdChat.currentUser?.userId
    }
    
    private var messageStatus: MessageStatus {
        messageStatusService.getMessageStatus(message)
    }
    
    private var canEditOrDelete: Bool {
        isCurrentUser && message is UserMessage
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser { 
                Spacer(minLength: 60) 
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                // Message content
                messageContentView
                    .glassCard()
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .contextMenu {
                        MessageContextMenu(
                            message: message,
                            canEditOrDelete: canEditOrDelete,
                            onEdit: { 
                                if let userMessage = message as? UserMessage {
                                    editText = userMessage.message
                                    showingEditMessage = true
                                }
                            },
                            onDelete: { showingDeleteConfirmation = true },
                            onCopy: { 
                                if let userMessage = message as? UserMessage {
                                    UIPasteboard.general.string = userMessage.message
                                    toast = .success("Message copied")
                                }
                            },
                            onReply: { 
                                // TODO: Implement reply functionality
                            }
                        )
                    }
                
                // Message metadata
                HStack(spacing: 6) {
                    if !isCurrentUser {
                        Text(message.sender?.nickname ?? "Unknown")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.createdAt, style: .time)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    // Status indicators for current user messages
                    if isCurrentUser {
                        MessageStatusIndicator(status: messageStatus)
                    }
                }
            }
            
            if !isCurrentUser { 
                Spacer(minLength: 60) 
            }
        }
        .sheet(isPresented: $showingEditMessage) {
            EditMessageView(
                message: editText,
                onSave: { newText in
                    if let userMessage = message as? UserMessage {
                        Task {
                            do {
                                try await SendbirdChatService.shared.updateMessage(userMessage, with: newText)
                                await MainActor.run {
                                    toast = .success("Message updated")
                                }
                            } catch {
                                await MainActor.run {
                                    toast = .error("Failed to update message")
                                }
                            }
                        }
                    }
                },
                onCancel: { showingEditMessage = false }
            )
        }
        .alert("Delete Message", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await SendbirdChatService.shared.deleteMessage(message)
                        await MainActor.run {
                            toast = .success("Message deleted")
                        }
                    } catch {
                        await MainActor.run {
                            toast = .error("Failed to delete message")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this message? This action cannot be undone.")
        }
        .task {
            if let fileMessage = message as? FileMessage,
               fileMessage.mimeType.starts(with: "image/") {
                await loadImage(from: fileMessage)
            }
        }
        .toast($toast)
    }
    
    @ViewBuilder
    private var messageContentView: some View {
        if let userMessage = message as? UserMessage {
            Text(userMessage.message)
                .font(DesignSystem.Typography.body)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isCurrentUser ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isCurrentUser ? .white : .primary)
        } else if let fileMessage = message as? FileMessage {
            if fileMessage.mimeType.starts(with: "image/") {
                imageMessageView(fileMessage)
            } else if fileMessage.mimeType == "audio/m4a" {
                voiceMessageView(fileMessage)
            } else {
                fileMessageView(fileMessage)
            }
        }
    }
    
    @ViewBuilder
    private func imageMessageView(_ fileMessage: FileMessage) -> some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(width: 200, height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
            } else if let image = image {
                ImageMessageView(image: image, isCurrentUser: isCurrentUser)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(width: 200, height: 200)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
    }
    
    @ViewBuilder
    private func voiceMessageView(_ fileMessage: FileMessage) -> some View {
        if let url = URL(string: fileMessage.url) {
            VoiceMessagePlayerView(url: url, isCurrentUser: isCurrentUser)
        }
    }
    
    @ViewBuilder
    private func fileMessageView(_ fileMessage: FileMessage) -> some View {
        HStack {
            Image(systemName: "doc")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(fileMessage.name)
                    .font(DesignSystem.Typography.callout)
                    .lineLimit(1)
                
                if fileMessage.fileSize > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(fileMessage.fileSize), countStyle: .file))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func loadImage(from message: FileMessage) async {
        guard let url = URL(string: message.url) else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                await MainActor.run {
                    image = loadedImage
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}

struct MessageStatusIndicator: View {
    let status: MessageStatus
    @State private var messageStatusService = MessageStatusService.shared
    
    var body: some View {
        Group {
            if status != .none {
                HStack(spacing: 2) {
                    Image(systemName: messageStatusService.getStatusIcon(status))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(messageStatusService.getStatusColor(status))
                        .opacity(0.8)
                        .scaleEffect(status == .sending ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.2), value: status)
                    
                    if status == .sending {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 8, height: 8)
                    }
                }
                .accessibilityLabel(statusAccessibilityLabel)
            }
        }
    }
    
    private var statusAccessibilityLabel: String {
        switch status {
        case .sending: return "Sending message"
        case .sent: return "Message sent"
        case .delivered: return "Message delivered"
        case .read: return "Message read"
        case .failed: return "Message failed to send"
        case .none: return ""
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animationPhase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
            )
            .glassCard()
            
            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                animationPhase = 2
            }
        }
        .accessibilityLabel("Someone is typing")
    }
}

struct MessageContextMenu: View {
    let message: BaseMessage
    let canEditOrDelete: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void
    let onReply: () -> Void
    
    var body: some View {
        Group {
            if canEditOrDelete {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
            
            if message is UserMessage {
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            
            Button(action: onReply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
        }
    }
}

struct EditMessageView: View {
    @State private var message: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var isTextFieldFocused: Bool
    
    init(message: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self._message = State(initialValue: message)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Layout.spacing) {
                Text("Edit Message")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Message", text: $message, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .lineLimit(3...10)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Layout.spacing) {
                    Button("Cancel") {
                        onCancel()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.secondary)
                    
                    Button("Save") {
                        onSave(message)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(DesignSystem.Layout.padding)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

#Preview("Chat Detail View") {
    NavigationView {
        ChatDetailView(channel: GroupChannel())
    }
}

#Preview("Message Status Indicators") {
    VStack(spacing: 12) {
        MessageStatusIndicator(status: .sending)
        MessageStatusIndicator(status: .sent)
        MessageStatusIndicator(status: .delivered)
        MessageStatusIndicator(status: .read)
        MessageStatusIndicator(status: .failed)
    }
    .padding()
}

#Preview("Typing Indicator") {
    VStack {
        TypingIndicatorView()
        Spacer()
    }
    .padding()
}

#Preview("Edit Message View") {
    EditMessageView(
        message: "This is a sample message that can be edited",
        onSave: { _ in },
        onCancel: { }
    )
}

#Preview("Toast Notifications") {
    VStack(spacing: 20) {
        ToastView(
            message: "Message copied",
            systemImage: "checkmark.circle.fill",
            color: .green,
            isShowing: .constant(true)
        )
        
        ToastView(
            message: "Failed to delete message",
            systemImage: "exclamationmark.circle.fill",
            color: .red,
            isShowing: .constant(true)
        )
        
        ToastView(
            message: "Message updated",
            systemImage: "info.circle.fill",
            color: .blue,
            isShowing: .constant(true)
        )
    }
    .padding()
} 