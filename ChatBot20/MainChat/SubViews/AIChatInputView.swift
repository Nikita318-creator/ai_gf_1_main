import UIKit
import SnapKit
import Vision
import CoreImage

class AIChatInputView: UIView {
    let textView = UITextView()
    let sendButton = UIButton(type: .system)
    let galleryButton = UIButton(type: .system)
    let placeholderLabel = UILabel()
    private let inputContainer = UIView()
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let separatorView = UIView()

    // Горизонтальный скроллвью для промптов
    private let promptsScrollView = UIScrollView()
    let promptsStackView = UIStackView() // Для размещения кнопок промптов

    // Массив промптов
    private let prompts: [String] = [
        "suggestedPrompt2".localize(),
        "suggestedPrompt3".localize(),
        "suggestedPrompt4".localize(),
        "suggestedPrompt5".localize(),
        "suggestedPrompt6".localize(),
        "suggestedPrompt7".localize(),
        "suggestedPrompt8".localize(),
        "suggestedPrompt9".localize(),
        "suggestedPrompt10".localize(),
        "suggestedPrompt11".localize(),
        "suggestedPrompt12".localize(),
        "suggestedPrompt13".localize(),
        "suggestedPrompt14".localize(),
        "suggestedPrompt15".localize()
    ]
    
    private let promptsEx: [String] = [
        "suggestedExPrompt1".localize(),
        "suggestedExPrompt2".localize(),
        "suggestedExPrompt3".localize(),
        "suggestedExPrompt4".localize()
    ]
    
    private let promptsRolePlay: [String] = [
        "suggestedRolePlayPrompt1".localize(),
        "suggestedRolePlayPrompt2".localize(),
        "suggestedRolePlayPrompt3".localize(),
        "suggestedRolePlayPrompt4".localize(),
        "suggestedRolePlayPrompt5".localize(),
        "suggestedRolePlayPrompt6".localize(),
        "suggestedRolePlayPrompt7".localize(),
        "suggestedRolePlayPrompt8".localize(),
        "suggestedRolePlayPrompt9".localize(),
        "suggestedRolePlayPrompt10".localize(),
        "suggestedRolePlayPrompt11".localize(),
        "suggestedRolePlayPrompt12".localize(),
        "suggestedRolePlayPrompt13".localize(),
        "suggestedRolePlayPrompt14".localize(),
        "suggestedRolePlayPrompt15".localize(),
        "suggestedRolePlayPrompt16".localize(),
        "suggestedRolePlayPrompt17".localize(),
        "suggestedRolePlayPrompt18".localize(),
        "suggestedRolePlayPrompt19".localize(),
        "suggestedRolePlayPrompt20".localize(),
        "suggestedRolePlayPrompt21".localize(),
        "suggestedRolePlayPrompt22".localize(),
        "suggestedRolePlayPrompt23".localize(),
        "suggestedRolePlayPrompt24".localize(),
        "suggestedRolePlayPrompt25".localize(),
        "suggestedRolePlayPrompt26".localize(),
        "suggestedRolePlayPrompt27".localize(),
        "suggestedRolePlayPrompt28".localize(),
        "suggestedRolePlayPrompt29".localize(),
        "suggestedRolePlayPrompt30".localize(),
        "suggestedRolePlayPrompt31".localize(),
        "suggestedRolePlayPrompt32".localize()
    ]
    
    var sendMessageHandler: ((String) -> Void)?
    var sendImageHandler: ((UIImage?, [String]?) -> Void)?
    var showInternetErrorAlertHandler: (() -> Void)?
    var giftSendedHandler: ((GiftItem) -> Void)?
    var pleaseWaitHandler: (() -> Void)?
    var textDidChangedHandler: (() -> Void)?
    var needPremiumForAudioHandler: (() -> Void)?
    
