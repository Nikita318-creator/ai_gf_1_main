import AVKit
import MediaPlayer

final class MyPlayerVC: AVPlayerViewController {
    
    private var audioStateTracker: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAudioSessionHandling()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        purgeVolumeOverlayNodes(within: self.view)
    }
    
    private func configureAudioSessionHandling() {
        let hiddenVolumeContainer = MPVolumeView(frame: .zero)
        hiddenVolumeContainer.clipsToBounds = true
        hiddenVolumeContainer.alpha = 0.001
        view.addSubview(hiddenVolumeContainer)
        
        guard let activePlayerInstance = player else { return }
        
        activePlayerInstance.isMuted = true
        
        audioStateTracker = activePlayerInstance.observe(\.isMuted, options: [.new]) { [weak activePlayerInstance] _, observedChange in
            guard let isMutedStatus = observedChange.newValue else { return }
            if !isMutedStatus {
                activePlayerInstance?.isMuted = true
            }
        }
    }
    
    private func purgeVolumeOverlayNodes(within targetContainerView: UIView) {
        for elementView in targetContainerView.subviews {
            let identifierString = String(describing: type(of: elementView))
            
            if identifierString.contains("Volume") || identifierString.contains("Mute") {
                elementView.removeFromSuperview()
            } else {
                purgeVolumeOverlayNodes(within: elementView)
            }
        }
    }
    
    deinit {
        audioStateTracker?.invalidate()
    }
}
