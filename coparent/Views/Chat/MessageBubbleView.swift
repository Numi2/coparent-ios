import SwiftUI
import SendbirdChatSDK

struct MessageBubbleView: View {
    let message: BaseMessage
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var messageStatusService = MessageStatusService.shared
    @State private var showingEditMessage = false
    @State private var showingDeleteConfirmation = false
    @State private var showingReactionPicker = false
    @State private var showingThreadView = false
    @State private var editText = ""
    @State private var toast: ToastData?
    @State private var chatService = SendbirdChatService.shared
    
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

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(message: UserMessage())
        MessageStatusIndicator(status: .sending)
        MessageStatusIndicator(status: .sent)
        MessageStatusIndicator(status: .delivered)
        MessageStatusIndicator(status: .read)
        MessageStatusIndicator(status: .failed)
    }
    .padding()
} 
