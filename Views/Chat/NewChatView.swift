import SwiftUI
import FirebaseFirestore
import SendbirdChatSDK

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var chatService = SendbirdChatService.shared
    @State private var searchText = ""
    @State private var selectedUsers: [User] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var users: [User] = []
    @State private var isLoading = false
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            (user.bio?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedUsers.isEmpty {
                    Text("Select users to start a chat")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedUsers) { user in
                                SelectedUserView(user: user) {
                                    selectedUsers.removeAll { $0.id == user.id }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredUsers) { user in
                            UserRowView(user: user) {
                                if !selectedUsers.contains(where: { $0.id == user.id }) {
                                    selectedUsers.append(user)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search users")
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        startChat()
                    }
                    .disabled(selectedUsers.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadUsers()
            }
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch users from Firestore
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users")
                .whereField("id", isNotEqualTo: appState.currentUser?.id ?? "")
                .getDocuments()
            
            users = try snapshot.documents.compactMap { document -> User? in
                try document.data(as: User.self)
            }
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func startChat() {
        guard !selectedUsers.isEmpty else { return }
        
        let participantIds = selectedUsers.map { $0.id }
        if let currentUserId = appState.currentUser?.id {
            let allParticipants = [currentUserId] + participantIds
            
            Task {
                do {
                    let channel = try await chatService.createChannel(with: allParticipants)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct SelectedUserView: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        VStack {
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
            
            Text(user.name)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .frame(width: 70)
    }
}

struct UserRowView: View {
    let user: User
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)
                    
                    if let bio = user.bio {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewChatView()
        .environment(AppState())
} 