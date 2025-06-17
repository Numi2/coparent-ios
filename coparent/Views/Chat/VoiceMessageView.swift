import SwiftUI
import AVFoundation

struct VoiceMessageView: View {
    @StateObject private var voiceService = VoiceMessageService.shared
    @State private var isRecording = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    let onSend: (URL) -> Void

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.1)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("Voice Message")
                        .font(.headline)

                    Spacer()

                    if isRecording {
                        Button(action: {
                            voiceService.stopRecording()
                            if let url = voiceService.recordingURL {
                                onSend(url)
                                dismiss()
                            }
                        }) {
                            Text("Send")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Recording interface
                VStack(spacing: 32) {
                    // Waveform visualization
                    WaveformView(isRecording: isRecording)
                        .frame(height: 120)
                        .padding(.horizontal)

                    // Recording button
                    Button(action: {
                        if isRecording {
                            voiceService.stopRecording()
                            if let url = voiceService.recordingURL {
                                onSend(url)
                                dismiss()
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
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.blue)
                                .frame(width: 80, height: 80)
                                .shadow(color: isRecording ? .red.opacity(0.3) : .blue.opacity(0.3),
                                       radius: 10, x: 0, y: 5)

                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")

                    // Duration display
                    if isRecording {
                        Text(voiceService.formatDuration(voiceService.recordingDuration))
                            .font(.system(.title2, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }
                }

                Spacer()

                // Instructions
                Text(isRecording ? "Tap to stop recording" : "Tap to start recording")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

struct WaveformView: View {
    let isRecording: Bool
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midHeight = height / 2
            let numberOfBars = 30
            let barWidth: CGFloat = 4
            let spacing: CGFloat = 4

            HStack(spacing: spacing) {
                ForEach(0..<numberOfBars, id: \.self) { index in
                    let progress = CGFloat(index) / CGFloat(numberOfBars)
                    let offset = sin(progress * .pi * 2 + phase)
                    let barHeight = isRecording ?
                        (midHeight * (0.5 + abs(offset) * 0.5)) :
                        (midHeight * 0.2)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(isRecording ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: barWidth, height: barHeight)
                        .animation(.easeInOut(duration: 0.2), value: isRecording)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
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
                HStack(spacing: 16) {
                    // Play/Pause button
                    Button(action: {
                        if voiceService.isPlaying {
                            voiceService.stopPlayback()
                        } else {
                            try? voiceService.playVoiceMessage(url: url)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: voiceService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isCurrentUser ? .white : .blue)
                        }
                    }
                    .accessibilityLabel(voiceService.isPlaying ? "Pause voice message" : "Play voice message")

                    // Waveform and duration
                    VStack(alignment: .leading, spacing: 4) {
                        // Waveform
                        WaveformView(isRecording: false)
                            .frame(height: 40)

                        // Duration
                        Text(voiceService.formatDuration(voiceService.playbackDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isCurrentUser ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
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
