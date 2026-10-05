import AVFoundation
import UIKit

class MusicVideoReppitter: NSObject {
    let player: AVPlayer
    private var mediaLoopObserverHandle: NSObjectProtocol?
    private let secondaryAudioHandler: VoiceVideoCellReppitter
    private var stateObserverAttached = false
    
    init(player: AVPlayer, audioManager: VoiceVideoCellReppitter) {
        self.player = player
        self.secondaryAudioHandler = audioManager
        super.init()
        
        self.player.isMuted = true
        
        registerPlaybackNotificationListener()
    }
    
    private func registerPlaybackNotificationListener() {
        guard let activePlayableItem = player.currentItem else { return }
        
        mediaLoopObserverHandle = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: activePlayableItem,
            queue: .main) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
        
        player.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)
        stateObserverAttached = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if player.rate > 0 {
                secondaryAudioHandler.play()
            } else {
                secondaryAudioHandler.pause()
            }
        }
    }

    deinit {
        if let currentObserver = mediaLoopObserverHandle {
            NotificationCenter.default.removeObserver(currentObserver)
        }
        if stateObserverAttached {
            player.removeObserver(self, forKeyPath: "rate")
        }
        secondaryAudioHandler.pause()
    }
}
