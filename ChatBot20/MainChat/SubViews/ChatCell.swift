import UIKit
import SafariServices
import StoreKit
import SnapKit
import AVFoundation
import AVKit

class ChatCell: UITableViewCell {
    static let identifier = "ChatCell"

    private struct TelegramColors {
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let assistantMessageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        static let avatarBackground = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        static let link = UIColor(red: 0.25, green: 0.77, blue: 1.0, alpha: 1.0)
    }
    
    private var loopingPlayerManager: LoopingPlayerManager?

    private let messageContainerView = UIView()
    private lazy var messageLabel: UITextView = {
        let messageTextView = UITextView()
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.dataDetectorTypes = .link
        messageTextView.backgroundColor = .clear
        messageTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageTextView.textColor = TelegramColors.textPrimary
        messageTextView.linkTextAttributes = [
            .foregroundColor: TelegramColors.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        messageTextView.delegate = self
        return messageTextView
    }()

    private let messageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.isHidden = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let avatarView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = TelegramColors.textSecondary
        label.isHidden = true
        return label
    }()
    
    private lazy var regenerateButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isCurrentDeviceiPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: "arrow.triangle.2.circlepath")?.withConfiguration(config)
        button.setImage(image, for: .normal)
        button.tintColor = TelegramColors.textSecondary
        return button
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isCurrentDeviceiPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: "hand.thumbsup.fill")?.withConfiguration(config)
        button.setImage(image, for: .normal)
        button.tintColor = TelegramColors.textSecondary
        return button
    }()

    private lazy var dislikeButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isCurrentDeviceiPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: "hand.thumbsdown.fill")?.withConfiguration(config)
        button.setImage(image, for: .normal)
        button.tintColor = TelegramColors.textSecondary
        return button
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = isCurrentDeviceiPad() ? 16 : 8
        stackView.isHidden = true
        return stackView
    }()

    private let blurryOverlayView: BlurryOverlayView = {
        let view = BlurryOverlayView()
        view.isHidden = true // Изначально скрываем его
        view.isUserInteractionEnabled = true // Важно, чтобы можно было обрабатывать тапы
        return view
    }()
    
    private let playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold, scale: .large)
        imageView.image = UIImage(systemName: "play.circle.fill")?.withConfiguration(config)
        imageView.isHidden = true
        return imageView
    }()
    
    weak var vc: UIViewController?
    var hideKeyboardHandler: (() -> Void)?
    var showSubsHandler: (() -> Void)?
    var likeTappedHandler: ((Bool) -> Void)?
    var regenerateTappedHandler: (() -> Void)?
    var reloadDataHandler: (() -> Void)?
    var avatarTappedHandler: (() -> Void)?

    private var messageID = ""
    private var isVideoCell = false
    private var videoID: String?
    
    // MARK: - Voice Message Elements (Обновленные)
    private let voiceContainerView = UIView()
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    // Маленький лоадер специально для кнопки аудио-сообщения
    private let voiceLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Вместо waveStackView используем интерактивный слайдер
    private lazy var audioSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        
        // Кастомизируем круглый ползунок (сделать чуть меньше при желании)
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: config)
        slider.setThumbImage(thumbImage, for: .normal)
        
        // Обработка событий перемотки
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: .touchUpOutside)
        return slider
    }()
    
    private lazy var waveformView: AudioWaveformView = {
        let wave = AudioWaveformView()
        wave.onProgressChanged = { [weak self] (progress, isDragging) in
            guard let self = self else { return }
            self.isDraggingSlider = isDragging
            
            // Передаем текущий прогресс в плеер
            guard let player = self.service.audioPlayer,
                  let currentItem = player.currentItem,
                  self.service.currentSpeakinID == self.messageID else { return }
            
            let duration = CMTimeGetSeconds(currentItem.duration)
            guard duration > 0 && !duration.isNaN else { return }
            
            let newTime = Double(progress) * duration
            let targetTime = CMTime(seconds: newTime, preferredTimescale: 1000)
            
            if isDragging {
                // Если просто тащит, можем обновлять только UI (поведение как у sliderValueChanged)
                player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            } else {
                // Юзер отпустил палец — финальная перемотка
                player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
        return wave
    }()
    
    private var displayLink: CADisplayLink?
    private var isDraggingSlider = false // Флаг, чтобы бегунок не прыгал во время ручной перемотки
    private var currentMessageText: String = ""
    private let service = SpeechSynthesizerService.shared
    private var isVoiceMessage = false
    
    var isSpeak = false {
        didSet {
            DispatchQueue.main.async { [self] in
                let isCurrentCellPlaying = (service.currentSpeakinID == messageID)
                
                if isCurrentCellPlaying && service.isPreparing {
                    playPauseButton.setImage(nil, for: .normal)
                    voiceLoadingIndicator.startAnimating()
                    startDisplayLink()
                } else if isCurrentCellPlaying && service.isSpeaking {
                    let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
                    playPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
                    voiceLoadingIndicator.stopAnimating()
                    startDisplayLink()
                } else {
                    let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
                    playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
                    voiceLoadingIndicator.stopAnimating()
                    
                    if !isCurrentCellPlaying {
                        stopDisplayLink()
                        waveformView.progress = 0
                    }
                }
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        updateTextForIPadIfNeeded()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAudioCellOnStart(_:)),
            name: .updateAllAudioCellsOnStart,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAudioCellOnFinish(_:)),
            name: .updateAllAudioCellsOnFinish,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        messageLabel.isHidden = false
        messageImageView.isHidden = true
        messageImageView.image = nil
        isSpeak = false
        buttonStackView.isHidden = true
        statusLabel.isHidden = true
        statusLabel.text = nil
        playIconImageView.isHidden = true
        blurryOverlayView.isHidden = true
        voiceContainerView.isHidden = true
        likeButton.tintColor = TelegramColors.textSecondary
        dislikeButton.tintColor = TelegramColors.textSecondary
        voiceLoadingIndicator.stopAnimating()
        audioSlider.value = 0
        waveformView.progress = 0
        isDraggingSlider = false
        stopDisplayLink()
    }
    
    deinit {
        SpeechSynthesizerService.shared.currentSpeakinID = nil
        SpeechSynthesizerService.shared.stopSpeaking()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        messageContainerView.layer.cornerRadius = 18
        messageContainerView.layer.masksToBounds = false
        messageContainerView.layer.shadowColor = UIColor.black.cgColor
        messageContainerView.layer.shadowOpacity = 0.1
        messageContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        messageContainerView.layer.shadowRadius = 2
        contentView.addSubview(messageContainerView)

        avatarView.backgroundColor = TelegramColors.avatarBackground
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        contentView.addSubview(avatarView)

        if MainHelper.shared.currentAssistant?.avatarImageName.isEmpty ?? true {
            avatarView.image = UIImage(named: "1")
        } else {
            avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? MainHelper.shared.currentAssistantImage
        }

        messageContainerView.addSubview(messageLabel)
        messageContainerView.addSubview(messageImageView)
        messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(messageImageTapped)))

        loadingIndicator.color = TelegramColors.textSecondary
        loadingIndicator.isHidden = true
        messageContainerView.addSubview(loadingIndicator)
        messageContainerView.addSubview(statusLabel)

        // Добавляем кнопки регенерации, лайка и дизлайка
        buttonStackView.addArrangedSubview(regenerateButton)
        buttonStackView.addArrangedSubview(likeButton)
        buttonStackView.addArrangedSubview(dislikeButton)
        messageContainerView.addSubview(buttonStackView)
        
        regenerateButton.addTarget(self, action: #selector(regenerateButtonTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        dislikeButton.addTarget(self, action: #selector(dislikeButtonTapped), for: .touchUpInside)

        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)

        messageImageView.addSubview(playIconImageView)
        messageImageView.bringSubviewToFront(playIconImageView) // Гарантируем, что иконка над размытием
        messageImageView.addSubview(blurryOverlayView)
        
        blurryOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview() // Центрируем иконку
            let iconSize: CGFloat = isCurrentDeviceiPad() ? 80 : 60
            make.width.height.equalTo(iconSize)
        }
        
        setupAudioUI()
    }

    func configure(message: String, isUserMessage: Bool, photoID: String, needHideActionButtons: Bool, id: String, isVoiceMessage: Bool) {
        messageID = id
        isVideoCell = message.contains("[video]")
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        avatarView.isHidden = isUserMessage
        playIconImageView.isHidden = true
        currentMessageText = message
        self.isVoiceMessage = isVoiceMessage
        
        if isVoiceMessage && !isUserMessage {
            messageLabel.isHidden = true
            messageImageView.isHidden = true
            voiceContainerView.isHidden = false
            messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
            configureAssistantVoiceMessage()
            
            // Проверяем: играет ли СЕЙЧАС именно это сообщение?
            self.isSpeak = service.isSpeaking && (service.currentSpeakinID == id)
            
            return
        } else {
            voiceContainerView.isHidden = true
        }
        
        if !isUserMessage {
            if MainHelper.shared.isMode, let avatarName = MainHelper.shared.currentAssistant?.avatarImageName {
                if avatarName.contains("ind1") {
                    avatarView.image = UIImage(named: "ind5")
                } else if avatarName.contains("latina16") {
                    avatarView.image = UIImage(named: "latina11")
                } else if avatarName == "1" {
                    avatarView.image = UIImage(named: "pic109")
                } else if avatarName == "5" {
                    avatarView.image = UIImage(named: "photo113")
                } else if avatarName == "6" {
                    avatarView.image = UIImage(named: "photo57")
                } else {
                    avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? MainHelper.shared.currentAssistantImage
                }
            } else {
                avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? MainHelper.shared.currentAssistantImage
            }
        }

        if !photoID.isEmpty { // Если сообщение - картинка
            messageLabel.isHidden = true
            messageImageView.isHidden = false
            if !isUserMessage && !IAPService.shared.hasActiveSubscription {
                blurryOverlayView.isHidden = false
            } else {
                blurryOverlayView.isHidden = true
            }
            
            if message.contains("[new pic]") {
                messageImageView.image = RemoteRealmPhotoService.shared.getImage(by: photoID)
            } else if message.contains("[user photo]") {
                let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = docsURL.appendingPathComponent(photoID)
                messageImageView.image = UIImage(contentsOfFile: fileURL.path)
            } else if message.contains("[video]") {
                videoID = photoID
                playIconImageView.isHidden = false
                if let thumbnailData = RemoteRealmVideoService.shared.getThumbnailData(name: photoID) {
                    self.messageImageView.image = UIImage(data: thumbnailData)
                }
            } else if MainHelper.shared.currentAssistant?.avatarImageName.contains("milf") == true && !isUserMessage {
                messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID)
            } else {
                messageImageView.image = UIImage(named: photoID)
            }
            
            messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
            
            if isUserMessage {
                configureUserMessageForImage()
            } else {
                configureAssistantMessageForImage()
            }
            buttonStackView.isHidden = true

        } else { // Если сообщение - текст
            messageLabel.isHidden = false
            messageImageView.isHidden = true
            messageLabel.text = message.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if isUserMessage {
                messageContainerView.backgroundColor = TelegramColors.userMessageBackground
                configureUserMessageForText()
                buttonStackView.isHidden = true
            } else {
                messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
                configureAssistantMessageForText()
                buttonStackView.isHidden = needHideActionButtons
            }
        }
        
        isSpeak = (SpeechSynthesizerService.shared.currentSpeakinID ?? "") == (messageLabel.text ?? "")
    }

    func configureLoader() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = false
        messageLabel.isHidden = true
        messageImageView.isHidden = true
        loadingIndicator.startAnimating()
        buttonStackView.isHidden = true
        voiceContainerView.isHidden = true
        
        statusLabel.text = MainHelper.shared.currentAIMessageType.rawValue.localize()
        statusLabel.isHidden = false
        statusLabel.textColor = TelegramColors.textSecondary
        
        avatarView.isHidden = false
        
        if MainHelper.shared.isMode, let avatarName = MainHelper.shared.currentAssistant?.avatarImageName {
            if avatarName.contains("ind1") {
                avatarView.image = UIImage(named: "ind5")
            } else if avatarName.contains("latina16") {
                avatarView.image = UIImage(named: "latina11")
            } else if avatarName == "1" {
                avatarView.image = UIImage(named: "pic109")
            } else if avatarName == "5" {
                avatarView.image = UIImage(named: "photo113")
            } else if avatarName == "6" {
                avatarView.image = UIImage(named: "photo57")
            } else {
                avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? MainHelper.shared.currentAssistantImage
            }
        } else {
            avatarView.image = UIImage(named: MainHelper.shared.currentAssistant?.avatarImageName ?? "") ?? MainHelper.shared.currentAssistantImage
        }
        
        configureAssistantMessageForLoader()
    }

    private func configureAssistantMessageForLoader() {
        messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
        avatarView.isHidden = false
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }
        
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.width.greaterThanOrEqualTo(150) // Достаточно места для текста + индикатора
            make.height.equalTo(44) // Фиксированная высота для чистого лоадера
        }
        
        let padding: CGFloat = isCurrentDeviceiPad() ? 12 : 8
        let indicatorSize: CGFloat = isCurrentDeviceiPad() ? 24 : 20
        
        // Индикатор: слева
        loadingIndicator.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(indicatorSize)
        }
        
        // Текст статуса: справа от индикатора
        statusLabel.snp.remakeConstraints { make in
            make.leading.equalTo(loadingIndicator.snp.trailing).offset(padding / 2)
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }
        
        // Скрываем другие вью, если они были настроены
        messageLabel.snp.remakeConstraints { make in make.height.equalTo(0) }
        messageImageView.snp.remakeConstraints { make in make.height.equalTo(0) }
        buttonStackView.isHidden = true
    }
    
    @objc private func avatarTapped() {
        avatarTappedHandler?()
    }
    
    @objc private func messageImageTapped() {
        guard let vc = vc else { return }
        
        hideKeyboardHandler?()
        
        guard IAPService.shared.hasActiveSubscription else {
            showSubsHandler?()
            return
        }
        
        if isVideoCell {
            guard let player = makePlayer(from: videoID ?? "") else { return }

            let audioManager = LoopingAudioManager()
            self.loopingPlayerManager = LoopingPlayerManager(player: player, audioManager: audioManager)

            let playerVC = HardcorePlayerViewController()
            playerVC.player = player
            playerVC.modalPresentationStyle = .fullScreen
            playerVC.delegate = self

            player.isMuted = true

            vc.present(playerVC, animated: true) {
                player.play()
            }
        } else if let messageImage = messageImageView.image {
            let fullScreenView = FullScreenImageView(image: messageImage)
            fullScreenView.vc = vc
            fullScreenView.show(in: vc.view)
        }
    }
    
    private func makePlayer(from videoName: String) -> AVPlayer? {
        // Просто запрашиваем готовый локальный URL у нашего сервиса.
        // Сервис сам проверит, существует ли файл, и если надо — зачистит базу.
        guard let localURL = RemoteRealmVideoService.shared.getVideoLocalURL(name: videoName) else {
            print("⚠️ Видео \(videoName) не найдено в кэше или было удалено системой.")
            return nil
        }

        // Файл уже на диске, AVPlayer начнет играть его мгновенно!
        return AVPlayer(url: localURL)
    }

    @objc private func updateAudioCellOnStart(_ notification: Notification) {
        isSpeak = (SpeechSynthesizerService.shared.currentSpeakinID ?? "") == (messageLabel.text ?? "")
    }
    
    @objc private func updateAudioCellOnFinish(_ notification: Notification) {
        isSpeak = false
    }
    
    @objc private func regenerateButtonTapped() {
        regenerateTappedHandler?()
    }
    
    @objc private func likeButtonTapped() {
        if likeButton.tintColor == TelegramColors.textPrimary {
            likeButton.tintColor = TelegramColors.textSecondary
        } else {
            AnalyticService.shared.logEvent(name: "like message ButtonTapped", properties: ["":""])
            likeButton.tintColor = TelegramColors.textPrimary
            dislikeButton.tintColor = TelegramColors.textSecondary
            likeTappedHandler?(true)
            
            if MainHelper.shared.shouldRequestReviewAfterLikeTapped() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
    }
    
    @objc private func dislikeButtonTapped() {
        if dislikeButton.tintColor == TelegramColors.textPrimary {
            dislikeButton.tintColor = TelegramColors.textSecondary
        } else {
            AnalyticService.shared.logEvent(name: "dislike message ButtonTapped", properties: ["":""])
            dislikeButton.tintColor = TelegramColors.textPrimary
            likeButton.tintColor = TelegramColors.textSecondary
            likeTappedHandler?(false)
        }
    }

    private func configureUserMessageForText() {
        avatarView.isHidden = true
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(80)
        }

        messageLabel.snp.remakeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        loadingIndicator.snp.remakeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func configureUserMessageForImage() {
        avatarView.isHidden = true
        
        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let photoSize: CGFloat = isCurrentDeviceiPad() ? smallerSide / 2 : 200
        
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(80)
            make.width.equalTo(photoSize)
            make.height.equalTo(photoSize)
        }
        
        messageImageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
        loadingIndicator.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
    }

    private func configureAssistantMessageForText() {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.trailing.greaterThanOrEqualTo(buttonStackView.snp.trailing).offset(8)
        }

        messageLabel.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(buttonStackView.snp.top).offset(-4) // Отступ от иконки динамика
        }

        if isCurrentDeviceiPad() {
            buttonStackView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(18)
                make.bottom.equalToSuperview().inset(16) // Выравнивание по низу контейнера
            }
        } else {
            buttonStackView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(12)
                make.bottom.equalToSuperview().inset(8) // Выравнивание по низу контейнера
            }
        }

        if !loadingIndicator.isHidden {
            messageContainerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(4)
                make.bottom.equalToSuperview().inset(4)
                make.leading.equalTo(avatarView.snp.trailing).offset(8)
                make.trailing.lessThanOrEqualToSuperview().inset(80)
                make.width.greaterThanOrEqualTo(200)
            }
            
            messageLabel.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(12)
                make.bottom.equalToSuperview().inset(12)
                make.height.equalTo(20)
            }
            
            loadingIndicator.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(20)
            }
        }
    }
    
    private func configureAssistantMessageForImage() {
        avatarView.isHidden = false

        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let photoSize: CGFloat = isCurrentDeviceiPad() ? smallerSide / 2 : 200
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = TelegramColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.width.equalTo(photoSize)
            make.height.equalTo(photoSize)
        }
        
        messageImageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
        loadingIndicator.snp.remakeConstraints { make in
            make.height.equalTo(0)
        }
    }

    private func setupAudioUI() {
        messageContainerView.addSubview(voiceContainerView)
        voiceContainerView.addSubview(playPauseButton)
        voiceContainerView.addSubview(voiceLoadingIndicator)
        voiceContainerView.addSubview(waveformView) // <- вместо audioSlider
        
        voiceContainerView.isHidden = true
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechStarted), name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechFinished), name: NSNotification.Name("updateAllAudioCellsOnFinish"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSpeechPaused), name: NSNotification.Name("updateAllAudioCellsOnPause"), object: nil)
    }
    
    private func configureAssistantVoiceMessage() {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }
        
        messageContainerView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.width.equalTo(240) // Немного увеличим ширину под слайдер
            make.height.equalTo(50)
        }
        
        voiceContainerView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playPauseButton.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }
        
        voiceLoadingIndicator.snp.remakeConstraints { make in
            make.center.equalTo(playPauseButton)
        }
        