    // Telegram цвета
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let inputBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 0.3) // #48484A
    }
    
    private var textViewHeightConstraint: Constraint?
    private let maxTextViewHeight: CGFloat = 120
    private lazy var minTextViewHeight: CGFloat = isCurrentDeviceiPad() ? 50 : 36
    private var isHandlingImage = false
    
    private enum ButtonMode {
        case mic
        case stop
        case send
    }

    private var currentButtonMode: ButtonMode = .mic
    private let recognizer = SpeechRecognitionService()
    private var textFromMic = ""

    // НОВОЕ: Вью для анимации аудио-волны
    private let audioWaveView = UIView()
    private var audioWaveBars: [UIView] = []
    private var isAnimatingAudioWave = false // Флаг для контроля состояния анимации
    private var canSendMessage = true
    private var needScrollTotTheEnd: Bool = true // for RTL (arabic)

    weak var vc: UIViewController?

    func setup() {
        setupBackground()
        setupPromptsScrollView()
        setupInputContainer()
        setupTextView()
        setupAudioWaveView() // НОВОЕ: Настройка вью для аудио-волны
        setupButtons()
        setupGalleryButton()
        setupConstraints()
        updateActionButtonUI()
        updateTextForIPadIfNeeded()
        
        recognizer.vc = vc
        recognizer.onResult = { [weak self] text in
            print("🎤 Recognized: \(text)")
            self?.textFromMic = text
            self?.textView.text = text
            self?.updateTextViewHeight()
        }
    }
    
    func updateForRLTIfNeeded() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        if isRTL, needScrollTotTheEnd {
            let rightOffset = CGPoint(x: promptsScrollView.contentSize.width - promptsScrollView.bounds.width + promptsScrollView.contentInset.right, y: 0)
            promptsScrollView.setContentOffset(rightOffset, animated: false)
        }
    }
    
    func remakeConstraintsForloveChat() {
        inputContainer.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            make.top.greaterThanOrEqualTo(promptsScrollView.snp.bottom).offset(12)
        }
    }
    
    private var heartImageViews: [UIImageView] = []
    
    func setHartsForLoveChat(count: Int) {
        promptsStackView.arrangedSubviews.forEach { view in
            if view.tag != 19 {
                promptsStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }
        
        heartImageViews.removeAll()
        
        let totalHearts = 10
        let filledCount = min(max(0, count), totalHearts)
        
        let filledHeartColor = UIColor.red
        let emptyHeartColor = TelegramColors.textSecondary
        let heartSize: CGFloat = 20.0
        
        for i in 0..<totalHearts {
            let isFilled = i < filledCount
            
            let imageName = isFilled ? "heart.fill" : "heart"
            let tintColor = isFilled ? filledHeartColor : emptyHeartColor
            
            let heartImage = UIImage(systemName: imageName)?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: heartSize, weight: .regular))
            
            let imageView = UIImageView(image: heartImage)
            imageView.tintColor = tintColor
            imageView.contentMode = .scaleAspectFit
            imageView.tag = 20 + i
            
            imageView.snp.makeConstraints { make in
                make.width.equalTo(heartSize)
                make.height.equalTo(heartSize)
            }
            
            promptsStackView.addArrangedSubview(imageView)
            heartImageViews.append(imageView)
        }
        
        if let giftButton = promptsStackView.arrangedSubviews.first,
           let _ = heartImageViews.first {
            promptsStackView.setCustomSpacing(12, after: giftButton)
        }
        
        promptsStackView.layoutIfNeeded()
    }
    
    private func setupBackground() {
        backgroundColor = .clear
        
        backgroundBlurView.alpha = 0.3
        addSubview(backgroundBlurView)
        
        separatorView.backgroundColor = TelegramColors.separator
        addSubview(separatorView)
    }

    func resetPromptsScrollView() {
        if let playButton = promptsStackView.viewWithTag(777) as? UIButton {
            let newTitle = MainHelper.shared.isLetsPlayMode ? "suggestedPromptLetsChat".localize() : "suggestedPromptLetsPlay".localize()
            
            playButton.setTitle(newTitle, for: .normal)
            
            UIView.animate(withDuration: 0.2) {
                self.promptsStackView.layoutIfNeeded()
            }
        }
    }
    
    private func setupPromptsScrollView() {
        promptsScrollView.showsHorizontalScrollIndicator = false
        promptsScrollView.clipsToBounds = false
        promptsScrollView.alwaysBounceHorizontal = true
        addSubview(promptsScrollView)
        
        promptsStackView.axis = .horizontal
        promptsStackView.spacing = 8
        promptsStackView.alignment = .fill
        promptsStackView.distribution = .fill
        promptsScrollView.addSubview(promptsStackView)
        
        let giftButton = UIButton(type: .system)
        let giftTitle = "SendGift".localize()
        giftButton.setTitle(giftTitle, for: .normal)
        let giftButtonFontSize: CGFloat = isCurrentDeviceiPad() ? 24 : 14
        let giftButtonCornerRadius: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        
        giftButton.titleLabel?.font = UIFont.systemFont(ofSize: giftButtonFontSize, weight: .medium)
        giftButton.setTitleColor(TelegramColors.textPrimary, for: .normal)
        giftButton.backgroundColor = TelegramColors.inputBackground
        giftButton.layer.cornerRadius = giftButtonCornerRadius
        giftButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        giftButton.layer.shadowColor = UIColor.systemBlue.cgColor
        giftButton.layer.shadowOpacity = 0.5
        giftButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        giftButton.layer.shadowRadius = 4
        giftButton.layer.masksToBounds = false
        giftButton.layer.borderWidth = 2
        giftButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        if let giftImage = UIImage(systemName: "gift.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal) {
            giftButton.setImage(giftImage, for: .normal)
            giftButton.imageView?.contentMode = .scaleAspectFit
            giftButton.tag = 19
            
            let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            if isRTL {
                giftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
                giftButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            } else {
                giftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                giftButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            }
        }
        
        giftButton.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
        giftButton.accessibilityIdentifier = "giftButton"
        
        // Всегда добавляем кнопку подарка первой
        promptsStackView.addArrangedSubview(giftButton)
        
        let allPrompts: [String]
        let isEx = MainHelper.shared.currentAssistant?.avatarImageName.contains("ex") == true
        let isRoleplay = MainHelper.shared.currentAssistant?.avatarImageName.contains("roleplay") == true || ["asion74", "asion49", "asion72", "asion89", "asion35", "asion36"].contains(MainHelper.shared.currentAssistant?.avatarImageName ?? "")
        
        let letsPlayPrompt = MainHelper.shared.isLetsPlayMode ? "suggestedPromptLetsChat".localize() : "suggestedPromptLetsPlay".localize()
        
        if ConfigService.shared.isVideoReady {
            if isEx {
                allPrompts = promptsEx.shuffled()
            } else if isRoleplay {
                allPrompts = Array(["suggestedPromptAudio1".localize(), "suggestedPromptVideo".localize(), "suggestedPrompt1".localize(), letsPlayPrompt])
            } else {
                allPrompts = MainHelper.shared.currentAssistantImage == nil
                    ? Array(["suggestedPrompt1".localize(), "suggestedPromptVideo".localize(), "suggestedPromptAudio1".localize(), letsPlayPrompt])
                    : Array(["suggestedPromptVideo".localize(), "suggestedPromptAudio1".localize(), letsPlayPrompt])
            }
        } else {
            if isEx {
                allPrompts = promptsEx.shuffled()
            } else if isRoleplay {
                allPrompts = Array(promptsRolePlay.shuffled().prefix(3) + ["suggestedPromptAudio1".localize(), "suggestedPrompt1".localize()])
            } else {
                allPrompts = MainHelper.shared.currentAssistantImage == nil
                    ? Array(["suggestedPrompt1".localize(), "suggestedPromptAudio1".localize(), letsPlayPrompt])
                    : Array(["suggestedPromptAudio1".localize(), letsPlayPrompt])
            }
        }
        
        let promptButtonSize: CGFloat = isCurrentDeviceiPad() ? 24 : 14
        let promptButtonCornerRadius: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        let font = UIFont.systemFont(ofSize: promptButtonSize, weight: .medium)
        
        for promptText in allPrompts {
            let button = UIButton(type: .system)
            button.setTitle(promptText, for: .normal)
            button.titleLabel?.font = font
            button.titleLabel?.numberOfLines = 2
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.setTitleColor(TelegramColors.textPrimary, for: .normal)
            button.backgroundColor = TelegramColors.inputBackground
            button.layer.cornerRadius = promptButtonCornerRadius
            
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
            
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.1
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 2
            
            button.addTarget(self, action: #selector(promptButtonTapped(_:)), for: .touchUpInside)
            
            let textWidthSingleLine = (promptText as NSString).size(withAttributes: [.font: font]).width
            let halfWidth = ceil(textWidthSingleLine / 2.0)
            
            let targetWidthForWrap = halfWidth + 40
            
            let constraintSize = CGSize(width: targetWidthForWrap, height: CGFloat.greatestFiniteMagnitude)
            let boundingRect = (promptText as NSString).boundingRect(
                with: constraintSize,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            
            let textWidth = ceil(boundingRect.width)
            let calculatedWidth = textWidth + button.contentEdgeInsets.left + button.contentEdgeInsets.right
            
            let absoluteMinWidth: CGFloat = isCurrentDeviceiPad() ? 100 : 80
            let finalWidth = max(absoluteMinWidth, calculatedWidth)
            
            button.snp.makeConstraints { make in
                make.width.equalTo(finalWidth).priority(.required)
            }
            
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            if promptText == "suggestedPromptLetsChat".localize() || promptText == "suggestedPromptLetsPlay".localize() {
                button.tag = 777
            }
            
            if promptText == "suggestedPromptAudio1".localize() || promptText == "suggestedPromptAudio2".localize() {
                button.tag = 888
            }
            
            promptsStackView.addArrangedSubview(button)
        }
    }
    
    private func setupInputContainer() {
        inputContainer.backgroundColor = TelegramColors.inputBackground
        inputContainer.layer.cornerRadius = 18
        inputContainer.layer.shadowColor = UIColor.black.cgColor
        inputContainer.layer.shadowOpacity = 0.1
        inputContainer.layer.shadowOffset = CGSize(width: 0, height: 1)
        inputContainer.layer.shadowRadius = 3
        addSubview(inputContainer)
    }
    
    private func setupTextView() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = TelegramColors.textPrimary
        textView.backgroundColor = .clear
        textView.textAlignment = isRTL ? .right : .left
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = true
//        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
        
        placeholderLabel.text = "WriteMessage".localize()
        placeholderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = TelegramColors.textSecondary
        placeholderLabel.textAlignment = isRTL ? .right : .left
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        inputContainer.addSubview(textView)
        inputContainer.addSubview(placeholderLabel)
    }

    // НОВОЕ: Настройка вью для анимации аудио-волны
    private func setupAudioWaveView() {
        audioWaveView.backgroundColor = .clear
        audioWaveView.isHidden = true // Изначально скрыта
        inputContainer.addSubview(audioWaveView)

        // Добавляем констрейнты для audioWaveView
        audioWaveView.snp.makeConstraints { make in
            // Располагаем audioWaveView там же, где и textView/placeholderLabel
            make.leading.trailing.equalTo(textView)
            make.centerY.equalTo(textView)
            make.height.equalTo(minTextViewHeight) // Высота волны соответствует минимальной высоте текстового поля
        }

        // Создаем несколько вертикальных полосок для имитации волны
        let numberOfBars = 5
        let barSpacing: CGFloat = 4 // Отступ между полосками
        let barWidth: CGFloat = 4 // Ширина каждой полоски

        for i in 0..<numberOfBars {
            let bar = UIView()
            bar.backgroundColor = TelegramColors.textSecondary // Цвет полосок
            bar.layer.cornerRadius = 1.5 // Слегка закругленные углы для полосок
            audioWaveView.addSubview(bar)
            audioWaveBars.append(bar)

            bar.snp.makeConstraints { make in
                make.width.equalTo(barWidth)
                make.height.equalTo(minTextViewHeight * 0.5) // Изначальная высота полоски
                make.centerY.equalToSuperview() // Центрируем по вертикали внутри audioWaveView
                // Располагаем полоски горизонтально с отступами
                make.leading.equalTo(i == 0 ? 0 : audioWaveBars[i-1].snp.trailing).offset(barSpacing)
            }
        }
    }
    
    private func setupButtons() {
        sendButton.layer.cornerRadius = 18
        sendButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureHandler(_:)))
        longPressGesture.minimumPressDuration = 0.5
        sendButton.addGestureRecognizer(longPressGesture)
        addSubview(sendButton)
    }
    
    private func setupConstraints() {
        backgroundBlurView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(-100)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        promptsScrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(inputContainer.snp.top).offset(-12)
            make.height.equalTo(60)
        }

        promptsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.center.equalTo(inputContainer)
            make.width.height.equalTo(36)
        }
        
        inputContainer.snp.makeConstraints { make in
            make.leading.equalTo(galleryButton.snp.trailing).inset(-8)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            make.top.greaterThanOrEqualTo(promptsScrollView.snp.bottom).offset(12)
        }
        
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(6)
            textViewHeightConstraint = make.height.equalTo(minTextViewHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textView)
            make.centerY.equalTo(textView)
        }
        
        galleryButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalTo(inputContainer)
            make.width.height.equalTo(36)
        }
    }
    
    private func setupGalleryButton() {
        let cameraImage = UIImage(systemName: "camera")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .regular))
        
        galleryButton.setImage(cameraImage, for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = TelegramColors.inputBackground
        galleryButton.layer.cornerRadius = 18
        
        galleryButton.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        addSubview(galleryButton)
    }
    
    private func updateActionButtonUI() {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Логика смены режима кнопки
        if hasText {
            currentButtonMode = .send
        } else {
            if currentButtonMode != .stop {
                currentButtonMode = .mic
            }
        }
        
        var image: UIImage?
        var backgroundColor: UIColor

        // НОВОЕ: Управление видимостью элементов и анимацией волны
        textView.isHidden = false
        placeholderLabel.isHidden = !textView.text.isEmpty
        audioWaveView.isHidden = true
        stopAudioWaveAnimation() // Останавливаем анимацию по умолчанию

        let pointSize: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        switch currentButtonMode {
        case .mic:
            image = UIImage(systemName: "mic.fill")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            )
            backgroundColor = TelegramColors.inputBackground
            if textView.inputView != nil {
                textView.resignFirstResponder()
                textView.inputView = nil
                textView.reloadInputViews()
            }
        case .stop:
            image = UIImage(systemName: "stop.fill")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            )
            backgroundColor = .systemRed
