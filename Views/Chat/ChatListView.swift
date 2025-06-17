import SwiftUI
import SendbirdChatSDK

struct ChatListView: View {
    @Environment(AppState.self) private var appState
    @State private var chatService = SendbirdChatService.shared
    @State private var showingNewChat = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Group {
                if chatService.isLoading {
                    ProgressView()
                } else if chatService.channels.isEmpty {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "message",
                        description: Text("Start a conversation with your matches")
                    )
                } else {
                    List {
                        ForEach(chatService.channels, id: \.channelUrl) { channel in
                            NavigationLink(destination: ChatDetailView(channel: channel)) {
                                ChatRowView(channel: channel)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewChat = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView()
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
                    try await chatService.fetchChannels()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct ChatRowView: View {
    let channel: GroupChannel
    @State private var otherUser: User?
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else if let user = otherUser {
                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name ?? "Unknown User")
                    .font(.headline)
                
                if let lastMessage = channel.lastMessage {
                    Text(lastMessage.message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let lastMessage = channel.lastMessage {
                    Text(lastMessage.createdAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if channel.unreadMessageCount > 0 {
                    Text("\(channel.unreadMessageCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
        .task {
            await loadOtherUser()
        }
    }
    
    private func loadOtherUser() async {
        guard let otherMember = channel.members.first(where: { $0.userId != SendbirdChat.currentUser?.userId }) else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userService = UserService()
            otherUser = try await userService.fetchUser(id: otherMember.userId)
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}

#Preview {
    ChatListView()
        .environment(AppState())
} 