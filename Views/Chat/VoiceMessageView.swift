import SwiftUI
import AVFoundation

struct VoiceMessageView: View {
    @StateObject private var voiceService = VoiceMessageService.shared
    @State private var isRecording = false
    @State private var showError = false
    @State private var errorMessage = ""
    let onSend: (URL) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if isRecording {
                    voiceService.stopRecording()
                    if let url = voiceService.recordingURL {
                        onSend(url)
                    }
                } else {
                    Task {
                        do {
                            try await voiceService.startRecording()
                            isRecording = true
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isRecording ? .red : .blue)
            }
            
            if isRecording {
                Text(voiceService.formatDuration(voiceService.recordingDuration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Recording waveform animation
                HStack(spacing: 2) {
                    ForEach(0..<20) { _ in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 2, height: CGFloat.random(in: 4...20))
                    }
                }
                .frame(height: 20)
            }
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

struct VoiceMessagePlayerView: View {
    @StateObject private var voiceService = VoiceMessageService.shared
    let url: URL
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Button(action: {
                        if voiceService.isPlaying {
                            voiceService.stopPlayback()
                        } else {
                            try? voiceService.playVoiceMessage(url: url)
                        }
                    }) {
                        Image(systemName: voiceService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    
                    // Playback waveform
                    HStack(spacing: 2) {
                        ForEach(0..<20) { _ in
                            Rectangle()
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 2, height: CGFloat.random(in: 4...20))
                        }
                    }
                    .frame(height: 20)
                    
                    Text(voiceService.formatDuration(voiceService.playbackDuration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

#Preview {
    VStack {
        VoiceMessageView { _ in }
        VoiceMessagePlayerView(url: URL(fileURLWithPath: ""), isCurrentUser: true)
    }
} 