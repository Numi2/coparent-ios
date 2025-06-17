import SwiftUI
import SendbirdChatSDK

struct ChatDetailView: View {
    let channel: GroupChannel
    @State private var chatService = SendbirdChatService.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isUploading = false
    @State private var showingVoiceMessageView = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatService.messages, id: \.messageId) { message in
                            MessageBubbleView(message: message)
                                .id(message.messageId)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.messages) { _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.messageId, anchor: .bottom)
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
                .disabled(isUploading)
                
                Button(action: { showingVoiceMessageView = true }) {
                    Image(systemName: "mic")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .disabled(isUploading)
                
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .disabled(isUploading)
                
                Button(action: sendMessage) {
                    if isUploading {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
            }
            .padding()
        }
        .navigationTitle(channel.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
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
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                sendImage(image)
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
                messageText = ""
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func sendImage(_ image: UIImage) {
        Task {
            isUploading = true
            defer { isUploading = false }
            
            do {
                try await chatService.sendImage(image, in: channel)
                selectedImage = nil
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: BaseMessage
    @State private var image: UIImage?
    @State private var isLoading = false
    
    private var isCurrentUser: Bool {
        message.sender?.userId == SendbirdChat.currentUser?.userId
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if let userMessage = message as? UserMessage {
                    Text(userMessage.message)
                        .padding(12)
                        .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                } else if let fileMessage = message as? FileMessage {
                    if fileMessage.mimeType.starts(with: "image/") {
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
                    } else if fileMessage.mimeType == "audio/m4a" {
                        if let url = URL(string: fileMessage.url) {
                            VoiceMessagePlayerView(url: url, isCurrentUser: isCurrentUser)
                        }
                    }
                }
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .task {
            if let fileMessage = message as? FileMessage,
               fileMessage.mimeType.starts(with: "image/") {
                await loadImage(from: fileMessage)
            }
        }
    }
    
    private func loadImage(from message: FileMessage) async {
        guard let url = URL(string: message.url) else { return }
        
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

#Preview {
    NavigationView {
        ChatDetailView(channel: GroupChannel())
    }
} 