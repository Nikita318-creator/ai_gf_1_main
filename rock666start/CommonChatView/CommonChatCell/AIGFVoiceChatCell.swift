import UIKit
import AVFoundation

class AIGFVoiceChatCell: AIGFChatCell {

    private let voiceContainerView = UIView()
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.primary
        button.layer.cornerRadius = 19
        return button
    }()

    private let voiceLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = MyColors.textPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var waveformView: AIGFMessageWaveView = {
        let wave = AIGFMessageWaveView()
        wave.onProgressChanged = { [weak self] (progress, isDragging) in
            guard let self = self else { return }
            self.isDraggingSlider = isDragging

            guard let player = self.service.audioPlayer,
                  let currentItem = player.currentItem,
                  self.service.currentSpeakinID == self.messageID else { return }

            let duration = CMTimeGetSeconds(currentItem.duration)
            guard duration > 0 && !duration.isNaN else { return }

            let newTime = Double(progress) * duration
            let targetTime = CMTime(seconds: newTime, preferredTimescale: 1000)

            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        return wave
    }()

    private var displayLink: CADisplayLink?
    private var isDraggingSlider = false
    private var currentMessageText: String = ""
    private let service = VoiceManager.shared

    var isSpeak = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let isCurrentCellPlaying = (self.service.currentSpeakinID == self.messageID)

                if isCurrentCellPlaying && self.service.isPreparing {
                    self.playPauseButton.setImage(nil, for: .normal)
                    self.voiceLoadingIndicator.startAnimating()
                    self.startDisplayLink()
                } else if isCurrentCellPlaying && self.service.isSpeaking {
                    let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                    self.playPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
                    self.voiceLoadingIndicator.stopAnimating()
                    self.startDisplayLink()
                } else {
                    let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                    self.playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
                    self.voiceLoadingIndicator.stopAnimating()

                    if !isCurrentCellPlaying {
                        self.stopDisplayLink()
                        self.waveformView.progress = 0
                    }
                }
            }
        }
    }

    override func setupSubviews() {
        messageContainerView.addSubview(voiceContainerView)
        voiceContainerView.addSubview(playPauseButton)
        voiceContainerView.addSubview(voiceLoadingIndicator)
        voiceContainerView.addSubview(waveformView)

        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechStarted), name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechFinished), name: NSNotification.Name("updateAllAudioCellsOnFinish"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechPaused), name: NSNotification.Name("updateAllAudioCellsOnPause"), object: nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSpeak = false
        voiceLoadingIndicator.stopAnimating()
        waveformView.progress = 0
        isDraggingSlider = false
        stopDisplayLink()
    }

    deinit {
        VoiceManager.shared.currentSpeakinID = nil
        VoiceManager.shared.stopSpeaking()
    }

    func configure(message: String, isUserMessage: Bool, id: String, reaction: String?) {
        self.messageID = id
        currentMessageText = message

        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction)
        messageContainerView.backgroundColor = MyColors.assistantMessageBackground
        configureAssistantVoiceMessage()

        self.isSpeak = service.isSpeaking && (service.currentSpeakinID == id)
    }

    private func configureAssistantVoiceMessage() {
        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.width.equalTo(240)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().inset(4)
        }

        voiceContainerView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        playPauseButton.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(38)
        }

        voiceLoadingIndicator.snp.remakeConstraints { make in
            make.center.equalTo(playPauseButton)
        }

        waveformView.snp.remakeConstraints { make in
            make.leading.equalTo(playPauseButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
    }

    @objc private func playPauseTapped() {
        let isCurrentCell = (service.currentSpeakinID == messageID)

        if isCurrentCell && service.audioPlayer != nil {
            if service.isPreparing {
                service.stopSpeaking()
                isSpeak = false
            } else {
                service.togglePause()
                isSpeak = service.isSpeaking
            }
            return
        }

        service.stopSpeaking(needNotifyOthers: false)
        service.currentSpeakinID = messageID

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("speech.mp3")
        if FileManager.default.fileExists(atPath: tempURL.path) && isCurrentCell {
            let playerItem = AVPlayerItem(url: tempURL)
            NotificationCenter.default.addObserver(service, selector: #selector(service.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            service.audioPlayer = AVPlayer(playerItem: playerItem)
            service.audioPlayer?.play()

            if waveformView.progress > 0 {
                let duration = CMTimeGetSeconds(playerItem.duration)
                if duration > 0 && !duration.isNaN {
                    let newTime = Double(waveformView.progress) * duration
                    service.audioPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 1000))
                }
            }

            NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
            isSpeak = true
        } else {
            let isAnime = (11...20).map({ "mainAvatar\($0)" }).contains(MyGovnoSingltone.shared.currentAssistant?.avatarImageName ?? "")
            service.speak(text: currentMessageText, isAnime: isAnime)
            isSpeak = true
        }
    }

    @objc private func handleSpeechStarted() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSpeak = (self.service.currentSpeakinID == self.messageID)
        }
    }

    @objc private func handleSpeechFinished() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
            self.playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
            self.voiceLoadingIndicator.stopAnimating()
            self.stopDisplayLink()
            self.waveformView.progress = 0
        }
    }

    @objc private func handleSpeechPaused() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.service.currentSpeakinID == self.messageID {
                self.stopDisplayLink()
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                self.playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
                self.voiceLoadingIndicator.stopAnimating()
            }
        }
    }

    @objc private func updateWaveProgress() {
        guard !isDraggingSlider else { return }
        guard let player = service.audioPlayer,
              let currentItem = player.currentItem,
              service.currentSpeakinID == messageID else { return }

        let duration = CMTimeGetSeconds(currentItem.duration)
        let currentTime = CMTimeGetSeconds(player.currentTime())

        guard duration > 0 && !duration.isNaN && !currentTime.isNaN else { return }
        waveformView.progress = Float(currentTime / duration)
    }

    private func startDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaveProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
}
