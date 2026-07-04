import UIKit
import SnapKit
import StoreKit
//import OneSignalFramework

// Этот класс представляет собой интерфейс голосового чата.
// Он был переработан из текстового чата для соответствия новому функционалу.
class AudioChat: UIView {
    // MARK: - Свойства UI

    private let plusButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let navigationBar = UIView()
    private let gradientLayer = CAGradientLayer()

    // Добавляем UIImageView для аватарки
    private let assistantAvatarImageView = UIImageView()

    // НОВЫЕ СВОЙСТВА ДЛЯ ФОНА
    private let backgroundImageView = UIImageView()
    private let backgroundOverlayView = UIView() // Полупрозрачный черный слой

    // НОВЫЕ СВОЙСТВА ДЛЯ ГОЛОСОВОГО ИНТЕРФЕЙСА
    private let micBackgroundCircleView = UIView()
    private let micButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let stopButton = UIButton(type: .system)
    
    // Новые свойства для облачка с инструкцией
    private let instructionCloud = UIView()
    private let instructionLabel = UILabel()

    let subsView = SubsView()

    weak var vc: UIViewController?
    
    private let viewModel = AIChatViewModel()

    private let recognizer = SpeechRecognitionService()
    private var textFromMic = ""

    // Состояние UI
    private var isListening = false
    private var assistantIsSpeaking = false
    
    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
    }

    func setup() {
        setupObservers()
        setupBackground()
        setupNavigationBar()
        setupVoiceChatUI() // Новый метод для настройки UI голосового чата
        setupInstructionCloud() // Настройка нового облачка с инструкцией
        setupConstraints()
        setupViewModel()
        setupNavTitleAndAvatar()
        setupSwipeToDismiss()
        updateTextForIPadIfNeeded()
        
        recognizer.vc = vc
        recognizer.onResult = { [weak self] text in
            print("🎤 Recognized: \(text)")
            self?.textFromMic = text
        }
    }

    func setupNavTitleAndAvatar() {
        titleLabel.text = MainHelper.shared.currentAssistant?.assistantName
        if let avatarName = MainHelper.shared.currentAssistant?.avatarImageName {
            assistantAvatarImageView.image = UIImage(named: avatarName) 
        }

        if let backgroundName = MainHelper.shared.currentAssistant?.avatarImageName {
            backgroundImageView.image = UIImage(named: backgroundName)
        }
    }

    func setMessagesFromDB() {
        viewModel.messagesAI = viewModel.currentMessagesAI
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopAudioSpeech),
            name: .updateAllAudioCellsOnFinish,
            object: nil
        )
    }
    
    private func setupBackground() {
        backgroundColor = TelegramColors.background
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        backgroundOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(backgroundOverlayView)

        gradientLayer.colors = [
            TelegramColors.background.cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupNavigationBar() {
        navigationBar.backgroundColor = .black.withAlphaComponent(0.3)
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOpacity = 0.1
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navigationBar.layer.shadowRadius = 3
        addSubview(navigationBar)

        assistantAvatarImageView.contentMode = .scaleAspectFill
        assistantAvatarImageView.layer.cornerRadius = 16
        assistantAvatarImageView.clipsToBounds = true
        assistantAvatarImageView.backgroundColor = TelegramColors.textSecondary
        navigationBar.addSubview(assistantAvatarImageView)
        assistantAvatarImageView.isUserInteractionEnabled = true
        assistantAvatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = TelegramColors.textPrimary
        navigationBar.addSubview(titleLabel)

        plusButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        ), for: .normal)
        plusButton.tintColor = TelegramColors.primary
        plusButton.backgroundColor = TelegramColors.messageBackground
        plusButton.layer.cornerRadius = 20
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)

        navigationBar.addSubview(plusButton)
        navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfile)))
    }

    private func setupVoiceChatUI() {
        // Полупрозрачный голубой круг
        micBackgroundCircleView.backgroundColor = TelegramColors.primary.withAlphaComponent(0.2)
        micBackgroundCircleView.layer.cornerRadius = 50 // Половина ширины/высоты
        addSubview(micBackgroundCircleView)

        // Кнопка микрофона
        let micImage = UIImage(systemName: "mic.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        )
        micButton.setImage(micImage, for: .normal)
        micButton.tintColor = TelegramColors.primary
        micButton.backgroundColor = .clear
        addSubview(micButton)

        // Индикатор загрузки
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = TelegramColors.primary
        addSubview(loadingIndicator)
        loadingIndicator.isHidden = true

        // Кнопка "Стоп"
        let stopImage = UIImage(systemName: "square.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        )
        stopButton.setImage(stopImage, for: .normal)
        stopButton.tintColor = TelegramColors.primary
        stopButton.backgroundColor = .clear
        stopButton.isHidden = true
        addSubview(stopButton)

        // Добавляем Long Press Gesture Recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(micLongPressGestureHandler(_:)))
        longPressGesture.minimumPressDuration = 0.1
        micButton.addGestureRecognizer(longPressGesture)
        
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
    }

    // Новый метод для настройки облачка с инструкцией
    private func setupInstructionCloud() {
        instructionCloud.backgroundColor = TelegramColors.messageBackground.withAlphaComponent(0.6)
        instructionCloud.layer.cornerRadius = 16
        instructionCloud.layer.masksToBounds = true
        addSubview(instructionCloud)
        
        instructionLabel.text = "VoiceChat.Instructions".localize()
        instructionLabel.textColor = TelegramColors.textPrimary
        instructionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.adjustsFontSizeToFitWidth = true
        instructionLabel.minimumScaleFactor = 0.5
        instructionCloud.addSubview(instructionLabel)
    }

    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }

        assistantAvatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(titleLabel.snp.leading).offset(-8)
            make.leading.greaterThanOrEqualTo(plusButton.snp.trailing).offset(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(plusButton.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        plusButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }

        // Constraints для голосового интерфейса
        micBackgroundCircleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(50) // Смещаем немного вниз для лучшего вида
            make.width.height.equalTo(100)
        }

        micButton.snp.makeConstraints { make in
            make.center.equalTo(micBackgroundCircleView)
            make.width.height.equalTo(50)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(micBackgroundCircleView)
            make.width.height.equalTo(50)
        }

        stopButton.snp.makeConstraints { make in
            make.center.equalTo(micBackgroundCircleView)
            make.width.height.equalTo(50)
        }
        
        // Constraints для облачка с инструкцией
        instructionCloud.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide)//.offset(-20)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.height.equalTo(70)
        }
        
        instructionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    private func setupViewModel() {
        viewModel.onAudioMessagesUpdated = { [weak self] isSucceed in
            guard
                let self,
//                isSucceed, // пусть и ошибку озвучивает =)
                let textToSpeak = viewModel.messagesAI.last (where: { $0.role == "assistant" && !$0.isLoading })?.content
            else { return }
            
            print("6666666 textToSpeak = \(textToSpeak)")
            SpeechSynthesizerService.shared.speak(text: "'oh', " + textToSpeak)
            
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true
            self.stopButton.isHidden = false
            self.assistantIsSpeaking = true
        }
    }

    private func setupSwipeToDismiss() {
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRightGesture.direction = .right
        self.addGestureRecognizer(swipeRightGesture)
    }
    
    @objc private func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        guard let vc = vc else { return }
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        vc.dismiss(animated: true)
    }
    
    private func sendMessage() {
        guard !textFromMic.isEmpty else {
            let userMessage = Message(role: "assistant", content: "EmptyMessage".localize())
            viewModel.messagesAI.append(userMessage)
            viewModel.onAudioMessagesUpdated?(false)
            return
        }
        
        AnalyticService.shared.logEvent(name: "audio sended in audioChat", properties: ["":""])

        guard MainHelper.shared.canMakeRequest() else {
            textFromMic = ""
            showAlertDailyLimit()
            return
        }

        var previousMessages = ""
        if viewModel.messagesAI.count >= 2 {
            previousMessages = "promp.previosMessagesUser".localize()
            + (self.viewModel.messagesAI[self.viewModel.messagesAI.count - 2].content)
            + "promp.previosMessagesAI".localize()
            + (self.viewModel.messagesAI.last?.content ?? "")
            + "promp.previosMessagesUserStarter".localize()
        }

        print("6666666 textFromMic = \(textFromMic)")

        viewModel.systemPrompt = MainHelper.shared.getSystemPromptForCurrentAssistant()
        viewModel.safeSystemPrompt = MainHelper.shared.getSafeSystemPromptForCurrentAssistant()
        viewModel.previousMessages = previousMessages
        viewModel.sendMessageViaCustomServer(textFromMic)
        messageDidSend()
        textFromMic = ""
    }
    
    private func messageDidSend() {
        // поднимаем текущего ассистента вверх списка:
        if MainHelper.shared.isFirstMessageInChat {
            MainHelper.shared.isFirstMessageInChat = false
            let assistantsService = AssistantsService()
            let assistant = assistantsService.getAllConfigs().first { $0.id == MainHelper.shared.currentAssistant?.id }
            guard let assistantConfig = assistant else { return }
            assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
        }
    }
    
    private func showAlertDailyLimit() {
        let customAlertView = CustomAlertView(type: .dailyLimitReached)
        customAlertView.show(in: self)
        customAlertView.onRateButtonTapped = { [weak self] in self?.showSubs() }
        customAlertView.onLaterButtonTapped = { [weak self] in self?.showSubs() }
    }

    @objc private func plusButtonTapped() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        vc?.dismiss(animated: true)
    }

    @objc private func avatarTapped() {
        openProfile()
    }

    @objc private func openProfile() {
        guard let assistant = MainHelper.shared.currentAssistant else { return }
        
        let allAssistantAvatarIDs = [ // это по сути не надо тут хватит только отличать аудио чаты - главное что у них индексы идут от 12 до 14
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "ex1", "audio1",
            "audio2", "audio3", "CustomAvatar1", "CustomAvatar2",
            "CustomAvatar3", "CustomAvatar4", "CustomAvatar5", "CustomAvatar6",
            "CustomAvatar7", "CustomAvatar8", "CustomAvatar9", "CustomAvatar10",
            "CustomAvatar11", "CustomAvatar12", "CustomAvatar13", "CustomAvatar14",
            "CustomAvatar15", "CustomAvatar16", "CustomAvatar17", "CustomAvatar18",
            "roleplay1", "roleplay2", "roleplay3", "roleplay4", "roleplay5", "roleplay6", "roleplay7", "roleplay8", "roleplay9", "roleplay10", "roleplay11", "roleplay12"
        ]
        
        let index = allAssistantAvatarIDs.firstIndex(of: assistant.avatarImageName) ?? 0
                
        let randomProfile = viewModel.sampleProfiles.indices.contains(index) ? viewModel.sampleProfiles[index] : viewModel.sampleProfiles.randomElement() ?? [:]
        
        if let age = randomProfile["age"] as? Int,
           let country = randomProfile["country"] as? String,
           let city = randomProfile["city"] as? String,
           let bio = randomProfile["bio"] as? String {

            let assistantProfile = AssistantProfile(
                id: assistant.id ?? "",
                avatarImageName: assistant.avatarImageName,
                name: assistant.assistantName,
                age: age,
                country: country,
                city: city,
                bio: bio
            )
            let profileVC = ProfileViewController(assistant: assistantProfile)
            profileVC.modalPresentationStyle = .fullScreen
            profileVC.sendGiftTappedHandler = { [weak self] in
                guard let self else { return }
                profileVC.dismiss(animated: false)
                
                let giftVC = GiftVC()
                giftVC.sendGiftHandler = { [weak self] gift in
                    guard let self else { return }

                    let giftMessage = Message(role: "user", content: "[gift]", photoID: gift.imageName)
                    viewModel.messagesAI.append(giftMessage)
                    viewModel.messageService.addMessage(giftMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "")
                    
                    giftVC.dismiss(animated: true)
                }
                vc?.present(giftVC, animated: true, completion: nil)
            }
            vc?.present(profileVC, animated: true)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    @objc private func micLongPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            print("Начало записи...")
            isListening = true
            // Эффект подсветки
            UIView.animate(withDuration: 0.3, animations: {
                self.micBackgroundCircleView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.micButton.tintColor = .white
                self.micBackgroundCircleView.backgroundColor = TelegramColors.primary.withAlphaComponent(0.8)
                self.instructionCloud.removeFromSuperview()
            }) { [weak self] _ in
                self?.recognizer.startRecognition()
            }
        case .ended:
            // Конец Long Press
            print("Конец записи, отправка на обработку...")
            isListening = false
            // Возвращаем кнопку в исходное состояние и запускаем индикатор загрузки
            UIView.animate(withDuration: 0.3, animations: {
                self.micBackgroundCircleView.transform = .identity
                self.micButton.tintColor = TelegramColors.primary
                self.micBackgroundCircleView.backgroundColor = TelegramColors.primary.withAlphaComponent(0.2)
            }) { [weak self] _ in
                self?.micButton.isHidden = true
                self?.loadingIndicator.isHidden = false
                self?.loadingIndicator.startAnimating()

                self?.recognizer.stopRecognition()
                guard IAPService.shared.hasActiveSubscription else {
                    self?.showCustomAlert(for: .needPremiumForAudio)
                    return
                }
                self?.sendMessage()
            }
            
        default:
            break
        }
    }

    private func showCustomAlert(for type: CustomAlertView.CustomAlertType) {
        let customAlertView = CustomAlertView(type: type)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }
    
    @objc private func stopButtonTapped() {
        stopAudioSpeech()
        SpeechSynthesizerService.shared.stopSpeaking()
    }

    @objc private func stopAudioSpeech() {
        assistantIsSpeaking = false
        stopButton.isHidden = true
        loadingIndicator.isHidden = true
        micButton.isHidden = false
    }
    
    private func showSubs() {
        subsView.vc = vc

        AnalyticService.shared.logEvent(name: "showSubs from audio chat", properties: ["":""])

        addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        subsView.transform = CGAffineTransform(translationX: 0, y: -UIScreen.main.bounds.height)

        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.subsView.transform = .identity
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
//            if isCurrentDeviceiPad() {
                subsView.scrollToBottom()
//            }
            self.subsView.yearlyButtonTapped()
        }
        
        stopAudioSpeech()
    }

    deinit {
        SpeechSynthesizerService.shared.stopSpeaking()
        NotificationCenter.default.removeObserver(self)
        MainHelper.shared.isVoiceChat = false
    }
}

extension AudioChat {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        instructionLabel.font = UIFont.systemFont(ofSize: 32, weight: .regular)

        assistantAvatarImageView.layer.cornerRadius = 30
        
        plusButton.layer.cornerRadius = 30
        
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(90)
        }
        
        assistantAvatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(60)
            make.trailing.equalTo(titleLabel.snp.leading).offset(-20)
        }
        
        plusButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
    }
}
