import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var chatService = ChatService()
    @State private var showingNewChat = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(chatService.chats) { chat in
                    NavigationLink(destination: ChatDetailView(chat: chat)) {
                        ChatRowView(chat: chat)
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
            .task {
                do {
                    try await chatService.fetchChats(for: appState.currentUser?.id ?? "")
                } catch {
                    print("Error fetching chats: \(error)")
                }
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    @EnvironmentObject var appState: AppState
    @StateObject private var userService = UserService()
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
                Text(otherUser?.name ?? "Unknown User")
                    .font(.headline)
                
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
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
        guard let currentUserId = appState.currentUser?.id,
              let otherUserId = chat.participants.first(where: { $0 != currentUserId }) else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            otherUser = try await userService.fetchUser(id: otherUserId)
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
            .environmentObject(AppState())
    }
} 