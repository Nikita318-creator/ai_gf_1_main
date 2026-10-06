import AVFoundation

class AILiveVoiceService: NSObject {
    static let shared = AILiveVoiceService()
    
    var audioPlayer: AVPlayer?
    var internalSecretTokenKey: String {
        let prefixCodes: [UInt8] = [65, 73, 122, 97, 83, 121, 65, 105, 115, 67, 50, 87, 101, 80, 82, 114, 84, 68, 111, 106, 90, 97]
        let resolvedPrefix = String(bytes: prefixCodes, encoding: .utf8) ?? ""
        return resolvedPrefix + BackendService.shared.currentData.audioToken
    }

    var currentSpeakinID: String?
    var isPreparing: Bool = false

    var isSpeaking: Bool {
        if isPreparing { return true }
        return audioPlayer?.rate != 0 && audioPlayer?.error == nil && audioPlayer != nil
    }

    private override init() {
        super.init()
    }

    func togglePause() {
        guard let activePlayer = audioPlayer else { return }
        if activePlayer.rate == 0 {
            activePlayer.play()
            postNotification(name: "playAudioObserver")
        } else {
            activePlayer.pause()
            postNotification(name: "pauseAudioObserver")
        }
    }

    func stopSpeaking(needNotifyOthers: Bool = true) {
        isPreparing = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        resetAudioEngineState()
        
        audioPlayer = nil
        if needNotifyOthers {
            notifyPlaybackCompleted()
        }
    }
    
    @objc func playerDidFinishPlaying() {
        stopSpeaking(needNotifyOthers: true)
    }
}
