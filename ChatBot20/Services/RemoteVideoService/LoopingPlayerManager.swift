import AVFoundation
import UIKit

class LoopingAudioManager: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        configureAudioSession() // Важный фикс
        setupRandomAudioPlayer()
    }

    private func configureAudioSession() {
        do {
            // Позволяет играть аудио вместе с видео и не глохнуть от переключателя Silent
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("ERROR: Failed to set audio session category: \(error)")
        }
    }

    private func setupRandomAudioPlayer() {
        let randomIndex = Int.random(in: 1...12)
        let audioFileName = "audioForVid\(randomIndex)"
        
        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.4 // Сделал чуть громче, раз видео будет молчать
            audioPlayer?.prepareToPlay()
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    func play() { audioPlayer?.play() }
    func pause() { audioPlayer?.pause() }
}


class LoopingPlayerManager: NSObject {
    let player: AVPlayer
    private var videoLoopToken: NSObjectProtocol?
    private let audioManager: LoopingAudioManager
    private var isObserverAdded = false
    
    init(player: AVPlayer, audioManager: LoopingAudioManager) {
        self.player = player
        self.audioManager = audioManager
        super.init()
        
        // Глушим видео сразу при инициализации
        self.player.isMuted = true
        
        setupLooping()
    }
    
    private func setupLooping() {
        guard let playerItem = player.currentItem else { return }
        
        videoLoopToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
        
        // Добавляем обсервер за рейтом
        player.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)
        isObserverAdded = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if player.rate > 0 {
                audioManager.play()
            } else {
                audioManager.pause()
            }
        }
    }

    deinit {
        if let token = videoLoopToken {
            NotificationCenter.default.removeObserver(token)
        }
        if isObserverAdded {
            player.removeObserver(self, forKeyPath: "rate")
        }
        audioManager.pause()
    }
}
