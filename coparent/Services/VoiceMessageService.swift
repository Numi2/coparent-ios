import Foundation
import AVFoundation
import SendbirdChatSDK

class VoiceMessageService: NSObject, ObservableObject {
    static let shared = VoiceMessageService()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var playbackDuration: TimeInterval = 0
    @Published var recordingURL: URL?
    
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() async throws {
        guard let recordingSession = recordingSession else {
            throw NSError(
                domain: "VoiceMessageService", 
                code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Audio session not initialized"]
            )
        }
        
        // Request microphone permission
        let granted = await withCheckedContinuation { continuation in
            recordingSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        guard granted else {
            throw NSError(
                domain: "VoiceMessageService", 
                code: -2, 
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]
            )
        }
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "voice_message_\(Date().timeIntervalSince1970).m4a"
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        guard let recordingURL = recordingURL else {
            throw NSError(
                domain: "VoiceMessageService", 
                code: -3, 
                userInfo: [NSLocalizedDescriptionKey: "Failed to create recording URL"]
            )
        }
        
        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // Start recording
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        
        isRecording = true
        recordingDuration = 0
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
    }
    
    func playVoiceMessage(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()
        
        isPlaying = true
        playbackDuration = 0
        
        // Start timer
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.playbackDuration = self?.audioPlayer?.currentTime ?? 0
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension VoiceMessageService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension VoiceMessageService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
} 