//        audioSlider.snp.remakeConstraints { make in
//            make.leading.equalTo(playPauseButton.snp.trailing).offset(12)
//            make.trailing.equalToSuperview().inset(16)
//            make.centerY.equalToSuperview()
//        }
        
        waveformView.snp.remakeConstraints { make in
            make.leading.equalTo(playPauseButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(30) // Фиксированная высота для контейнера жестов волны
        }
    }
    
    @objc private func playPauseTapped() {
        AnalyticService.shared.logEvent(name: "audio message playPause button Tapped", properties: ["isSpeak":"\(isSpeak)"])

        let isCurrentCell = (service.currentSpeakinID == messageID)

        // 1. Если плеер сейчас существует и работает — просто управляем паузой
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
        
        // 2. Если плеера нет (аудио закончилось или это другая ячейка)
        service.stopSpeaking(needNotifyOthers: false)
        service.currentSpeakinID = messageID
        
        // Проверяем: если файл уже лежит в темпе — просто играем его без интернета!
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("speech.mp3")
        if FileManager.default.fileExists(atPath: tempURL.path) && isCurrentCell {
            // Просто создаем новый плеер из существующего файла!
            let playerItem = AVPlayerItem(url: tempURL)
            NotificationCenter.default.addObserver(service, selector: #selector(service.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            service.audioPlayer = AVPlayer(playerItem: playerItem)
            service.audioPlayer?.play()
            
            // Перематываем, если юзер подвинул слайдер перед стартом
//            if audioSlider.value > 0 {
//                let duration = CMTimeGetSeconds(playerItem.duration)
//                if duration > 0 && !duration.isNaN {
//                    let newTime = Double(audioSlider.value) * duration
//                    service.audioPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 1000))
//                }
//            }
            if waveformView.progress > 0 { // <- вместо audioSlider.value
                let duration = CMTimeGetSeconds(playerItem.duration)
                if duration > 0 && !duration.isNaN {
                    let newTime = Double(waveformView.progress) * duration
                    service.audioPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 1000))
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("updateAllAudioCellsOnStart"), object: nil)
            isSpeak = true
        } else {
            // Если файла нет или это вообще другая ячейка — качаем из сети
            service.speak(text: currentMessageText)
            isSpeak = true
        }
    }
    
    @objc private func handleSpeechStarted() {
        DispatchQueue.main.async {
            self.isSpeak = (self.service.currentSpeakinID == self.messageID)
        }
    }

    @objc private func handleSpeechFinished() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Меняем иконку на play
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
            self.playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
            self.voiceLoadingIndicator.stopAnimating()
            
            self.stopDisplayLink()
            
            // Сбрасываем в 0, только если аудио реально закончилось/сбросилось
            self.waveformView.progress = 0
        }
    }
    
    @objc private func handleSpeechPaused() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.service.currentSpeakinID == self.messageID {
                self.stopDisplayLink()
                
                let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
                self.playPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
                self.voiceLoadingIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: - Слайдер & Тайм-трекинг
    
    @objc private func sliderTouchDown(_ slider: UISlider) {
        isDraggingSlider = true
    }
    
    @objc private func sliderTouchUp(_ slider: UISlider) {
        isDraggingSlider = false
        
        // Перематываем AVPlayer на выбранную позицию
        guard let player = service.audioPlayer,
              let currentItem = player.currentItem,
              service.currentSpeakinID == messageID else { return }
        
        let duration = CMTimeGetSeconds(currentItem.duration)
        guard duration > 0 && !duration.isNaN else { return }
        
        let newTime = Double(slider.value) * duration
        let targetTime = CMTime(seconds: newTime, preferredTimescale: 1000)
        
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        // Опционально: можно выводить лейбл с текущими секундами text = format(slider.value * duration)
    }
    
    @objc private func updateWaveProgress() {
        // Защита: не обновляем слайдер из плеера, пока юзер тащит его пальцем
        guard !isDraggingSlider else { return }
        
        guard let player = service.audioPlayer,
              let currentItem = player.currentItem,
              service.currentSpeakinID == messageID else {
            return
        }
        
        let duration = CMTimeGetSeconds(currentItem.duration)
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        guard duration > 0 && !duration.isNaN && !currentTime.isNaN else { return }
        
//        let progress = Float(currentTime / duration)
//        audioSlider.value = progress
        let progress = Float(currentTime / duration)
        waveformView.progress = progress
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

extension ChatCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            let deleteAction = UIAction(
                title: "Delete".localize(),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                guard let self = self else { return }
                AnalyticService.shared.logEvent(name: "UIContext delete", properties: ["":""])
                
                MessageHistoryService().deleteMessage(id: self.messageID)
                self.reloadDataHandler?()
            }
            
            return UIMenu(title: "", children: [
                UIAction(title: "Copy".localize(), image: UIImage(systemName: "doc.on.doc")) { _ in
                    AnalyticService.shared.logEvent(name: "UIContext Copy", properties: ["":""])
                    if !(self?.messageLabel.isHidden ?? true) {
                        UIPasteboard.general.string = self?.messageLabel.text ?? " "
                    }
                },
                UIAction(title: "SelectText".localize(), image: UIImage(systemName: "text.cursor"), handler: { _ in
                    AnalyticService.shared.logEvent(name: "UIContext SelectText", properties: ["":""])
                    guard !(self?.messageLabel.isHidden ?? true) else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        guard let self = self else { return }
                        self.messageLabel.isSelectable = true
                        self.messageLabel.becomeFirstResponder()

                        if let textRange = self.messageLabel.textRange(
                            from: self.messageLabel.beginningOfDocument,
                            to: self.messageLabel.endOfDocument
                        ) {
                            self.messageLabel.selectedTextRange = textRange
                        }
                    }
                }),
                UIAction(title: "Share".localize(), image: UIImage(systemName: "square.and.arrow.up")) { _ in
                    AnalyticService.shared.logEvent(name: "UIContext Share", properties: ["":""])
                    
                    var activityItems: [Any] = []
                    if let image = self?.messageImageView.image, !(self?.messageImageView.isHidden ?? true) {
                        guard IAPService.shared.hasActiveSubscription else {
                            self?.showSubsHandler?()
                            return
                        }
                        activityItems.append(image)
                        activityItems.append("\("ResourceImage".localize()) \(SubsView.Constants.appStoreUrl)")
                    } else if let textToShare = self?.messageLabel.text, !(self?.messageLabel.isHidden ?? true) {
                        activityItems.append(textToShare + "\n\n\("ResourceText".localize()) \(SubsView.Constants.appStoreUrl)")
                    } else {
                        return
                    }
                    
                    guard !activityItems.isEmpty else { return }

                    let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    if let popoverController = activityController.popoverPresentationController {
                        popoverController.sourceView = self?.messageContainerView
                        popoverController.sourceRect = self?.messageContainerView.bounds ?? .zero
                    }
                    self?.vc?.present(activityController, animated: true, completion: nil)
                },
                
                deleteAction
            ])
        }
    }
}

extension ChatCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        messageLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        statusLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        messageImageView.layer.cornerRadius = 22
        messageContainerView.layer.cornerRadius = 28
        avatarView.layer.cornerRadius = 26
    }
}

// todo со временем можно линки на видосики начать кидать -- фича
extension ChatCell: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard let vc = vc else { return false }
        hideKeyboardHandler?() // прячем клавиатуру, если надо

        let safariVC = SFSafariViewController(url: URL)
        safariVC.modalPresentationStyle = .pageSheet
        vc.present(safariVC, animated: true)

        return false // отменяем дефолтное открытие в Safari
    }
}

extension ChatCell: AVPlayerViewControllerDelegate {
    
    func playerViewControllerWillDisappear(_ playerViewController: AVPlayerViewController) {
        playerViewController.player?.pause()
        
        if let manager = self.loopingPlayerManager {
            // Критично: Удаляем KVO-наблюдателя перед тем, как обнулить manager.
            manager.player.removeObserver(manager, forKeyPath: "rate")
        }
        
        // Обнуление сильной ссылки, которое вызывает deinit менеджеров.
        self.loopingPlayerManager = nil
    }
}
