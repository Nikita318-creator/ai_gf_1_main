import AVFoundation
import UIKit

class VoiceVideoCellReppitter: NSObject, AVAudioPlayerDelegate {
    private var primaryAudioStreamUnit: AVAudioPlayer?

    override init() {
        super.init()
        configurePlaybackFramework()
        setupMediaAudioSource()
    }

    private func configurePlaybackFramework() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("ERROR: Failed to set audio session category: \(error)")
        }
    }

    private func setupMediaAudioSource() {
        let selectedTrackID = Int.random(in: 1...12)
        let assetNameString = "music\(selectedTrackID)"
        
        guard let localMediaURL = Bundle.main.url(forResource: assetNameString, withExtension: "mp3") else { return }

        do {
            primaryAudioStreamUnit = try AVAudioPlayer(contentsOf: localMediaURL)
            primaryAudioStreamUnit?.delegate = self
            primaryAudioStreamUnit?.numberOfLoops = -1
            primaryAudioStreamUnit?.volume = 0.4
            primaryAudioStreamUnit?.prepareToPlay()
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    func play() { primaryAudioStreamUnit?.play() }
    func pause() { primaryAudioStreamUnit?.pause() }
}
