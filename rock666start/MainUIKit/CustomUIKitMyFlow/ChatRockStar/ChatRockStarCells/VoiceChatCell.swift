import UIKit
import AVFoundation

class VoiceChatCell: AbstractChatCell {

    private let audioContentWrapper = UIView()
    private let playbackActionButton: UIButton = {
        let primaryBtn = UIButton(type: .system)
        let iconSymbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        primaryBtn.setImage(UIImage(systemName: "play.fill", withConfiguration: iconSymbolConfig), for: .normal)
        primaryBtn.tintColor = BasePalitColors.textPrimary
        primaryBtn.backgroundColor = BasePalitColors.primary
        primaryBtn.layer.cornerRadius = 19
        return primaryBtn
    }()

    private let audioBufferingSpinner: UIActivityIndicatorView = {
        let loadingSpinner = UIActivityIndicatorView(style: .medium)
        loadingSpinner.color = BasePalitColors.textPrimary
        loadingSpinner.hidesWhenStopped = true
        return loadingSpinner
    }()

    private lazy var audioTrackTrackbar: AudioMessageView = {
        let trackbarWidget = AudioMessageView()
        trackbarWidget.onProgressChanged = { [weak self] (playbackRatio, userInteractionActive) in
            guard let self = self else { return }
            self.userManipulatingSlider = userInteractionActive

            guard let activePlayer = self.speechDispatcher.audioPlayer,
                  let activeMediaItem = activePlayer.currentItem,
                  self.speechDispatcher.currentSpeakinID == self.currentMessageID else { return }

            let totalMediaDuration = CMTimeGetSeconds(activeMediaItem.duration)
            guard totalMediaDuration > 0 && !totalMediaDuration.isNaN else { return }

            let targetSecond = Double(playbackRatio) * totalMediaDuration
            let playbackSeekTime = CMTime(seconds: targetSecond, preferredTimescale: 1000)

            activePlayer.seek(to: playbackSeekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        return trackbarWidget
    }()

    private var frameSyncTimer: CADisplayLink?
    private var userManipulatingSlider = false
    private var cachedPayloadText: String = ""
    private let speechDispatcher = VoiceManager.shared

    var isSpeak = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let cellIsCurrentlyActive = (self.speechDispatcher.currentSpeakinID == self.currentMessageID)

                if cellIsCurrentlyActive && self.speechDispatcher.isPreparing {
                    self.playbackActionButton.setImage(nil, for: .normal)
                    self.audioBufferingSpinner.startAnimating()
                    self.activateFrameLoop()
                } else if cellIsCurrentlyActive && self.speechDispatcher.isSpeaking {
                    let pauseIconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                    self.playbackActionButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: pauseIconConfig), for: .normal)
                    self.audioBufferingSpinner.stopAnimating()
                    self.activateFrameLoop()
                } else {
                    let playIconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                    self.playbackActionButton.setImage(UIImage(systemName: "play.fill", withConfiguration: playIconConfig), for: .normal)
                    self.audioBufferingSpinner.stopAnimating()

                    if !cellIsCurrentlyActive {
                        self.deactivateFrameLoop()
                        self.audioTrackTrackbar.progress = 0
                    }
                }
            }
        }
    }

    override func setupSubviews() {
        bobleView.addSubview(audioContentWrapper)
        audioContentWrapper.addSubview(playbackActionButton)
        audioContentWrapper.addSubview(audioBufferingSpinner)
        audioContentWrapper.addSubview(audioTrackTrackbar)

        playbackActionButton.addTarget(self, action: #selector(didTapPlaybackToggle), for: .touchUpInside)

        NotificationCenter.default.addObserver(self, selector: #selector(didObserveSpeechStart), name: NSNotification.Name("playAudioObserver"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didObserveSpeechCompletion), name: NSNotification.Name("endedAudioObserver"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didObserveSpeechPause), name: NSNotification.Name("pauseAudioObserver"), object: nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSpeak = false
        audioBufferingSpinner.stopAnimating()
        audioTrackTrackbar.progress = 0
        userManipulatingSlider = false
        deactivateFrameLoop()
    }

    deinit {
        VoiceManager.shared.currentSpeakinID = nil
        VoiceManager.shared.stopSpeaking()
    }

    func configure(message: String, isUserMessage: Bool, id: String, reaction: String?) {
        self.currentMessageID = id
        cachedPayloadText = message

        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction)
        bobleView.backgroundColor = BasePalitColors.assistantMessageBackground
        applyVoiceLayoutConstraints()

        self.isSpeak = speechDispatcher.isSpeaking && (speechDispatcher.currentSpeakinID == id)
    }

    private func applyVoiceLayoutConstraints() {
        let avatarDimension: CGFloat = isIPad() ? 52 : 36
        authorImageView.snp.remakeConstraints { makeConstraint in
            makeConstraint.leading.equalToSuperview().inset(16)
            makeConstraint.bottom.equalToSuperview().inset(4)
            makeConstraint.width.height.equalTo(avatarDimension)
        }

        bobleView.snp.remakeConstraints { makeConstraint in
            makeConstraint.top.equalToSuperview().inset(4)
            makeConstraint.leading.equalTo(authorImageView.snp.trailing).offset(8)
            makeConstraint.width.equalTo(240)
            makeConstraint.height.equalTo(50)
            makeConstraint.bottom.equalToSuperview().inset(4)
        }

        audioContentWrapper.snp.remakeConstraints { makeConstraint in
            makeConstraint.edges.equalToSuperview()
        }

        playbackActionButton.snp.remakeConstraints { makeConstraint in
            makeConstraint.leading.equalToSuperview().inset(8)
            makeConstraint.centerY.equalToSuperview()
            makeConstraint.size.equalTo(38)
        }

        audioBufferingSpinner.snp.remakeConstraints { makeConstraint in
            makeConstraint.center.equalTo(playbackActionButton)
        }

        audioTrackTrackbar.snp.remakeConstraints { makeConstraint in
            makeConstraint.leading.equalTo(playbackActionButton.snp.trailing).offset(12)
            makeConstraint.trailing.equalToSuperview().inset(16)
            makeConstraint.centerY.equalToSuperview()
            makeConstraint.height.equalTo(30)
        }
    }

    @objc private func didTapPlaybackToggle() {
        let isActiveTargetCell = (speechDispatcher.currentSpeakinID == currentMessageID)

        if isActiveTargetCell && speechDispatcher.audioPlayer != nil {
            if speechDispatcher.isPreparing {
                speechDispatcher.stopSpeaking()
                isSpeak = false
            } else {
                speechDispatcher.togglePause()
                isSpeak = speechDispatcher.isSpeaking
            }
            return
        }

        speechDispatcher.stopSpeaking(needNotifyOthers: false)
        speechDispatcher.currentSpeakinID = currentMessageID

        let cachedAudioFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("speech.mp3")
        if FileManager.default.fileExists(atPath: cachedAudioFilePath.path) && isActiveTargetCell {
            let playableItem = AVPlayerItem(url: cachedAudioFilePath)
            NotificationCenter.default.addObserver(speechDispatcher, selector: #selector(speechDispatcher.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playableItem)
            speechDispatcher.audioPlayer = AVPlayer(playerItem: playableItem)
            speechDispatcher.audioPlayer?.play()

            if audioTrackTrackbar.progress > 0 {
                let trackLength = CMTimeGetSeconds(playableItem.duration)
                if trackLength > 0 && !trackLength.isNaN {
                    let desiredPosition = Double(audioTrackTrackbar.progress) * trackLength
                    speechDispatcher.audioPlayer?.seek(to: CMTime(seconds: desiredPosition, preferredTimescale: 1000))
                }
            }

            NotificationCenter.default.post(name: NSNotification.Name("playAudioObserver"), object: nil)
            isSpeak = true
        } else {
            let hasAnimeAvatar = (11...20).map({ "mainAvatar\($0)" }).contains(MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName ?? "")
            speechDispatcher.speak(text: cachedPayloadText, isAnime: hasAnimeAvatar)
            isSpeak = true
        }
    }

    @objc private func didObserveSpeechStart() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSpeak = (self.speechDispatcher.currentSpeakinID == self.currentMessageID)
        }
    }

    @objc private func didObserveSpeechCompletion() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let defaultIconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
            self.playbackActionButton.setImage(UIImage(systemName: "play.fill", withConfiguration: defaultIconConfig), for: .normal)
            self.audioBufferingSpinner.stopAnimating()
            self.deactivateFrameLoop()
            self.audioTrackTrackbar.progress = 0
        }
    }

    @objc private func didObserveSpeechPause() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.speechDispatcher.currentSpeakinID == self.currentMessageID {
                self.deactivateFrameLoop()
                let defaultIconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                self.playbackActionButton.setImage(UIImage(systemName: "play.fill", withConfiguration: defaultIconConfig), for: .normal)
                self.audioBufferingSpinner.stopAnimating()
            }
        }
    }

    @objc private func syncProgressStep() {
        guard !userManipulatingSlider else { return }
        guard let activeAudioPlayer = speechDispatcher.audioPlayer,
              let activeTrackItem = activeAudioPlayer.currentItem,
              speechDispatcher.currentSpeakinID == currentMessageID else { return }

        let mediaTotalDuration = CMTimeGetSeconds(activeTrackItem.duration)
        let mediaCurrentTimestamp = CMTimeGetSeconds(activeAudioPlayer.currentTime())

        guard mediaTotalDuration > 0 && !mediaTotalDuration.isNaN && !mediaCurrentTimestamp.isNaN else { return }
        audioTrackTrackbar.progress = Float(mediaCurrentTimestamp / mediaTotalDuration)
    }

    private func activateFrameLoop() {
        frameSyncTimer?.invalidate()
        frameSyncTimer = CADisplayLink(target: self, selector: #selector(syncProgressStep))
        frameSyncTimer?.add(to: .main, forMode: .common)
    }

    private func deactivateFrameLoop() {
        frameSyncTimer?.invalidate()
        frameSyncTimer = nil
    }
}
