import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    @EnvironmentObject var appState: AppState
    @StateObject private var chatService = ChatService()
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    @StateObject private var storageService = StorageService()
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatService.messages) { message in
                            MessageBubbleView(message: message, isCurrentUser: message.senderId == appState.currentUser?.id)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.messages) { _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Message Input
            HStack(spacing: 12) {
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(chat.participants.count > 2 ? "Group Chat" : "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                sendImage(image)
            }
        }
        .task {
            do {
                try await chatService.fetchMessages(for: chat.id)
                try await chatService.markMessagesAsRead(in: chat.id, for: appState.currentUser?.id ?? "")
            } catch {
                print("Error loading messages: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUser = appState.currentUser else { return }
        
        let message = Message(
            id: UUID().uuidString,
            senderId: currentUser.id,
            receiverId: chat.id,
            content: messageText,
            timestamp: Date(),
            isRead: false,
            type: .text
        )
        
        Task {
            do {
                try await chatService.sendMessage(message, in: chat.id)
                messageText = ""
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
    
    private func sendImage(_ image: UIImage) {
        guard let currentUser = appState.currentUser else { return }
        
        isUploading = true
        
        Task {
            do {
                // Upload image to Firebase Storage
                let path = "chat_images/\(chat.id)/\(UUID().uuidString).jpg"
                let imageURL = try await storageService.uploadImage(image, path: path)
                
                // Create and send message
                let message = Message(
                    id: UUID().uuidString,
                    senderId: currentUser.id,
                    receiverId: chat.id,
                    content: imageURL,
                    timestamp: Date(),
                    isRead: false,
                    type: .image
                )
                
                try await chatService.sendMessage(message, in: chat.id)
                selectedImage = nil
            } catch {
                errorMessage = "Failed to send image: \(error.localizedDescription)"
                showingError = true
            }
            
            isUploading = false
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if message.type == .text {
                    Text(message.content)
                        .padding(12)
                        .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                } else if message.type == .image {
                    if isLoading {
                        ProgressView()
                            .frame(width: 200, height: 200)
                    } else if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(16)
                    } else {
                        Color.gray.opacity(0.2)
                            .frame(width: 200, height: 200)
                            .cornerRadius(16)
                            .overlay(
                                ProgressView()
                            )
                    }
                } else if message.type == .system {
                    Text(message.content)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .task {
            if message.type == .image {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        guard let url = URL(string: message.content) else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let loadedImage = UIImage(data: data) {
                image = loadedImage
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatDetailView(chat: Chat(
                id: "preview",
                participants: ["user1", "user2"],
                lastMessage: nil,
                createdAt: Date(),
                updatedAt: Date()
            ))
            .environmentObject(AppState())
        }
    }
} 