//            textView.isHidden = true // Скрываем текстовое поле
            placeholderLabel.isHidden = true // Скрываем плейсхолдер
            audioWaveView.isHidden = true // Показываем аудио-волну
            startAudioWaveAnimation() // Запускаем анимацию
            textView.inputView = UIView()
            textView.reloadInputViews()
            textView.becomeFirstResponder()
        case .send:
            image = UIImage(systemName: "paperplane.fill")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            )
            backgroundColor = canSendMessage ? TelegramColors.primary : TelegramColors.inputBackground
            if textView.inputView != nil {
                textView.resignFirstResponder()
                textView.inputView = nil
                textView.reloadInputViews()
            }
        }
        
        sendButton.setImage(image, for: .normal)
        sendButton.tintColor = TelegramColors.textPrimary
        sendButton.backgroundColor = backgroundColor
        
        UIView.animate(withDuration: 0.2) {
            self.sendButton.transform = .identity
        }
    }
    
    private func updateActionButtonUIForLongTap() {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Логика смены режима кнопки
        if hasText {
            currentButtonMode = .send
        } else {
            if currentButtonMode != .stop {
                currentButtonMode = .mic
            }
        }
        
        var image: UIImage?
        var backgroundColor: UIColor

        // НОВОЕ: Управление видимостью элементов и анимацией волны
        textView.isHidden = false
        placeholderLabel.isHidden = !textView.text.isEmpty
        audioWaveView.isHidden = true
        stopAudioWaveAnimation() // Останавливаем анимацию по умолчанию

        let pointSize: CGFloat = isCurrentDeviceiPad() ? 24 : 16
        switch currentButtonMode {
        case .mic:
            image = UIImage(systemName: "mic.fill")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            )
            backgroundColor = TelegramColors.inputBackground
            stopPulsatingMicAnimation()
            if textView.inputView != nil {
                textView.resignFirstResponder()
                textView.inputView = nil
                textView.reloadInputViews()
            }
        case .stop:
            // НОВОЕ: Иконка остается "микрофоном", но фон и цвет меняются
            image = UIImage(systemName: "mic.fill")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            )
            backgroundColor = TelegramColors.primary // оставляем тот же фон
            sendButton.tintColor = .white // делаем иконку белой
            
