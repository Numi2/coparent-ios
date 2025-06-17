import SwiftUI
import SendbirdChatSDK

struct ChatSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    let onSearchSubmit: () -> Void
    let onSearchCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search messages...", text: $searchText)
                    .font(DesignSystem.Typography.body)
                    .focused($isSearchFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        onSearchSubmit()
                    }
                    .onChange(of: searchText) { _, newValue in
                        // Trigger search with a slight delay for better performance
                        if newValue.isEmpty {
                            onSearchCancel()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        onSearchCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, DesignSystem.Layout.padding)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color(.systemGray6).opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            
            // Cancel button (only show when search is active)
            if isSearchFocused || !searchText.isEmpty {
                Button("Cancel") {
                    searchText = ""
                    isSearchFocused = false
                    onSearchCancel()
                }
                .font(DesignSystem.Typography.callout)
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, DesignSystem.Layout.padding)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
    }
}

struct ChatSearchResultsView: View {
    let searchResults: [BaseMessage]
    let searchQuery: String
    let isSearching: Bool
    let onMessageTap: (BaseMessage) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search results header
            HStack {
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(isSearching ? "Searching..." : "\(searchResults.count) results for '\(searchQuery)'")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(DesignSystem.Layout.padding)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Search results list
            if searchResults.isEmpty && !isSearching {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.secondary)
                    
                    Text("No messages found")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Try searching with different keywords")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.messageId) { message in
                            SearchResultRow(
                                message: message,
                                searchQuery: searchQuery,
                                onTap: { onMessageTap(message) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let message: BaseMessage
    let searchQuery: String
    let onTap: () -> Void
    
    private var isCurrentUser: Bool {
        message.sender?.userId == SendbirdChat.currentUser?.userId
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Sender and timestamp
                HStack {
                    Text(message.sender?.nickname ?? "Unknown")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isCurrentUser ? .blue : .secondary)
                    
                    Spacer()
                    
                    Text(message.createdAt, style: .relative)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                // Message content with highlighted search terms
                if let userMessage = message as? UserMessage {
                    Text(highlightedText(userMessage.message, searchQuery: searchQuery))
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                } else if let fileMessage = message as? FileMessage {
                    HStack {
                        Image(systemName: getFileIcon(for: fileMessage))
                            .foregroundColor(.blue)
                        
                        Text(fileMessage.name)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(DesignSystem.Layout.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color(.systemGray6).opacity(0.5))
                    .background(.ultraThinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func highlightedText(_ text: String, searchQuery: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if !searchQuery.isEmpty {
            let range = text.range(of: searchQuery, options: .caseInsensitive)
            if let range = range {
                let nsRange = NSRange(range, in: text)
                if let attributedRange = Range(nsRange, in: attributedString) {
                    attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
                    attributedString[attributedRange].foregroundColor = .primary
                }
            }
        }
        
        return attributedString
    }
    
    private func getFileIcon(for fileMessage: FileMessage) -> String {
        if fileMessage.mimeType.starts(with: "image/") {
            return "photo"
        } else if fileMessage.mimeType == "audio/m4a" {
            return "mic"
        } else {
            return "doc"
        }
    }
}

#Preview {
    VStack {
        ChatSearchBar(
            searchText: .constant("test"),
            onSearchSubmit: {},
            onSearchCancel: {}
        )
        
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Search Results") {
    ChatSearchResultsView(
        searchResults: [],
        searchQuery: "hello",
        isSearching: false,
        onMessageTap: { _ in }
    )
}