import SwiftUI
import SendbirdChatSDK

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
        guard let userMessage = message as? UserMessage else { return false }
        return isCurrentUser && userMessage.sendingStatus == .succeeded
    }
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            if let userMessage = message as? UserMessage {
                if userMessage.messageType == .user {
                    TextMessageView(message: userMessage)
                } else if userMessage.messageType == .file {
                    FileMessageView(message: userMessage)
                }
            }
            
            // Message status
            if isCurrentUser {
                HStack(spacing: 4) {
                    Text(messageStatusService.getStatusIcon(messageStatus))
                        .font(.system(size: 12))
                        .foregroundColor(messageStatusService.getStatusColor(messageStatus))
                }
                .padding(.trailing, 4)
            }
        }
        .contextMenu {
            if canEditOrDelete {
                Button(action: {
                    if let userMessage = message as? UserMessage {
                        editText = userMessage.message
                        showingEditMessage = true
                    }
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showingDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Edit Message", isPresented: $showingEditMessage) {
            TextField("Message", text: $editText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let userMessage = message as? UserMessage {
                    Task {
                        do {
                            try await SendbirdChatService.shared.updateMessage(userMessage, with: editText)
                        } catch {
                            toast = ToastData(message: error.localizedDescription, type: .error)
                        }
                    }
                }
            }
        }
        .alert("Delete Message", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let userMessage = message as? UserMessage {
                    Task {
                        do {
                            try await SendbirdChatService.shared.deleteMessage(userMessage)
                        } catch {
                            toast = ToastData(message: error.localizedDescription, type: .error)
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
        .toast(data: $toast)
    }
}

struct TextMessageView: View {
    let message: UserMessage
    
    var body: some View {
        Text(message.message)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(message.sender?.userId == SendbirdChat.currentUser?.userId ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(message.sender?.userId == SendbirdChat.currentUser?.userId ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FileMessageView: View {
    let message: UserMessage
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isLoading {
                ProgressView()
                    .frame(width: 200, height: 200)
            } else {
                Color.gray.opacity(0.2)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let fileMessage = message as? FileMessage,
              let url = fileMessage.url else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.image = image
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
} 