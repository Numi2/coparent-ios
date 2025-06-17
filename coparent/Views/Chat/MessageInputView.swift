import SwiftUI
import SendbirdChatSDK

struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var showingImagePicker: Bool
    @Binding var showingVoiceMessageView: Bool
    @Binding var isUploading: Bool
    @FocusState var isInputFocused: Bool
    let onSend: () -> Void
    let onTyping: (String, String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Image button
            Button {
                showingImagePicker = true
            } label: {
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
            Button {
                showingVoiceMessageView = true
            } label: {
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
            TextField("Message", text: $messageText, axis: .vertical)
                .textFieldStyle(GlassTextFieldStyle())
                .focused($isInputFocused)
                .disabled(isUploading)
                .lineLimit(1...5)
                .onSubmit {
                    onSend()
                }
                .onChange(of: messageText) { oldValue, newValue in
                    onTyping(oldValue, newValue)
                }
            
            // Send button
            Button(action: onSend) {
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: DesignSystem.Layout.buttonHeight, 
                               height: DesignSystem.Layout.buttonHeight)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: DesignSystem.Layout.iconSize + 4, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: DesignSystem.Layout.buttonHeight, 
                               height: DesignSystem.Layout.buttonHeight)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, DesignSystem.Layout.padding)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    MessageInputView(
        messageText: .constant(""),
        showingImagePicker: .constant(false),
        showingVoiceMessageView: .constant(false),
        isUploading: .constant(false),
        onSend: {},
        onTyping: { _, _ in }
    )
} 