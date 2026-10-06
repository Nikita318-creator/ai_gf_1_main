import AVFoundation
import UIKit

class VoiceVideoCellReppitter: NSObject, AVAudioPlayerDelegate {
    private var soundEnginePlayer: AVAudioPlayer?

    override init() {
        super.init()
        prepareAudioEnvironment()
        initializePlaybackEngine()
    }

    private func prepareAudioEnvironment() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("ERROR: Failed to set audio session category: \(error)")
        }
    }

    private func initializePlaybackEngine() {
        let trackSelectionIndex = Int.random(in: 1...12)
        let audioTrackName = "music\(trackSelectionIndex)"
        
        guard let resourceUrl = Bundle.main.url(forResource: audioTrackName, withExtension: "mp3") else { return }

        do {
            soundEnginePlayer = try AVAudioPlayer(contentsOf: resourceUrl)
            soundEnginePlayer?.delegate = self
            soundEnginePlayer?.numberOfLoops = -1
            soundEnginePlayer?.volume = 0.4
            soundEnginePlayer?.prepareToPlay()
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    func play() { soundEnginePlayer?.play() }
    func pause() { soundEnginePlayer?.pause() }
}


class musicVideoReppitter: NSObject {
    let player: AVPlayer
    private var loopNotificationToken: NSObjectProtocol?
    private let soundController: VoiceVideoCellReppitter
    private var isKvoRegistered = false
    
    init(player: AVPlayer, audioManager: VoiceVideoCellReppitter) {
        self.player = player
        self.soundController = audioManager
        super.init()
        
        self.player.isMuted = true
        
        attachRepeatObserver()
    }
    
    private func attachRepeatObserver() {
        guard let currentMediaItem = player.currentItem else { return }
        
        loopNotificationToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: currentMediaItem,
            queue: .main) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
        
        player.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)
        isKvoRegistered = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if player.rate > 0 {
                soundController.play()
            } else {
                soundController.pause()
            }
        }
    }

    deinit {
        if let activeToken = loopNotificationToken {
            NotificationCenter.default.removeObserver(activeToken)
        }
        if isKvoRegistered {
            player.removeObserver(self, forKeyPath: "rate")
        }
        soundController.pause()
    }
}