//            textView.isHidden = true
            placeholderLabel.isHidden = true
            audioWaveView.isHidden = true
            startAudioWaveAnimation()
            startPulsatingMicAnimation()
            textView.inputView = UIView()
            textView.reloadInputViews()
            textView.becomeFirstResponder()
        case .send:
            image = UIImage(systemName: "paperplane.fill")?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            )
            backgroundColor = TelegramColors.primary
            stopPulsatingMicAnimation()
            if textView.inputView != nil {
                textView.resignFirstResponder()
                textView.inputView = nil
                textView.reloadInputViews()
            }
        }
        
        sendButton.setImage(image, for: .normal)
        sendButton.tintColor = TelegramColors.textPrimary
        sendButton.backgroundColor = backgroundColor
        
        UIView.animate(withDuration: 0.2) {
            self.sendButton.transform = .identity
        }
    }
    
    private func startPulsatingMicAnimation() {
        // Создаем слой для пульсирующей анимации
        let pulseLayer = CALayer()
        pulseLayer.backgroundColor = TelegramColors.primary.withAlphaComponent(0.4).cgColor
        pulseLayer.frame = sendButton.bounds
        pulseLayer.cornerRadius = sendButton.layer.cornerRadius
        sendButton.layer.insertSublayer(pulseLayer, at: 0)
        
        // Анимация увеличения и затухания
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 3.0
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.8
        opacityAnimation.toValue = 0.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseLayer.add(groupAnimation, forKey: "pulsingAnimation")
        
        // Сохраняем слой в свойство, чтобы потом его можно было удалить
        sendButton.layer.setValue(pulseLayer, forKey: "pulseLayer")
    }

    private func stopPulsatingMicAnimation() {
        // Находим слой по ключу и удаляем его, чтобы остановить анимацию
        if let pulseLayer = sendButton.layer.value(forKey: "pulseLayer") as? CALayer {
            pulseLayer.removeFromSuperlayer()
            sendButton.layer.setValue(nil, forKey: "pulseLayer")
        }
    }
    
    private func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = max(minTextViewHeight, min(maxTextViewHeight, size.height))
        
        textViewHeightConstraint?.update(offset: newHeight)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.layoutIfNeeded()
        }
        
        textView.isScrollEnabled = true
    }

    // НОВОЕ: Запуск анимации аудио-волны
    private func startAudioWaveAnimation() {
        guard !isAnimatingAudioWave else { return }
        isAnimatingAudioWave = true

        let maxScaleY: CGFloat = 2.0 // Максимальный множитель высоты полоски
        let minScaleY: CGFloat = 0.5 // Минимальный множитель высоты полоски
        let animationDuration: TimeInterval = 0.6 // Длительность одного цикла анимации

        for (index, bar) in audioWaveBars.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = minScaleY
            animation.toValue = maxScaleY
            animation.autoreverses = true // Анимация будет проигрываться вперед и назад
            animation.repeatCount = .infinity // Повторять бесконечно
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // Плавное начало и конец
            // Задержка для каждой полоски, чтобы создать эффект "волны"
            animation.beginTime = CACurrentMediaTime() + Double(index) * (animationDuration / Double(audioWaveBars.count))

            bar.layer.add(animation, forKey: "scaleAnimation")
        }
    }

    // НОВОЕ: Остановка анимации аудио-волны
    private func stopAudioWaveAnimation() {
        guard isAnimatingAudioWave else { return }
        isAnimatingAudioWave = false
        for bar in audioWaveBars {
            bar.layer.removeAnimation(forKey: "scaleAnimation")
        }
    }
    
    // MARK: - Actions
        
    @objc private func actionButtonTapped() {
        switch currentButtonMode {
        case .mic:
            textFromMic = ""
            print("Mic button tapped - Start recording")
            currentButtonMode = .stop
            updateActionButtonUI()
            recognizer.startRecognition()
            
        case .stop:
            print("Stop button tapped - Stop recording")
            currentButtonMode = .mic
            updateActionButtonUI()
            recognizer.stopRecognition()
            sendAudio(text: textFromMic)

        case .send:
            sendButtonTapped()
        }
    }

    @objc private func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            textFromMic = ""
            print("Mic button tapped - Start recording")
            currentButtonMode = .stop
            updateActionButtonUIForLongTap()
            recognizer.startRecognition()
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
        case .ended, .cancelled:
            currentButtonMode = .mic
            updateActionButtonUIForLongTap()
            recognizer.stopRecognition()
            sendAudio(text: textFromMic)
        default:
            break
        }
    }
    
    func enableSendButton() {
        canSendMessage = true
        if self.currentButtonMode == .send {
            self.sendButton.backgroundColor = TelegramColors.primary
        }
    }
    
    private func sendButtonTapped() {
        guard canSendMessage, let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            pleaseWaitHandler?()
            return
        }
        canSendMessage = false
        self.sendButton.backgroundColor = TelegramColors.inputBackground
        
        guard NetworkMonitor.shared.isConnected else {
            showInternetErrorAlertHandler?()
            return
        }
        
        if text.contains("suggestedPromptAudio1".localize()) || text.contains("suggestedPromptAudio2".localize()) {
            guard IAPService.shared.hasActiveSubscription else {
                enableSendButton()
                needPremiumForAudioHandler?()
                return
            }
            updateAudioTagButton()
        }
        
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        if let language = textView.textInputMode?.primaryLanguage {
            print("currentLanguage \(language)")
            MainHelper.shared.currentLanguage = language
        }
        sendMessageHandler?(text.trimmingCharacters(in: .whitespacesAndNewlines))
        
        UIView.animate(withDuration: 0.2, animations: {
            self.textView.alpha = 0.5
        }) { _ in
            self.textView.text = ""
            self.textView.alpha = 1.0
            self.placeholderLabel.isHidden = false
            self.updateActionButtonUI()
            self.updateTextViewHeight()
        }
    }

    private func sendAudio(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        AnalyticService.shared.logEvent(name: "audio sended with text", properties: ["":""])

        guard NetworkMonitor.shared.isConnected else {
            showInternetErrorAlertHandler?()
            return
        }
        
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        sendMessageHandler?(text.trimmingCharacters(in: .whitespacesAndNewlines))
        
        UIView.animate(withDuration: 0.2, animations: {
            self.textView.alpha = 0.5
        }) { _ in
            self.textView.text = ""
            self.textView.alpha = 1.0
            self.placeholderLabel.isHidden = false
            self.updateActionButtonUI()
            self.updateTextViewHeight()
        }
    }
    
    @objc private func promptButtonTapped(_ sender: UIButton) {
        needScrollTotTheEnd = false
        
        if self.currentButtonMode == .stop {
            print("Stop! prompt tapped - Stop recording")
            updateActionButtonUI()
            recognizer.stopRecognition()
//            sendAudio(text: textFromMic)
        }
        
        if sender.accessibilityIdentifier == "giftButton" {
            sendGiftButtonTapped()
        } else if let promptText = sender.titleLabel?.text {
//            textView.text = promptText
//            textViewDidChange(textView)
//            textView.becomeFirstResponder()
            guard canSendMessage else {
                pleaseWaitHandler?()
                return
            }
            canSendMessage = false
            
            if promptText.contains("suggestedPromptAudio1".localize()) || promptText.contains("suggestedPromptAudio2".localize()) {
                guard IAPService.shared.hasActiveSubscription else {
                    enableSendButton()
                    needPremiumForAudioHandler?()
                    return
                }
                updateAudioTagButton()
            }
            
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            
            if let language = textView.textInputMode?.primaryLanguage {
                print("currentLanguage \(language)")
                MainHelper.shared.currentLanguage = language
            }
            
            sendMessageHandler?(promptText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    func sendGiftButtonTapped() {
        let giftVC = GiftVC()
        giftVC.sendGiftHandler = { [weak self] gift in
            self?.giftSendedHandler?(gift)
            giftVC.dismiss(animated: true)
        }
        vc?.present(giftVC, animated: true, completion: nil)
    }
    
    func updateAudioTagButton() {
        if let audioButton = promptsStackView.viewWithTag(888) as? UIButton {
            let newTitle = MainHelper.shared.isAudioMessagesMode ? "suggestedPromptAudio1".localize() : "suggestedPromptAudio2".localize()
            MainHelper.shared.isAudioMessagesMode.toggle()
            
            audioButton.setTitle(newTitle, for: .normal)
            
            UIView.animate(withDuration: 0.2) {
                self.promptsStackView.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension AIChatInputView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textDidChangedHandler?()
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateActionButtonUI()
        updateTextViewHeight()
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        
        // Лимит на длину текста
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        if updatedText.count > 2000 {
            return false
        }
        
        // Отправка по Enter
//        if text == "\n" {
//            if !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                if currentButtonMode == .send {
//                    sendButtonTapped()
//                    return false
//                }
//            }
//        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.inputContainer.layer.shadowOpacity = 0.2
            self.inputContainer.layer.shadowRadius = 6
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.inputContainer.layer.shadowOpacity = 0.1
            self.inputContainer.layer.shadowRadius = 3
            self.inputContainer.transform = .identity
        }
    }
}

extension AIChatInputView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        inputContainer.layer.cornerRadius = 28
        sendButton.layer.cornerRadius = 28
        galleryButton.layer.cornerRadius = 28
        
        textView.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        placeholderLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        
        promptsScrollView.snp.updateConstraints { make in
            make.height.equalTo(60)
        }

        sendButton.snp.updateConstraints { make in
            make.width.height.equalTo(56)
        }
        
        galleryButton.snp.updateConstraints { make in
            make.width.height.equalTo(56)
        }
    }
}

extension AIChatInputView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @objc func galleryButtonTapped() {
        guard IAPService.shared.hasActiveSubscription else {
            DispatchQueue.main.async {
                self.sendImageHandler?(nil, nil)
            }
            return
        }
        
        guard canSendMessage else { return }
        canSendMessage = false
        
        AnalyticService.shared.logEvent(name: "galleryButtonTapped", properties: ["":""])

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        vc?.present(picker, animated: true)
    }

    // MARK: - UIImagePicker Delegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        analyzeImageWithVision(image) { [weak self] tags in
            print("Detected tags: \(tags)")
            AnalyticService.shared.logEvent(name: "analyzeImageWithVision", properties: ["Detected tags:":"\(tags)"])

            guard self?.isHandlingImage == false else { return }
            self?.isHandlingImage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.isHandlingImage = false
            }
            
            DispatchQueue.main.async {
                self?.sendImageHandler?(image, tags)
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        enableSendButton()
        picker.dismiss(animated: true)
    }

    // MARK: - Apple Vision Image Labeling
    private func analyzeImageWithVision(_ uiImage: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = uiImage.cgImage else {
            completion([])
            return
        }

        let request = VNClassifyImageRequest { request, error in
            guard error == nil else {
                completion([])
                return
            }

            let results = request.results?
                .compactMap { $0 as? VNClassificationObservation }
                .filter { $0.confidence > 0.5 }
                .map { $0.identifier } ?? []

            completion(results)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Vision request failed: \(error)")
                completion([])
            }
        }
    }
}
