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
    
    // MARK: - Advanced Chat Features
    @State private var showingSearchBar = false
    @State private var searchText = ""
    @State private var searchTimer: Timer?
    @State private var scrollPositionId: Int64?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar (when active)
            if showingSearchBar {
                ChatSearchBar(
                    searchText: $searchText,
                    onSearchSubmit: {
                        performSearch()
                    },
                    onSearchCancel: {
                        cancelSearch()
                    }
                )
                .focused($isSearchFocused)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main Content
            if chatService.isInSearchMode {
                // Search Results View
                ChatSearchResultsView(
                    searchResults: chatService.searchResults,
                    searchQuery: chatService.currentSearchQuery,
                    isSearching: chatService.isSearching,
                    onMessageTap: { message in
                        jumpToMessage(message)
                    }
                )
            } else {
                // Normal Chat View
                ChatContentView(
                    chatService: chatService,
                    scrollPositionId: $scrollPositionId,
                    onError: { error in
                        errorMessage = error
                        showingError = true
                    }
                )
            }
            
            // Input Bar (hidden during search)
            if !chatService.isInSearchMode {
                Divider()
                    .background(.ultraThinMaterial)
                
                MessageInputView(
                    messageText: $messageText,
                    showingImagePicker: $showingImagePicker,
                    showingVoiceMessageView: $showingVoiceMessageView,
                    isUploading: $isUploading,
                    isInputFocused: _isInputFocused,
                    onSend: sendMessage,
                    onTyping: handleTypingIndicator
                )
            }
        }
        .navigationTitle(channel.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleSearch) {
                    Image(systemName: showingSearchBar ? "xmark" : "magnifyingglass")
                        .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                }
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
        .onChange(of: searchText) { oldValue, newValue in
            handleSearchTextChange(newValue)
        }
        .animation(.easeInOut(duration: 0.2), value: showingSearchBar)
        .animation(.easeInOut(duration: 0.2), value: chatService.isInSearchMode)
    }
    
    // MARK: - Message Handling
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            do {
                try await chatService.sendMessage(trimmedText, in: channel)
                messageText = ""
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func sendImages() {
        guard !selectedImages.isEmpty else { return }
        
        Task {
            isUploading = true
            do {
                try await chatService.sendImages(selectedImages, in: channel)
                showingImagePreview = false
                selectedImages.removeAll()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isUploading = false
        }
    }
    
    // MARK: - Search Handling
    
    private func toggleSearch() {
        withAnimation {
            showingSearchBar.toggle()
            if !showingSearchBar {
                cancelSearch()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        Task {
            do {
                try await chatService.searchMessages(searchText, in: channel)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func cancelSearch() {
        searchText = ""
        chatService.clearSearch()
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            if !newValue.isEmpty {
                performSearch()
            }
        }
    }
    
    private func jumpToMessage(_ message: BaseMessage) {
        scrollPositionId = message.messageId
        showingSearchBar = false
        cancelSearch()
    }
    
    // MARK: - Typing Indicator
    
    private func handleTypingIndicator(oldText: String, newText: String) {
        // Only send typing status if text changed
        guard oldText != newText else { return }
        
        // Cancel existing timer
        typingTimer?.invalidate()
        
        // Start new timer
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                do {
                    try await chatService.sendTypingStatus(true, in: channel)
                    
                    // Stop typing status after 2 seconds
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    try await chatService.sendTypingStatus(false, in: channel)
                } catch {
                    print("Error sending typing status: \(error)")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatDetailView(channel: GroupChannel())
    }
} 