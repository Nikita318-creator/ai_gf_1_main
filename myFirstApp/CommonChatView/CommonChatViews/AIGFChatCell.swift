import UIKit
import SafariServices
import StoreKit
import SnapKit
import AVFoundation
import AVKit

class AIGFChatCell: UITableViewCell {
    static let identifier = "AIGFChatCell"

    let reactions = [
        (emoji: "❤️", id: "heart"),
        (emoji: "👍", id: "up"),
        (emoji: "👎", id: "down"),
        (emoji: "😂", id: "laugh"),
        (emoji: "😭", id: "cry"),
        (emoji: "😡", id: "angry")
    ]
    
    private let reactionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground // Темный фон реакции
        view.layer.cornerRadius = 11
        view.layer.borderWidth = 2
        view.layer.borderColor = MyColors.background.cgColor
        view.isHidden = true
        return view
    }()

    private let reactionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        return label
    }()
    
    private var overlayView: UIView?

    // Новый лейбл для имени персонажа сверху ячейки
    private let characterNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = MyColors.link // Цвет как у ссылок в ТГ, либо можно поставить любой другой custom
        label.isHidden = true
        return label
    }()
    private var currentCharacterInGroupAvatarName: String?
    
    private var loopingPlayerManager: LoopingPlayerManager?

    private let messageContainerView = UIView()
    private lazy var messageLabel: UITextView = {
        let messageTextView = UITextView()
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.isSelectable = false  // <-- вот эта строка вырубает выделение по long press
        messageTextView.dataDetectorTypes = .link
        messageTextView.backgroundColor = .clear
        messageTextView.textContainerInset = .zero
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageTextView.textColor = MyColors.textPrimary
        messageTextView.linkTextAttributes = [
            .foregroundColor: MyColors.link,
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
        label.textColor = MyColors.textSecondary
        label.isHidden = true
        return label
    }()
    
    private lazy var copyAllTextButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isNeedBigTextForIPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: "doc.on.doc")?.withConfiguration(config)
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isNeedBigTextForIPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: "hand.thumbsup.fill")?.withConfiguration(config)
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()

    private lazy var dislikeButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isNeedBigTextForIPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: "hand.thumbsdown.fill")?.withConfiguration(config)
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = isNeedBigTextForIPad() ? 16 : 8
        stackView.isHidden = true
        return stackView
    }()

    private let blurryOverlayView: AIGFMessageOverlayBlurView = {
        let view = AIGFMessageOverlayBlurView()
        view.isHidden = true // Изначально скрываем его
        view.isUserInteractionEnabled = true // Важно, чтобы можно было обрабатывать тапы
        return view
    }()
    
    private let playIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = MyColors.textPrimary
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold, scale: .large)
        imageView.image = UIImage(systemName: "play.circle.fill")?.withConfiguration(config)
        imageView.isHidden = true
        return imageView
    }()
    
    weak var vc: UIViewController?
    var hideKeyboardHandler: (() -> Void)?
    var showSubsHandler: (() -> Void)?
    var likeTappedHandler: ((Bool) -> Void)?
    var copyTappedHandler: (() -> Void)?
    var reloadDataHandler: (() -> Void)?
    var avatarTappedHandler: ((String?) -> Void)?

    private var messageID = ""
    private var isVideoCell = false
    private var videoID: String?
    private var isNewVideoCell = false
    private var photoForDressUp: UIImage?

    // MARK: - Voice Message Elements (Обновленные)
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
    
    // Маленький лоадер специально для кнопки аудио-сообщения
    private let voiceLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = MyColors.textPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Вместо waveStackView используем интерактивный слайдер
    private lazy var audioSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.minimumTrackTintColor = MyColors.textPrimary
        slider.maximumTrackTintColor = MyColors.textPrimary.withAlphaComponent(0.3)
        
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
    
    private lazy var waveformView: AIGFMessageWaveView = {
        let wave = AIGFMessageWaveView()
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
    private let service = VoiceManager.shared
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
                    let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                    playPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
                    voiceLoadingIndicator.stopAnimating()
                    startDisplayLink()
                } else {
                    let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
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
        likeButton.tintColor = MyColors.textSecondary
        dislikeButton.tintColor = MyColors.textSecondary
        voiceLoadingIndicator.stopAnimating()
        audioSlider.value = 0
        waveformView.progress = 0
        isDraggingSlider = false
        reactionLabel.text = ""
        characterNameLabel.isHidden = true
        characterNameLabel.text = nil
        avatarView.image = nil
        stopDisplayLink()
    }
    
    deinit {
        VoiceManager.shared.currentSpeakinID = nil
        VoiceManager.shared.stopSpeaking()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(characterNameLabel)

        messageContainerView.layer.cornerRadius = 18
        messageContainerView.layer.masksToBounds = false
        messageContainerView.layer.shadowColor = MyColors.background.cgColor
        messageContainerView.layer.shadowOpacity = 0.1
        messageContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        messageContainerView.layer.shadowRadius = 2
        contentView.addSubview(messageContainerView)

        avatarView.backgroundColor = MyColors.avatarBackground
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        contentView.addSubview(avatarView)

        if BaseManager.shared.currentAssistant?.avatarImageName.isEmpty ?? true {
            avatarView.image = BaseManager.shared.currentAssistantImage
        } else {
            let imageName = BaseManager.shared.currentAssistant?.avatarImageName ?? ""
            avatarView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (imageName + "_") : imageName)) ?? UIImage(named: imageName) ?? BaseManager.shared.currentAssistantImage
        }

        if let photoForDressUp {
            avatarView.image = photoForDressUp
        }
        
        messageContainerView.addSubview(messageLabel)
        messageContainerView.addSubview(messageImageView)
        messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(messageImageTapped)))

        loadingIndicator.color = MyColors.textSecondary
        loadingIndicator.isHidden = true
        messageContainerView.addSubview(loadingIndicator)
        messageContainerView.addSubview(statusLabel)

        // Добавляем кнопки регенерации, лайка и дизлайка
        buttonStackView.addArrangedSubview(copyAllTextButton)
        buttonStackView.addArrangedSubview(likeButton)
        buttonStackView.addArrangedSubview(dislikeButton)
        messageContainerView.addSubview(buttonStackView)
        
        copyAllTextButton.addTarget(self, action: #selector(copyAllTextButtonTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        dislikeButton.addTarget(self, action: #selector(dislikeButtonTapped), for: .touchUpInside)

//        let interaction = UIContextMenuInteraction(delegate: self)
//        messageContainerView.addInteraction(interaction)

        messageImageView.addSubview(playIconImageView)
        messageImageView.bringSubviewToFront(playIconImageView) // Гарантируем, что иконка над размытием
        messageImageView.addSubview(blurryOverlayView)
        
        blurryOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview() // Центрируем иконку
            let iconSize: CGFloat = isNeedBigTextForIPad() ? 80 : 60
            make.width.height.equalTo(iconSize)
        }
        
        setupAudioUI()
        
        contentView.addSubview(reactionContainer)
        reactionContainer.addSubview(reactionLabel)
        reactionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
        setupLongPressForReactions()
    }

    func configure(message: String, isUserMessage: Bool, photoID: String, needHideActionButtons: Bool, id: String, isVoiceMessage: Bool, reaction: String?, avatarName: String?) {
        messageID = id
        isVideoCell = message.contains("[video]")
        isNewVideoCell = message.contains("[new video]")
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        avatarView.isHidden = isUserMessage
        messageContainerView.layer.maskedCorners = isUserMessage
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        playIconImageView.isHidden = true
        self.isVoiceMessage = isVoiceMessage
        
        if let name = BaseManager.shared.currentAssistant?.avatarImageName, name.contains("waifuInOutfit_") {
            photoForDressUp = MiniGamesPhotoCacheService.shared.getImage(named: name)
        }
        
        // Обработка префикса ***[Имя]***
        var cleanMessage = message
        var characterName: String? = nil
        
        // Регулярное выражение ищет структуры вида ***[...]*** строго в начале строки
        if let regex = try? NSRegularExpression(pattern: "^\\*\\*\\*(.*?)\\*\\*\\*", options: []) {
            let nsString = message as NSString
            let results = regex.matches(in: message, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = results.first {
                // Вытаскиваем то, что внутри звездочек
                characterName = nsString.substring(with: match.range(at: 1))
                
                // Удаляем весь префикс ***[...]*** из финального текста сообщения
                cleanMessage = nsString.replacingCharacters(in: match.range, with: "")
                
                // Выпиливаем лишнее двоеточие и пробелы, которые остались в начале сообщения
                if cleanMessage.hasPrefix(":") {
                    cleanMessage.removeFirst() // удаляем само двоеточие
                    // Убираем оставшиеся пробелы в начале (если они были, например ": Привет")
                    cleanMessage = cleanMessage.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        let superCleanText = cleanMessage.replacingOccurrences(
            of: "[\\*\\[\\]\\(\\)]",
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        currentMessageText = superCleanText

        if !isUserMessage {
            let imageName = BaseManager.shared.currentAssistant?.avatarImageName ?? ""
            avatarView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (imageName + "_") : imageName)) ?? UIImage(named: imageName) ?? BaseManager.shared.currentAssistantImage
            if let photoForDressUp {
                avatarView.image = photoForDressUp
            }
        }

        if isVoiceMessage && !isUserMessage {
            messageLabel.isHidden = true
            messageImageView.isHidden = true
            voiceContainerView.isHidden = false
            messageContainerView.backgroundColor = MyColors.assistantMessageBackground
            configureAssistantVoiceMessage(hasNameLabel: characterName != nil)
            
            // Проверяем: играет ли СЕЙЧАС именно это сообщение?
            self.isSpeak = service.isSpeaking && (service.currentSpeakinID == id)
        } else if !photoID.isEmpty { // Если сообщение - картинка
            voiceContainerView.isHidden = true
            messageLabel.isHidden = true
            messageImageView.isHidden = false
            if !isUserMessage && !SubscriptionManager.shared.hasActiveSubscription {
                blurryOverlayView.isHidden = false
            } else {
                blurryOverlayView.isHidden = true
            }
            
            if message.contains("[new pic]") {
                messageImageView.image = GiftRealmPhotoService.shared.getImage(by: photoID)
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
            } else if message.contains("[new video]") {
                videoID = photoID
                playIconImageView.isHidden = false
                
                let url = AdditionalVideosService.shared.getFullUrl(for: photoID)
                let asset = AVAsset(url: url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                let time = CMTime(seconds: 1, preferredTimescale: 60)
                if let imageRef = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                    self.messageImageView.image = UIImage(cgImage: imageRef)
                }
            } else if BaseManager.shared.currentAssistant?.avatarImageName.contains("mainAvatar") == true && !isUserMessage {
                if photoID.contains("firstFoto") {
                    messageImageView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? ("firstFoto_") : "firstFoto"))
                } else {
                    messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? (UIImage(named: APIManager.shared.isRemotePhoto ? ("firstFoto_") : "firstFoto"))
                }
            } else if BaseManager.shared.currentAssistant?.avatarImageName.contains("MyGF") == true && !isUserMessage {
                messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? (UIImage(named: APIManager.shared.isRemotePhoto ? ("firstFoto_") : "firstFoto"))
            } else {
                messageImageView.image = AdditionalRemoteRealmPhotoService.shared.getImage(by: photoID) ?? UIImage(named: photoID) ?? (UIImage(named: APIManager.shared.isRemotePhoto ? ("firstFoto_") : "firstFoto"))
            }
            
            messageContainerView.backgroundColor = MyColors.assistantMessageBackground
            
            if isUserMessage {
                configureUserMessageForImage()
            } else {
                configureAssistantMessageForImage(hasNameLabel: characterName != nil)
            }
            buttonStackView.isHidden = true

        } else { // Если сообщение - текст
            voiceContainerView.isHidden = true
            messageLabel.isHidden = false
            messageImageView.isHidden = true
            messageLabel.text = cleanMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if isUserMessage {
                messageContainerView.backgroundColor = MyColors.userMessageBackground
                configureUserMessageForText()
                buttonStackView.isHidden = true
            } else {
                messageContainerView.backgroundColor = MyColors.assistantMessageBackground
                configureAssistantMessageForText(hasNameLabel: characterName != nil)
                buttonStackView.isHidden = needHideActionButtons
            }
        }
        
        // Настройка лейбла имени персонажа
        if let name = characterName, !isUserMessage {
            characterNameLabel.text = name
            characterNameLabel.isHidden = false
            
//            let avatarViewSize: CGFloat = isCurrentDeviceiPad() ? 52 : 36
            characterNameLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(6)
                make.leading.equalTo(avatarView.snp.trailing).offset(14)
                make.trailing.lessThanOrEqualToSuperview().inset(80)
            }
        } else {
            characterNameLabel.text = nil
            characterNameLabel.isHidden = true
        }
        
        currentCharacterInGroupAvatarName = nil
        if !isUserMessage {
            if let avatarName {
                let finalAvatarImage = (UIImage(named: APIManager.shared.isRemotePhoto ? (avatarName + "_") : avatarName)) ?? UIImage(named: avatarName)
                avatarView.image = finalAvatarImage ?? BaseManager.shared.currentAssistantImage
                currentCharacterInGroupAvatarName = avatarName
            } else {
                avatarView.image = UIImage(named: BaseManager.shared.currentAssistant?.avatarImageName ?? "") ?? BaseManager.shared.currentAssistantImage
            }
            
            if let photoForDressUp {
                avatarView.image = photoForDressUp
            }
        }
        
        if let reactionId = reaction,
           let emoji = reactions.first(where: { $0.id == reactionId })?.emoji {
            
            reactionContainer.isHidden = false
            reactionLabel.text = emoji
            
            if isUserMessage {
                reactionContainer.backgroundColor = MyColors.userMessageBackground
            } else {
                reactionContainer.backgroundColor = MyColors.assistantMessageBackground
            }
            
            reactionContainer.snp.remakeConstraints { make in
                make.bottom.equalTo(messageContainerView.snp.bottom).offset(6)
                if isUserMessage {
                    make.trailing.equalTo(messageContainerView.snp.trailing).offset(-8)
                } else {
                    make.leading.equalTo(messageContainerView.snp.leading).offset(8)
                }
                make.height.equalTo(22)
            }
        } else {
            reactionContainer.isHidden = true
        }
        
        isSpeak = (VoiceManager.shared.currentSpeakinID ?? "") == (messageLabel.text ?? "")
    }

    func setupLongPressForReactions() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        messageContainerView.isUserInteractionEnabled = true
        messageContainerView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let window = window,
              let snapshot = messageContainerView.snapshotView(afterScreenUpdates: true)
        else { return }
        
        hideKeyboardHandler?()
        
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .clear
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlay.bounds
        blurView.alpha = 0
        overlay.addSubview(blurView)
        
        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissOverlay(_:)))
        overlay.addGestureRecognizer(tapToDismiss)
        
        let cellFrameInWindow = messageContainerView.convert(messageContainerView.bounds, to: window)
        
        snapshot.frame = cellFrameInWindow
        snapshot.layer.cornerRadius = messageContainerView.layer.cornerRadius
        snapshot.clipsToBounds = true
        snapshot.layer.shadowColor = MyColors.background.cgColor
        snapshot.layer.shadowOpacity = 0.2
        snapshot.layer.shadowOffset = CGSize(width: 0, height: 2)
        snapshot.layer.shadowRadius = 6
        overlay.addSubview(snapshot)
        
        // --- РАСЧЕТ ПОЗИЦИИ И ШИРИНЫ ---
        let screenWidth = window.bounds.width
        let screenHeight = window.bounds.height
        let sidePadding: CGFloat = 24
        let bottomPadding: CGFloat = 40 // Отступ от низа экрана
        let topPadding: CGFloat = 60    // Отступ от верха экрана
        let menuWidth: CGFloat = screenWidth * 0.52
        
        var targetCenterX = cellFrameInWindow.midX
        if targetCenterX - (menuWidth / 2) < sidePadding {
            targetCenterX = sidePadding + (menuWidth / 2)
        }
        if targetCenterX + (menuWidth / 2) > screenWidth - sidePadding {
            targetCenterX = screenWidth - sidePadding - (menuWidth / 2)
        }
        
        let reactionsWidthEstimate = CGFloat(reactions.count) * 40 + 80
        var reactionsWidth = max(reactionsWidthEstimate, menuWidth * 0.9)
        reactionsWidth = min(reactionsWidth, screenWidth - sidePadding * 2)
        
        // --- РЕАКЦИИ ---
        let reactionsContainer = UIView()
        reactionsContainer.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.96)
        reactionsContainer.layer.cornerRadius = 28
        overlay.addSubview(reactionsContainer)
        
        let reactionsStack = UIStackView()
        reactionsStack.axis = .horizontal
        reactionsStack.spacing = 20
        reactionsStack.distribution = .fillProportionally
        reactionsStack.alignment = .center
        
        for (index, item) in reactions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item.emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20) // Оставил как в твоем коде
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.7
            button.tag = index
            button.addTarget(self, action: #selector(selectReaction(_:)), for: .touchUpInside)
            reactionsStack.addArrangedSubview(button)
        }
        
        reactionsContainer.addSubview(reactionsStack)
        reactionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24))
        }
        
        // --- МЕНЮ ДЕЙСТВИЙ ---
        let actionsContainer = UIView()
        actionsContainer.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.96)
        actionsContainer.layer.cornerRadius = 18
        actionsContainer.clipsToBounds = true
        overlay.addSubview(actionsContainer)
        
        let actionsStack = UIStackView()
        actionsStack.axis = .vertical
        actionsStack.spacing = 0
        
        let actionsData: [(title: String, image: String, destructive: Bool, handler: () -> Void)] = [
            ("Copy".localize(), "doc.on.doc", false, { [weak self] in
                guard let self = self else { return }
                AmplitudeManager.shared.logEvent(name: "UIContext Copy", properties: ["":""])
                if !self.messageLabel.isHidden {
                    UIPasteboard.general.string = self.messageLabel.text ?? " "
                }
                self.dismissOverlay()
            }),
            ("SelectText".localize(), "text.cursor", false, { [weak self] in
                guard let self = self else { return }
                AmplitudeManager.shared.logEvent(name: "UIContext SelectText", properties: ["":""])
                guard !self.messageLabel.isHidden else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.messageLabel.isSelectable = true
                    self.messageLabel.becomeFirstResponder()
                    if let textRange = self.messageLabel.textRange(from: self.messageLabel.beginningOfDocument, to: self.messageLabel.endOfDocument) {
                        self.messageLabel.selectedTextRange = textRange
                    }
                }
                self.dismissOverlay()
            }),
            ("Share".localize(), "square.and.arrow.up", false, { [weak self] in
                guard let self = self else { return }
                AmplitudeManager.shared.logEvent(name: "UIContext Share", properties: ["":""])
                var activityItems: [Any] = []
                if let image = self.messageImageView.image, !self.messageImageView.isHidden {
                    guard SubscriptionManager.shared.hasActiveSubscription else {
                        self.showSubsHandler?()
                        self.dismissOverlay()
                        return
                    }
                    activityItems.append(image)
                    activityItems.append("\("ResourceImage".localize()) \(PaywallView.Constants.appStoreUrl)")
                } else if let textToShare = self.messageLabel.text, !self.messageLabel.isHidden {
                    activityItems.append(textToShare)
                    activityItems.append("\("ResourceText".localize()) \(PaywallView.Constants.appStoreUrl)")
                }
                if !activityItems.isEmpty, let vc = self.vc {
                    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.messageContainerView
                    vc.present(activityViewController, animated: true, completion: nil)
                }
                self.dismissOverlay()
            }),
            ("Delete".localize(), "trash", true, { [weak self] in
                guard let self = self else { return }
                AmplitudeManager.shared.logEvent(name: "UIContext delete", properties: ["":""])
                AIGirlfriendMessagesManager().deleteMessage(id: self.messageID)
                self.reloadDataHandler?()
                self.dismissOverlay()
            })
        ]
        
        for (index, data) in actionsData.enumerated() {
            let button = createActionButton(title: data.title, imageName: data.image, destructive: data.destructive) { data.handler() }
            actionsStack.addArrangedSubview(button)
            if index < actionsData.count - 1 {
                let separator = UIView()
                separator.backgroundColor = MyColors.separator.withAlphaComponent(0.6)
                separator.snp.makeConstraints { $0.height.equalTo(0.5) }
                actionsStack.addArrangedSubview(separator)
            }
        }
        
        actionsContainer.addSubview(actionsStack)
        actionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }
        
        // --- УМНЫЕ КОНСТРЕЙНТЫ (ЧТОБЫ НЕ ВЫЛЕТАЛО ЗА ЭКРАН) ---
        
        reactionsContainer.snp.makeConstraints { make in
            make.centerX.equalTo(overlay.snp.leading).offset(targetCenterX)
            make.width.equalTo(reactionsWidth)
            make.height.equalTo(60)
            
            // Пытаемся быть сверху сообщения
            make.bottom.equalTo(snapshot.snp.top).offset(-16).priority(.high)
            // Но не выше верхнего края экрана
            make.top.greaterThanOrEqualTo(overlay.snp.top).offset(topPadding).priority(.required)
        }
        
        actionsContainer.snp.makeConstraints { make in
            make.centerX.equalTo(overlay.snp.leading).offset(targetCenterX)
            make.width.equalTo(menuWidth)
            
            // Пытаемся быть снизу сообщения
            make.top.equalTo(snapshot.snp.bottom).offset(16).priority(.high)
            // НО: нижний край меню НЕ ДОЛЖЕН уходить за нижний край экрана (priority .required)
            make.bottom.lessThanOrEqualTo(overlay.snp.bottom).offset(-bottomPadding).priority(.required)
        }
        
        window.addSubview(overlay)
        self.overlayView = overlay
        
        // --- АНИМАЦИЯ ---
        let startTransform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        reactionsContainer.transform = startTransform
        actionsContainer.transform = startTransform
        reactionsContainer.alpha = 0
        actionsContainer.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            blurView.alpha = 1.0
        }
        
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.0, options: .curveEaseOut) {
            reactionsContainer.transform = .identity
            actionsContainer.transform = .identity
            reactionsContainer.alpha = 1.0
            actionsContainer.alpha = 1.0
            snapshot.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }
    }
    
    @objc private func dismissOverlay(_ gesture: UITapGestureRecognizer? = nil) {
        overlayView?.removeFromSuperview()
        overlayView = nil
        messageLabel.isSelectable = false  // <-- СБРОС ЗДЕСЬ, чтоб после любого закрытия текст не был selectable
    }
    
    @objc private func selectReaction(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0 && index < reactions.count else { return }
        let selected = reactions[index]
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AmplitudeManager.shared.logEvent(name: "UIContext Reaction Tap", properties: ["emoji_id": selected.id])
        AIGirlfriendMessagesManager().updateReaction(id: messageID, reaction: selected.id)
        reloadDataHandler?()
        dismissOverlay()
        
        if index == 0 || index == 1 || index == 3 {
            if BaseManager.shared.shouldRequestReviewAfterLikeTapped() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
    }
    
    private func createActionButton(title: String, imageName: String, destructive: Bool = false, handler: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = destructive ? MyColors.accentRed : MyColors.textPrimary
        button.setTitleColor(destructive ? MyColors.accentRed : MyColors.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }
    
    func configureLoader() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = false
        messageLabel.isHidden = true
        messageImageView.isHidden = true
        loadingIndicator.startAnimating()
        buttonStackView.isHidden = true
        voiceContainerView.isHidden = true
        
        statusLabel.text = BaseManager.shared.currentAIMessageType.rawValue.localize()
        statusLabel.isHidden = false
        statusLabel.textColor = MyColors.textSecondary
        
        avatarView.isHidden = false
        let imageName = BaseManager.shared.currentAssistant?.avatarImageName ?? ""
        avatarView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (imageName + "_") : imageName)) ?? UIImage(named: imageName) ?? BaseManager.shared.currentAssistantImage
        
        if let photoForDressUp {
            avatarView.image = photoForDressUp
        }
        
        configureAssistantMessageForLoader()
    }

    private func configureAssistantMessageForLoader() {
        messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        messageContainerView.backgroundColor = MyColors.assistantMessageBackground
        avatarView.isHidden = false
        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        
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
        
        let padding: CGFloat = isNeedBigTextForIPad() ? 12 : 8
        let indicatorSize: CGFloat = isNeedBigTextForIPad() ? 24 : 20
        
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
        avatarTappedHandler?(currentCharacterInGroupAvatarName)
    }
    
    @objc private func messageImageTapped() {
        guard let vc = vc else { return }
        
        hideKeyboardHandler?()
        
        guard SubscriptionManager.shared.hasActiveSubscription else {
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
        } else if isNewVideoCell {
            AmplitudeManager.shared.logEvent(name: "messageImageTapped", properties: ["isNewVideo": "\(true)"])
            
            let url = AdditionalVideosService.shared.getFullUrl(for: videoID ?? "")
            
            let player = AVPlayer(url: url)
            
            let audioManager = LoopingAudioManager()
            self.loopingPlayerManager = LoopingPlayerManager(player: player, audioManager: audioManager)

            let playerVC = HardcorePlayerViewController()
            playerVC.player = player
            playerVC.modalPresentationStyle = .fullScreen
            playerVC.delegate = self
            
            vc.present(playerVC, animated: true) {
                player.play()
            }
        } else if let messageImage = messageImageView.image {
            let fullScreenView = PreviewImageView(image: messageImage)
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
        isSpeak = (VoiceManager.shared.currentSpeakinID ?? "") == (messageLabel.text ?? "")
    }
    
    @objc private func updateAudioCellOnFinish(_ notification: Notification) {
        isSpeak = false
    }
    
    @objc private func copyAllTextButtonTapped() {
        AmplitudeManager.shared.logEvent(name: "Message Copy tapped", properties: ["":""])
        
        if !messageLabel.isHidden {
            UIPasteboard.general.string = messageLabel.text
        }
        
        copyTappedHandler?()
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.1, animations: {
            self.copyAllTextButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 6, options: [], animations: {
                self.copyAllTextButton.transform = .identity
            })
        }
    }
    
    @objc private func likeButtonTapped() {
        if likeButton.tintColor == MyColors.textPrimary {
            likeButton.tintColor = MyColors.textSecondary
        } else {
            AmplitudeManager.shared.logEvent(name: "like message ButtonTapped", properties: ["":""])
            likeButton.tintColor = MyColors.textPrimary
            dislikeButton.tintColor = MyColors.textSecondary
            likeTappedHandler?(true)
            
            if BaseManager.shared.shouldRequestReviewAfterLikeTapped() {
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
        if dislikeButton.tintColor == MyColors.textPrimary {
            dislikeButton.tintColor = MyColors.textSecondary
        } else {
            AmplitudeManager.shared.logEvent(name: "dislike message ButtonTapped", properties: ["":""])
            dislikeButton.tintColor = MyColors.textPrimary
            likeButton.tintColor = MyColors.textSecondary
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
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }

        loadingIndicator.snp.remakeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func configureUserMessageForImage() {
        avatarView.isHidden = true
        
        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let photoSize: CGFloat = isNeedBigTextForIPad() ? smallerSide / 2 : 200
        
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

    private func configureAssistantMessageForText(hasNameLabel: Bool) {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = MyColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            if hasNameLabel {
                make.top.equalTo(characterNameLabel.snp.bottom).offset(4)
            } else {
                make.top.equalToSuperview().inset(4)
            }
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
        }

        messageLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }

        if !loadingIndicator.isHidden {
            messageContainerView.snp.remakeConstraints { make in
                if hasNameLabel {
                    make.top.equalTo(characterNameLabel.snp.bottom).offset(4)
                } else {
                    make.top.equalToSuperview().inset(4)
                }
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
    
    private func configureAssistantMessageForImage(hasNameLabel: Bool) {
        avatarView.isHidden = false

        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        let photoSize: CGFloat = isNeedBigTextForIPad() ? smallerSide / 2 : 200
        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.backgroundColor = MyColors.assistantMessageBackground
        messageContainerView.snp.remakeConstraints { make in
            if hasNameLabel {
                make.top.equalTo(characterNameLabel.snp.bottom).offset(4)
            } else {
                make.top.equalToSuperview().inset(4)
            }
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
    
    private func configureAssistantVoiceMessage(hasNameLabel: Bool) {
        avatarView.isHidden = false
        
        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }
        
        messageContainerView.snp.remakeConstraints { make in
            if hasNameLabel {
                make.top.equalTo(characterNameLabel.snp.bottom).offset(4)
            } else {
                make.top.equalToSuperview().inset(4)
            }
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.width.equalTo(240) // Немного увеличим ширину под слайдер
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
        AmplitudeManager.shared.logEvent(name: "audio message playPause button Tapped", properties: ["isSpeak":"\(isSpeak)"])

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
            let isAnime = (11...20).map({ "mainAvatar\($0)" }).contains(BaseManager.shared.currentAssistant?.avatarImageName ?? "")
            service.speak(text: currentMessageText, isAnime: isAnime)
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
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
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
                
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
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
//
//extension ChatCell: UIContextMenuInteractionDelegate {
//    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
//
//            let deleteAction = UIAction(
//                title: "Delete".localize(),
//                image: UIImage(systemName: "trash"),
//                attributes: .destructive
//            ) { _ in
//                guard let self = self else { return }
//                AnalyticService.shared.logEvent(name: "UIContext delete", properties: ["":""])
//
//                MessageHistoryService().deleteMessage(id: self.messageID)
//                self.reloadDataHandler?()
//            }
//
//            return UIMenu(title: "", children: [
//                UIAction(title: "Copy".localize(), image: UIImage(systemName: "doc.on.doc")) { _ in
//                    AnalyticService.shared.logEvent(name: "UIContext Copy", properties: ["":""])
//                    if !(self?.messageLabel.isHidden ?? true) {
//                        UIPasteboard.general.string = self?.messageLabel.text ?? " "
//                    }
//                },
//                UIAction(title: "SelectText".localize(), image: UIImage(systemName: "text.cursor"), handler: { _ in
//                    AnalyticService.shared.logEvent(name: "UIContext SelectText", properties: ["":""])
//                    guard !(self?.messageLabel.isHidden ?? true) else { return }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
//                        guard let self = self else { return }
//                        self.messageLabel.isSelectable = true
//                        self.messageLabel.becomeFirstResponder()
//
//                        if let textRange = self.messageLabel.textRange(
//                            from: self.messageLabel.beginningOfDocument,
//                            to: self.messageLabel.endOfDocument
//                        ) {
//                            self.messageLabel.selectedTextRange = textRange
//                        }
//                    }
//                }),
//                UIAction(title: "Share".localize(), image: UIImage(systemName: "square.and.arrow.up")) { _ in
//                    AnalyticService.shared.logEvent(name: "UIContext Share", properties: ["":""])
//
//                    var activityItems: [Any] = []
//                    if let image = self?.messageImageView.image, !(self?.messageImageView.isHidden ?? true) {
//                        guard IAPService.shared.hasActiveSubscription else {
//                            self?.showSubsHandler?()
//                            return
//                        }
//                        activityItems.append(image)
//                        activityItems.append("\("ResourceImage".localize()) \(SubsView.Constants.appStoreUrl)")
//                    } else if let textToShare = self?.messageLabel.text, !(self?.messageLabel.isHidden ?? true) {
//                        activityItems.append(textToShare + "\n\n\("ResourceText".localize()) \(SubsView.Constants.appStoreUrl)")
//                    } else {
//                        return
//                    }
//
//                    guard !activityItems.isEmpty else { return }
//
//                    let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
//                    if let popoverController = activityController.popoverPresentationController {
//                        popoverController.sourceView = self?.messageContainerView
//                        popoverController.sourceRect = self?.messageContainerView.bounds ?? .zero
//                    }
//                    self?.vc?.present(activityController, animated: true, completion: nil)
//                },
//
//                deleteAction
//            ])
//        }
//    }
//}

extension AIGFChatCell {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }
        
        messageLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        statusLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        messageImageView.layer.cornerRadius = 22
        messageContainerView.layer.cornerRadius = 28
        avatarView.layer.cornerRadius = 26
        characterNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
    }
}

// todo со временем можно линки на видосики начать кидать -- фича
extension AIGFChatCell: UITextViewDelegate {
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

extension AIGFChatCell: AVPlayerViewControllerDelegate {
    
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
