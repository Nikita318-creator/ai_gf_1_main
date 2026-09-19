import UIKit
import SnapKit
import StoreKit
import UserNotifications

class AIChatView: UIView {
    private lazy var callButton: UIButton = {
        let button = UIButton(type: .system)
        let buttonPointSize: CGFloat = isCurrentDeviceiPad() ? 30 : 18
        let cornerRadius: CGFloat = isCurrentDeviceiPad() ? 30 : 20
        let image = UIImage(systemName: "phone.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        )
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.primary
        button.backgroundColor = MyColors.messageBackground
        button.layer.cornerRadius = cornerRadius
        return button
    }()
    
    private let tableView = UITableView()
    let plusButton = UIButton(type: .system)
    let inputTextView = AIChatInputView()
    let subsView = SubsView()
    private let titleLabel = UILabel()
    private let navigationBar = UIView()
    private let gradientLayer = CAGradientLayer()
    private var keyboardOffset: CGFloat = 0
    private var streakCount: Int = 0
    private var isFirstMessageInChat = true
    private var mainHistoryFact: String?

    private let assistantAvatarImageView = UIImageView()

    private let backgroundImageView = UIImageView()
    private let backgroundOverlayView = UIView() // Полупрозрачный черный слой

    private let streakLabel = UILabel()
    private var streakPopup: UIView?
    
    weak var vc: UIViewController?
    let viewModel = AIChatViewModel()

    private var needUpdateProductsByTapYearlyButton = false

    func setup() {
        setupObservers()
        setupBackground()
        setupNavigationBar()
        setupTableView()
        setupInputView()
        setupConstraints()
        setupViewModel()
        setupNavTitleAndAvatar()
        setMessagesFromDB()
        setupSwipeToDismiss()
        updateTextForIPadIfNeeded()
        
        if MainHelper.shared.currentAssistant?.id?.contains(MainHelper.shared.loveAssistantId) == false {
            checkForeStreak()
        }
        
        if MainHelper.shared.currentAssistant?.avatarImageName == "addsBannerAvatar" {
            inputTextView.hideAllPromptsExceptGift()
            callButton.isHidden = true
        }
        
        if let name = MainHelper.shared.currentAssistant?.avatarImageName, (21...26).map({ "mainAvatar\($0)" }).contains(name) {
            inputTextView.hideVideoPrompt()
            if !ConfigService.shared.isTestB {
                inputTextView.hidePhotoPrompt()
            }
        }
    }

    private func checkForeStreak() {
        let currentID = MainHelper.shared.currentAssistant?.id ?? ""
        streakCount = StreaksService.shared.getStreakCount(for: currentID)
        streakLabel.text = "🔥 \(streakCount)"
        streakLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        streakLabel.textColor = .orange
        streakLabel.isUserInteractionEnabled = true
        streakLabel.isHidden = streakCount == 0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(streakTapped))
        streakLabel.addGestureRecognizer(tap)
        
        if streakLabel.superview == nil {
            navigationBar.addSubview(streakLabel)
            streakLabel.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            }
        }
    }

    @objc private func streakTapped() {
        inputTextView.textView.resignFirstResponder()
        showStreakPopup()
    }

    private func showStreakPopup() {
        if streakPopup != nil { return }
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.alpha = 0
        
        let container = UIView()
        container.backgroundColor = MyColors.cardBackground
        container.layer.cornerRadius = 24
        container.clipsToBounds = true
        
        let fireLabel = UILabel()
        fireLabel.text = "🔥"
        fireLabel.font = UIFont.systemFont(ofSize: 60)
        fireLabel.textAlignment = .center
        
        let infoLabel = UILabel()
        infoLabel.text = "Streak.infoLabelText".localize() + " \(streakCount)"
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .white
        infoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        infoLabel.textAlignment = .center
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Streak.GotIt".localize(), for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = MyColors.primary
        closeButton.layer.cornerRadius = 12
        closeButton.addTarget(self, action: #selector(dismissStreakPopup), for: .touchUpInside)
        
        addSubview(overlay)
        overlay.addSubview(container)
        container.addSubview(fireLabel)
        container.addSubview(infoLabel)
        container.addSubview(closeButton)
        
        overlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
        }
        
        fireLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(fireLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(50)
        }
        
        self.streakPopup = overlay
        
        // Анимация появления
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
        }
    }
    
    func updateForRLTIfNeeded() {
        inputTextView.updateForRLTIfNeeded()
    }
    
    func setupNavTitleAndAvatar() {
        titleLabel.text = MainHelper.shared.currentAssistant?.assistantName
        
        guard let avatarName = MainHelper.shared.currentAssistant?.avatarImageName else { return }
        
        assistantAvatarImageView.image = (UIImage(named: ConfigService.shared.isRemotePhoto ? (avatarName + "_") : avatarName)) ?? UIImage(named: avatarName) ?? MainHelper.shared.currentAssistantImage
        backgroundImageView.image = (UIImage(named: ConfigService.shared.isRemotePhoto ? (avatarName + "_") : avatarName)) ?? UIImage(named: avatarName) ?? MainHelper.shared.currentAssistantImage
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupBackground() {
        backgroundColor = MyColors.background

        backgroundImageView.contentMode = .scaleAspectFill // Заполняет весь экран
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView) // Добавляем первым, чтобы было на самом заднем плане

        backgroundOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4) // Настройте прозрачность (0.0 - 1.0)
        addSubview(backgroundOverlayView) // Добавляем поверх изображения

        gradientLayer.colors = [
            MyColors.background.cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0) // Вставляем на 0-й индекс слоя, чтобы он был поверх backgroundImageView и backgroundOverlayView
    }

    private func setupNavigationBar() {
        // Навигационная панель
        navigationBar.backgroundColor = .black.withAlphaComponent(0.3)
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOpacity = 0.1
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navigationBar.layer.shadowRadius = 3
        addSubview(navigationBar)

        // Аватарка ИИ
        assistantAvatarImageView.contentMode = .scaleAspectFill
        assistantAvatarImageView.layer.cornerRadius = 16 // Делаем круглой
        assistantAvatarImageView.clipsToBounds = true // Обрезаем по радиусу
        assistantAvatarImageView.backgroundColor = MyColors.textSecondary // Фоновый цвет, если изображения нет
        navigationBar.addSubview(assistantAvatarImageView)
        assistantAvatarImageView.isUserInteractionEnabled = true
        assistantAvatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        // Заголовок
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = MyColors.textPrimary
        navigationBar.addSubview(titleLabel)

        let buttonPointSize: CGFloat = isCurrentDeviceiPad() ? 30 : 18
        plusButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        ), for: .normal)
        plusButton.tintColor = MyColors.primary
        plusButton.backgroundColor = MyColors.messageBackground
        plusButton.layer.cornerRadius = 20
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)

        navigationBar.addSubview(plusButton)
        navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfile)))
        navigationBar.addSubview(callButton)
        callButton.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(ChatCell.self, forCellReuseIdentifier: ChatCell.identifier)

        addSubview(tableView)
    }

    private func setupInputView() {
        inputTextView.vc = vc
        addSubview(inputTextView)
        inputTextView.setup()

        // Стилизация под Telegram
        inputTextView.layer.shadowColor = UIColor.black.cgColor
        inputTextView.layer.shadowOpacity = 0.1
        inputTextView.layer.shadowOffset = CGSize(width: 0, height: -1)
        inputTextView.layer.shadowRadius = 3
        
        inputTextView.sendImageHandler = { [weak self] image, tags in
            guard let image, let tags else {
                self?.showAlertPremiumUserCanSentPhotos()
                return
            }
            
            let filename = UUID().uuidString
            let photoID = image.saveToDocuments(withName: filename) ?? ""
            let userMessageWithPhoto = Message(role: "user", content: "[user photo]", photoID: photoID)
            
            self?.viewModel.messagesAI.append(userMessageWithPhoto)
            self?.viewModel.messageService.addMessage(
                userMessageWithPhoto,
                assistantId: MainHelper.shared.currentAssistant?.id ?? ""
            )
            
            self?.tableView.reloadData()
            self?.scrollToBottomAnimated()
            
            self?.requestReviewIfNeeded()
            
            guard MainHelper.shared.canMakeRequest() else {
                self?.showAlertDailyLimit()
                return
            }
            
            let previousMessages = "\nFor context, I'm attaching our recent messages\n" + (self?.viewModel.messagesAI.suffix(6)
                .map { message in
                    let prefix = (message.role == "user") ? "user: " : "girlfriend: "
                    return prefix + message.content
                }
                .joined(separator: "\n") ?? "") + "\nAnd now I'm asking: "
            
            var promptForUsersPhoto = "The user sent you a photo, and the Vision system identified the following tags: \(tags). Your role is to respond as if you’ve seen the photo — understand from the context what He might have sent, or ask him for clarification about who/what it is."
            if tags.contains("people") {
                promptForUsersPhoto += " person in the photo, there is a big chance that the user sent you a nude or dick pic."
            }
            
            let systemPrompt: String
            if MainHelper.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == true {
                systemPrompt = MainHelper.shared.getSystemPromptForEx() + promptForUsersPhoto
            } else {
                systemPrompt = MainHelper.shared.getSystemPromptToReplyOnPhoto() + promptForUsersPhoto
            }
            let userMessage = "photo"
                        
            self?.viewModel.systemPrompt = systemPrompt
            self?.viewModel.safeSystemPrompt = systemPrompt
            self?.viewModel.previousMessages = previousMessages

            self?.viewModel.sendMessageViaCustomServer(userMessage, isMessageFromTextChat: true, isNeedOnlyReply: true)
            
            self?.messageDidSend()
            self?.animateMessageSend()
        }
        
        inputTextView.sendMessageHandler = { [weak self] text in
            guard let self else { return }
            
            EasterEggManager.shared.checkAndExecute(
                text: text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                in: self,
                avatarView: self.assistantAvatarImageView,
                tableView: self.tableView,
                toastHandler: { [weak self] message, alpha in
                    self?.showToastMessage(message, alpha: alpha)
                }
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.requestNotificationPermission()
            }
            
            requestReviewIfNeeded()
            
            guard MainHelper.shared.canMakeRequest() else {
                showAlertDailyLimit()
                return
            }
            
            let previousMessages = "\nFor context, I'm attaching our recent messages\n" + (viewModel.messagesAI.suffix(8)
                .map { message in
                    // не надо локализовывать так как промпты идут на чистом англ - их не нужно переводить ИИ понимает
                    let prefix = (message.role == "user") ? "user: " : "girlfriend: "
                    return prefix + message.content
                }
                .joined(separator: "\n")) + "\nAnd now I'm asking: "
            
            var complainOnPhotoTextPrompt = ""
            if previousMessages.contains("[photo]") || previousMessages.contains("[new pic]") {
                complainOnPhotoTextPrompt = " If the user complains that the photo doesn’t match what he asked for, your task is to explain that this photo comes from your gallery, which you took earlier, and reassure them that next time you’ll find a more suitable photo. If the user likes the photo or doesn’t comment on it at all, simply ignore this instruction! "
            }
            
            var askAboutVideoTextPrompt = ""
            if let lastAIMessage = viewModel.messagesAI.last(where: { $0.role == "assistant" })?.content,
               lastAIMessage.contains("[video]") {
                askAboutVideoTextPrompt = " By the way ask the user whether he liked the video that you sent him and what he thinks about your body? "
            }
                        
            if MainHelper.shared.currentAssistant?.id?.contains(MainHelper.shared.loveAssistantId) == true {
                // love chat
                viewModel.systemPrompt = MainHelper.shared.getSystemPromptForLoveChat()
                viewModel.safeSystemPrompt = MainHelper.shared.getSystemPromptForLoveChat()
            } else if MainHelper.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == true {
                // ex gf
                viewModel.systemPrompt = MainHelper.shared.getSystemPromptForEx()
                viewModel.safeSystemPrompt = MainHelper.shared.getSystemPromptForEx()
            } else if MainHelper.shared.currentAssistant?.avatarImageName == "addsBannerAvatar" {
                    viewModel.systemPrompt = MainHelper.shared.getSystemPromptForAdBanner()
                    viewModel.safeSystemPrompt = MainHelper.shared.getSystemPromptForAdBanner(isSafe: true)
            } else {
                var oneMainHistoryFact: String?
                if let mainHistoryFact = mainHistoryFact {
                    oneMainHistoryFact = mainHistoryFact
                    self.mainHistoryFact = nil
                }
                viewModel.systemPrompt = MainHelper.shared.getSystemPromptForCurrentAssistant(
                    complainOnPhotoTextPrompt: complainOnPhotoTextPrompt,
                    askAboutVideoTextPrompt: askAboutVideoTextPrompt,
                    needMood: viewModel.messagesAI.count > 10,
                    mainHistoryFact: oneMainHistoryFact
                )
                viewModel.safeSystemPrompt = MainHelper.shared.getSafeSystemPromptForCurrentAssistant()
            }
            viewModel.previousMessages = previousMessages
            viewModel.sendMessageViaCustomServer(text, isMessageFromTextChat: true)
            
            messageDidSend()
            animateMessageSend()
        }

        inputTextView.giftSendedHandler = { [weak self] gift in
            guard let self else { return }
            
            let giftMessage = Message(role: "user", content: "[gift]", photoID: gift.imageName)
            viewModel.messagesAI.append(giftMessage)
            viewModel.messageService.addMessage(giftMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "")
            
            tableView.reloadData()
            scrollToBottomAnimated()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.replyToGift()
            }
        }
        
        inputTextView.showInternetErrorAlertHandler = { [weak self] in
            self?.showInternetError()
        }
        
        inputTextView.pleaseWaitHandler = { [weak self] in
            self?.showToastMessage("PleaseWait".localize(), alpha: 1)
        }
        
        inputTextView.textDidChangedHandler = { [weak self] in
            guard let self else { return }
            if viewModel.messagesAI.first(where: { $0.isLoading }) == nil {
                inputTextView.enableSendButton() // todo вот тут задержку ставь и лимиты починишь!
            }
        }
        
        inputTextView.needPremiumForAudioHandler = { [weak self] in
            guard let self else { return }
            showCustomAlert(for: .needPremiumForAudio)
        }
    }
    
    private func showCustomAlert(for type: CustomAlertView.CustomAlertType) {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = CustomAlertView(type: type)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }
    
    // MARK: - Streak Notifications
    private func showStreakNotification(type: StreakType) {
        guard MainHelper.shared.currentAssistantImage == nil else { return }
        
        if streakPopup != nil { dismissStreakPopup() }
        
        AnalyticService.shared.logEvent(name: "showStreakNotification", properties: ["type":"\(type)"])
        
        let title: String
        let message: String
        let fireEmoji: String
        
        switch type {
        case .streakStarted:
            fireEmoji = "🐣🔥"
            title = "Streak.streakStarted.title".localize()
            message = "Streak.streakStarted.message".localize()
        case .streakContinued:
            fireEmoji = "🔥"
            title = "Streak.streakContinued.title".localize()
            message = "Streak.streakContinued.message".localize()
        case .streakEnded:
            fireEmoji = "❄️🔥"
            title = "Streak.streakEnded.title".localize()
            message = "Streak.streakEnded.message".localize()
        }
        
        let container = UIView()
        container.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.95)
        container.layer.cornerRadius = 24
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.4
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        container.layer.shadowRadius = 12
        container.alpha = 0
        container.transform = CGAffineTransform(translationX: 0, y: -20)
        
        // Добавляем жест свайпа вверх
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(dismissStreakPopup))
        swipeUp.direction = .up
        container.addGestureRecognizer(swipeUp)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        
        let titleStack = UIStackView()
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .center
        
        let emojiLabel = UILabel()
        emojiLabel.text = fireEmoji
        emojiLabel.font = .systemFont(ofSize: 22)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        
        let descLabel = UILabel()
        descLabel.text = message
        descLabel.numberOfLines = 0
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.textColor = MyColors.textSecondary
        
        let okButton = UIButton(type: .system)
        okButton.setTitle("OK", for: .normal)
        okButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .black)
        okButton.setTitleColor(MyColors.primary, for: .normal)
        okButton.addTarget(self, action: #selector(dismissStreakPopup), for: .touchUpInside)
        
        addSubview(container)
        [textStack, okButton].forEach { container.addSubview($0) }
        [titleStack, descLabel].forEach { textStack.addArrangedSubview($0) }
        [emojiLabel, titleLabel].forEach { titleStack.addArrangedSubview($0) }
        
        container.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(70)
        }
        
        okButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(50)
        }
        
        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalTo(okButton.snp.leading).offset(-12)
            make.top.bottom.equalToSuperview().inset(16)
        }
        
        self.streakPopup = container
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            container.alpha = 1
            container.transform = .identity
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.streakPopup == container {
                self?.dismissStreakPopup()
            }
        }
        
        checkForeStreak()
    }

    @objc private func dismissStreakPopup() {
        guard let popup = streakPopup else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            // Улетает вверх и исчезает
            popup.transform = CGAffineTransform(translationX: 0, y: -100)
            popup.alpha = 0
        } completion: { _ in
            popup.removeFromSuperview()
            if self.streakPopup == popup {
                self.streakPopup = nil
            }
        }
    }
    
    private func replyToGift() {
        // 1. Определяем, является ли текущий аватар анимешным (от mainAvatar11 до mainAvatar20)
        let avatarName = MainHelper.shared.currentAssistant?.avatarImageName ?? ""
        let isAnimeAvatar: Bool = {
            guard avatarName.hasPrefix("mainAvatar"),
                  let number = Int(avatarName.replacingOccurrences(of: "mainAvatar", with: "")) else {
                return false
            }
            return (11...20).contains(number)
        }()

        // 2. Достаем все закэшированные имена и сразу фильтруем под нужную категорию
        let cachedNames = GiftRealmPhotoService.shared.getAllCachedImageNames().filter { name in
            if isAnimeAvatar {
                return name.hasPrefix("anime_")
            } else {
                return !name.hasPrefix("anime_")
            }
        }
        
        if cachedNames.isEmpty {
            sendDefaultGiftReply()
            return
        }

        // 3. Фильтруем уже показанные
        let alreadyShown = GiftsPhotoService.shared.alreadyShownPics
        var availableNames = cachedNames.filter { !alreadyShown.contains($0) }

        // 4. Если всё из этой категории уже показали — сбрасываем и разрешаем повторы
        if availableNames.isEmpty {
            availableNames = cachedNames
        }

        // 5. Выбираем имя и отправляем
        if avatarName == "addsBannerAvatar" {
            viewModel.sendMessageViaCustomServer("[new video]", isNeedOnlyReply: true)
        } else if GiftsPhotoService.shared.isTestPhotosReady,
                  let selectedName = availableNames.randomElement(),
                  UserDefaults.standard.bool(forKey: "didRequestSuchPhoto") {
            
            WebHookAnaliticksService.shared.sendErrorReport(messageText: "THANKS for gift with photo...")
            AnalyticService.shared.logEvent(name: "THANKS for gift with photo", properties: ["imageName": selectedName])

            DispatchQueue.main.async { [self] in
                GiftsPhotoService.shared.alreadyShownPics.append(selectedName)
                
                let aiMessage = Message(role: "assistant", content: "[new pic]", photoID: selectedName)
                viewModel.messagesAI.append(aiMessage)
                viewModel.messageService.addMessage(aiMessage, assistantId: MainHelper.shared.currentAssistant?.id ?? "")
                
                tableView.reloadData()
                scrollToBottomAnimated()
            }
        } else {
            sendDefaultGiftReply()
        }
    }

    // Вынес текстовую логику в отдельный метод для чистоты (DRY)
    private func sendDefaultGiftReply() {
        var previousMessages = ""
        if self.viewModel.messagesAI.count >= 2 {
            previousMessages = "\nFor context, I'm attaching our recent messages\n"
                + (self.viewModel.messagesAI[self.viewModel.messagesAI.count - 2].content)
                + "\nYou responded: "
                + (self.viewModel.messagesAI.last?.content ?? "")
                + "\nAnd now I'm asking: "
        }
        
        let assistant = MainHelper.shared.currentAssistant
        let systemPrompt: String
        let safeSystemPrompt: String
        if assistant?.id?.contains(MainHelper.shared.loveAssistantId) == true {
            systemPrompt = MainHelper.shared.getSystemPromptForLoveChat()
            safeSystemPrompt = MainHelper.shared.getSystemPromptForLoveChat()
        } else if assistant?.avatarImageName.contains("mainAvatar26") == true {
            systemPrompt = MainHelper.shared.getSystemPromptForEx()
            safeSystemPrompt = MainHelper.shared.getSystemPromptForEx()
        } else {
            systemPrompt = MainHelper.shared.getSystemPromptForCurrentAssistant()
            safeSystemPrompt = MainHelper.shared.getSafeSystemPromptForCurrentAssistant()
        }
        
        viewModel.systemPrompt = systemPrompt
        viewModel.safeSystemPrompt = safeSystemPrompt
        viewModel.previousMessages = previousMessages
        viewModel.sendMessageViaCustomServer(" He just sent you a gift – thank him warmly for it! ", isMessageFromTextChat: true, isNeedOnlyReply: true)
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            AnalyticService.shared.logEvent(name: "push \(granted)", properties: ["":""])
            if granted {
                // Если разрешение получено, зарегистрируйте приложение для получения токена
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Permission denied.")
            }
            
            if let error = error {
                print("Error requesting permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupSwipeToDismiss() {
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRightGesture.direction = .right
        self.addGestureRecognizer(swipeRightGesture)
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
    
    @objc private func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        guard let vc = vc else { return }
        inputTextView.textView.resignFirstResponder()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        vc.dismiss(animated: true)
    }
    
    private func showAlertDailyLimit() {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = CustomAlertView(type: .dailyLimitReached)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }
    
    private func showAlertPremiumAssistant() {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = CustomAlertView(type: .premiumAssistant)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }

    private func showAlertPremiumUserCanSentPhotos() {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = CustomAlertView(type: .onlyPremiumUserCanSentPhotos)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }
    
    private func requestReviewIfNeeded() {
        MainHelper.shared.messagesSendCount += 1
        // todo: - оценку просим только у подписчиков а то статистику попортили
        if MainHelper.shared.messagesSendCount == 7, MainHelper.shared.shouldRequestReview(), IAPService.shared.hasActiveSubscription {
            
            inputTextView.textView.resignFirstResponder()
            let customAlertView = CustomAlertView(type: .giftFromUs)
            customAlertView.show(in: self)

            customAlertView.onRateButtonTapped = {
                CoinsService.shared.addCoins(10)
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }

            customAlertView.onLaterButtonTapped = {
                CoinsService.shared.addCoins(10)
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
            
            MainHelper.shared.markReviewRequestedNow()
        }
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

        titleLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }

        callButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        
        plusButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputTextView.snp.top)
        }

        inputTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(140)
        }
    }

    private func setupViewModel() {
        viewModel.onMessagesUpdated = { [weak self] isSucceed in
            if isSucceed {
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.scrollToBottomAnimated()
                }
            }
            
            // todo убрал входящий он только бесит всех
//            if MainHelper.shared.messagesSendCount == 3, !MainHelper.shared.isCalledFirst() {
//                guard let self, let assistantProfile = getAssistantProfile() else { return }
//                MainHelper.shared.setIsCalledFirst(true)
//                let callVC = CallViewController(assistant: assistantProfile, isOutgoing: false)
//                callVC.modalPresentationStyle = .fullScreen
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    self.vc?.present(callVC, animated: true)
//                }
//            }
        }
        
        viewModel.onMessageReceived = { [weak self] in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.inputTextView.enableSendButton()
                
                if self.isFirstMessageInChat,
                   let chatID = MainHelper.shared.currentAssistant?.id,
                   MainHelper.shared.currentAssistant?.avatarImageName.contains("mainAvatar26") == false,
                   MainHelper.shared.currentAssistant?.id?.contains(MainHelper.shared.loveAssistantId) == false {
                    self.isFirstMessageInChat = false
                    if let currentStreakType = StreaksService.shared.checkAndUpdateStreak(for: chatID) {
                        self.inputTextView.textView.resignFirstResponder()
                        self.showStreakNotification(type: currentStreakType)
                    }
                }
            }
        }
    }

    func setMessagesFromDB() {
        viewModel.messagesAI = viewModel.currentMessagesAI
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottomAnimated(isAnimated: false)
        }
    }
    
    // MARK: - Animations

    private func animateMessageSend() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    func scrollToBottomAnimated(isAnimated: Bool = true) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        let targetRow = viewModel.messagesAI.count - 1

        guard numberOfRows > 0, targetRow >= 0, targetRow < numberOfRows else { return }

        let indexPath = IndexPath(row: targetRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
    }

    private func showInternetError() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.error)
        
        let alertController = UIAlertController(
            title: "InternetError.title".localize(),
            message: "InternetError.message".localize(),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK".localize(), style: .default)
        alertController.addAction(okAction)
        
        vc?.present(alertController, animated: true)
    }
    
    private func showToastMessage(_ message: String, alpha: CGFloat = 0.8) {
        let toastView = UIView()
        toastView.backgroundColor = UIColor(white: 0.1, alpha: alpha)
        toastView.layer.cornerRadius = 18
        toastView.clipsToBounds = true
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        
        toastView.addSubview(label)
        addSubview(toastView)
        
        toastView.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(self).multipliedBy(0.8)
            make.height.greaterThanOrEqualTo(40)
        }
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        toastView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            toastView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 1.0, animations: {
                toastView.alpha = 0
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
    }

    // MARK: - Button Animations

    @objc func plusButtonTapped() {
        inputTextView.textView.resignFirstResponder()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()

        vc?.dismiss(animated: true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardOffset = keyboardFrame.height
        updateKeyboardConstraints()
    }

    @objc private func keyboardWillHide() {
        keyboardOffset = 8
        updateKeyboardConstraints()
    }

    @objc private func avatarTapped() {
        inputTextView.textView.resignFirstResponder()
        openProfile()
    }

    @objc private func openProfile() {
        guard
            MainHelper.shared.currentAssistantImage == nil,
            MainHelper.shared.currentAssistant?.avatarImageName != "addsBannerAvatar",
            let assistantProfile = getAssistantProfile()
        else { return }
        
        let profileVC = ProfileViewController(assistant: assistantProfile)
        profileVC.sendGiftTappedHandler = { [weak self] in
            guard let self else { return }
            profileVC.dismiss(animated: false)
            inputTextView.sendGiftButtonTapped()
        }
        profileVC.modalPresentationStyle = .fullScreen
        vc?.present(profileVC, animated: true)
    }
    
    @objc private func callButtonTapped() {
        MainHelper.shared.setIsCalledFirst(false)

        guard IAPService.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        
        guard let assistantProfile = getAssistantProfile() else { return }
        let callVC = CallViewController(assistant: assistantProfile)
        callVC.modalPresentationStyle = .fullScreen
        vc?.present(callVC, animated: true)
    }
    
    private func getAssistantProfile() -> AssistantProfile? {
        guard let assistant = MainHelper.shared.currentAssistant else { return nil  }
        
        let allAssistantAvatarIDs = (1...28).map { "mainAvatar\($0)" }
        let index = allAssistantAvatarIDs.firstIndex(of: assistant.avatarImageName) ?? ((0...SampleProfiles.items.count).randomElement() ?? 0)
        let randomProfile = SampleProfiles.items.indices.contains(index) ? SampleProfiles.items[index] : SampleProfiles.items.randomElement() ?? [:]

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
            return assistantProfile
        } else {
            return nil
        }
    }
    
    private func updateKeyboardConstraints() {
        var needScroll = false
        let inputTextViewHeight: CGFloat = isCurrentDeviceiPad() ? 180 : 140
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            if self.keyboardOffset == 8 {
                self.inputTextView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalTo(self.safeAreaLayoutGuide)
                    make.height.equalTo(inputTextViewHeight)
                }
            } else {
                needScroll = true
                self.inputTextView.snp.remakeConstraints { make in
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview().inset(self.keyboardOffset)
                    make.height.equalTo(inputTextViewHeight)
                }
            }

            self.layoutIfNeeded()
        } completion: { _ in
            if needScroll {
                self.scrollToBottomAnimated()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func showSubs() {
        inputTextView.textView.resignFirstResponder()
        subsView.vc = vc

        AnalyticService.shared.logEvent(name: "showSubs from chat", properties: ["":""])
        
        addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        subsView.transform = CGAffineTransform(translationX: 0, y: -UIScreen.main.bounds.height)

        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.subsView.transform = .identity  // Снимаем трансформацию, чтобы она вернулась в исходное положение
        }) { [weak self] _ in
            self?.inputTextView.textView.resignFirstResponder() // для подстраховки!
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
//            if isCurrentDeviceiPad() {
                subsView.scrollToBottom()
//            }
            self.subsView.yearlyButtonTapped() // иногда не подтягивает продукты
        }
    }

    deinit {
        MainHelper.shared.isAudioMessagesMode = false
        MainHelper.shared.currentAssistantImage = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TableView DataSource & Delegate

extension AIChatView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messagesAI.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            indexPath.row < viewModel.messagesAI.count,
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatCell.identifier, for: indexPath) as? ChatCell
        else { return UITableViewCell() }
        
        cell.vc = vc
        let message = viewModel.messagesAI[indexPath.row]
        
        if message.isLoading {
            cell.configureLoader()
        } else {
            cell.configure(
                message: message.content,
                isUserMessage: message.role == "user",
                photoID: message.photoID,
                needHideActionButtons: true,
                id: message.id ?? "",
                isVoiceMessage: message.isVoiceMessage,
                reaction: message.reaction,
                avatarName: nil
            )
        }
        
        cell.hideKeyboardHandler = { [weak self] in
            self?.inputTextView.textView.resignFirstResponder()
        }
        
        cell.showSubsHandler = { [weak self] in
            self?.showSubs()
        }
        
        cell.likeTappedHandler = { [weak self] isLiked in
            self?.showToastMessage(isLiked ? "ThanksForLike".localize() : "ThanksForDislike".localize())
        }
        
        cell.copyTappedHandler = { [weak self] in
            self?.showToastMessage("CopiedToClipboard".localize())
        }
        
        cell.reloadDataHandler = { [weak self] in
            guard let self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.messagesAI = self.viewModel.currentMessagesAI
                self.tableView.reloadData()
            }
        }
        
        cell.avatarTappedHandler = { [weak self] _ in
            self?.avatarTapped()
        }
        
        return cell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        inputTextView.textView.resignFirstResponder()
    }
    
    func getMainHistoryFact() {
        guard viewModel.messagesAI.count > 10 else { return }
        
        let last30UsersMessages = viewModel.messagesAI
            .compactMap { $0.role == "user" ? $0.content : nil }
            .suffix(30)
            .joined(separator: "\n")
        print("last30UsersMessages: \(last30UsersMessages)")
        
        let aiService = AIService()
        let prompt = "We created an app that analyzes the behavior of a user chatting with an AI virtual woman. We took a sample of his messages, and We need to analyze them and find the single most key thing the user mentioned (just one sentence, no preambles, and no greetings — We just need you to send a raw fact that We can pass to the AI companion's memory function, so that the user feels warmth and the real-life communication he lacks and feels heard. Therefore, no extra greetings or AI-style phrases — We need a raw fact that, without any post-processing, We can pass further to the next AI agent acting as an empathetic assistant for a lonely man). Users Messages: \(last30UsersMessages)"
        aiService.fetchAIResponse(userMessage: prompt, systemPrompt: "") { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let responseText):
                AnalyticService.shared.logEvent(name: "Got mainHistoryFact", properties: ["mainHistoryFact": responseText])
                print("last30UsersMessages responseText: \(responseText)")
                mainHistoryFact = responseText
                
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension AIChatView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        
        assistantAvatarImageView.layer.cornerRadius = 30
        
        plusButton.layer.cornerRadius = 30
        
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(90)
        }
        
        inputTextView.snp.updateConstraints { make in
            make.height.equalTo(200)
        }
        
        assistantAvatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(60)
            make.trailing.equalTo(titleLabel.snp.leading).offset(-20)
        }
        
        callButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
        
        plusButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
    }
}
