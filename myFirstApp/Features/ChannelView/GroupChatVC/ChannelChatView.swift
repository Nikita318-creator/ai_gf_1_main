import UIKit
import SnapKit

class ChannelChatView: UIView {
    
    // MARK: - UI Elements
    private let navigationBar = UIView()
    private let navBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let clearChatHistoryButton = UIButton(type: .system)
    private let assistantAvatarImageView = UIImageView()
    
    private let tableView = UITableView()
    let inputTextView = AIGFChatBottomInputView()
    let subsView = PaywallView()

    // MARK: - Dependencies & State
    weak var vc: UIViewController?
    let viewModel = AIGFChatViewModel()
    
    private let backgroundImageView = UIImageView()
    private let backgroundOverlayView = UIView()
    private let gradientLayer = CAGradientLayer()

    private var keyboardOffset: CGFloat = 8
    var isMessageOnRepite = false
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Lifecycle
    func setup() {
        setupObservers()
        setupBackground()
        setupBaseUI()
        setupNavigationBar()
        setupTableView()
        setupInputView()
        setupConstraints()
        setupViewModel()
        setupSwipeToDismiss()
        
        setMessagesFromDB()
    }

    // MARK: - UI & Subviews Setup
    private func setupBaseUI() {
        backgroundColor = MyColors.background
    }

    private func setupBackground() {
        backgroundColor = MyColors.background
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)
        
        backgroundOverlayView.backgroundColor = MyColors.pureBlack.withAlphaComponent(0.4)
        addSubview(backgroundOverlayView)
        
        gradientLayer.colors = [
            MyColors.gradientStart.cgColor,
            MyColors.gradientEnd.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        guard let avatarName = BaseManager.shared.currentAssistant?.avatarImageName else { return }
        backgroundImageView.image = UIImage(named: avatarName)
    }
    
    private func setupNavigationBar() {
        navigationBar.backgroundColor = .clear
        addSubview(navigationBar)

        navigationBar.addSubview(navBlurView)
        navBlurView.snp.makeConstraints { $0.edges.equalToSuperview() }

        navigationBar.isUserInteractionEnabled = true
        let headerTap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        navigationBar.addGestureRecognizer(headerTap)

        // Кнопка Назад
        let buttonPointSize: CGFloat = isCurrentDeviceiPad() ? 28 : 20
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        ), for: .normal)
        backButton.tintColor = MyColors.primary
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationBar.addSubview(backButton)

        // Аватарка чата (Возвращена и стилизована под ТГ)
        let avatarSize: CGFloat = isCurrentDeviceiPad() ? 44 : 36
        assistantAvatarImageView.contentMode = .scaleAspectFill
        assistantAvatarImageView.layer.cornerRadius = avatarSize / 2
        assistantAvatarImageView.clipsToBounds = true
        assistantAvatarImageView.backgroundColor = MyColors.cardBackground
        assistantAvatarImageView.image = UIImage(named: BaseManager.shared.currentAssistant?.avatarImageName ?? "")
        assistantAvatarImageView.isUserInteractionEnabled = true
        assistantAvatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarHeaderTapped)))
        navigationBar.addSubview(assistantAvatarImageView)

        // Название чата
        titleLabel.text = BaseManager.shared.currentAssistant?.assistantName ?? ""
        titleLabel.textAlignment = .left
        titleLabel.font = isCurrentDeviceiPad() ? .systemFont(ofSize: 22, weight: .semibold) : .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = MyColors.textPrimary
        navigationBar.addSubview(titleLabel)

        // Кнопка Очистить историю
        let trashPointSize: CGFloat = isCurrentDeviceiPad() ? 24 : 18
        clearChatHistoryButton.setImage(UIImage(systemName: "trash.slash")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: trashPointSize, weight: .medium)
        ), for: .normal)
        clearChatHistoryButton.tintColor = MyColors.primary
        clearChatHistoryButton.addTarget(self, action: #selector(clearChatHistoryButtonTapped), for: .touchUpInside)
        navigationBar.addSubview(clearChatHistoryButton)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(AIGFChatCell.self, forCellReuseIdentifier: AIGFChatCell.identifier)
        addSubview(tableView)
    }

    private func setupInputView() {
        inputTextView.vc = vc
        addSubview(inputTextView)
        inputTextView.setup()
        
        inputTextView.sendMessageHandler = { [weak self] text in
            guard let self else { return }

            guard BaseManager.shared.canMakeRequest() else {
                showCustomAlert(for: .dailyLimitReached)
                return
            }
            
            isMessageOnRepite = false
            let groups = BaseManager.shared.allWaifuGroups
            if let index = BaseManager.shared.currentWaifuIndex, index < groups.count {
                BaseManager.shared.currentWaifuNameFromeGroupeChat = groups[index].filter({$0.avatarName != BaseManager.shared.currentWaifuNameFromeGroupeChat?.avatarName}).randomElement()
            }
            
            let previousMessages = "promp.previosMessagesUser".localize() + (viewModel.messagesAI.suffix(12)
                .map { message in
                    let prefix = (message.role == "user") ? "user: " : "girlfriend: "
                    return prefix + message.content
                }
                .joined(separator: "\n")) + "promp.previosMessagesUserStarter".localize()
            let systemPrompt = BaseManager.shared.getSystemPromptForGroupChat()
            viewModel.systemPrompt = systemPrompt
            viewModel.safeSystemPrompt = systemPrompt
            viewModel.previousMessages = previousMessages

            self.viewModel.sendMessageViaCustomServer(text)
            self.scrollToBottomAnimated()
        }

        inputTextView.sendImageHandler = { [weak self] image, tags in
            guard let image, let tags else {
                self?.showCustomAlert(for: .onlyPremiumUserCanSentPhotos)
                return
            }
            
            let filename = UUID().uuidString
            let photoID = image.saveToDocuments(withName: filename) ?? ""
            let userMessageWithPhoto = AIGFMessageModel(role: "user", content: "[user photo]", photoID: photoID)
            
            self?.viewModel.messagesAI.append(userMessageWithPhoto)
            self?.viewModel.messageService.addMessage(
                userMessageWithPhoto,
                assistantId: BaseManager.shared.currentAssistant?.id ?? ""
            )
            
            self?.tableView.reloadData()
            self?.scrollToBottomAnimated()
                        
            guard BaseManager.shared.canMakeRequest() else {
                self?.showCustomAlert(for: .dailyLimitReached)
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
            
            let systemPrompt = BaseManager.shared.getSystemPromptToReplyOnPhoto() + promptForUsersPhoto
            let userMessage = "photo"
                        
            self?.viewModel.systemPrompt = systemPrompt
            self?.viewModel.safeSystemPrompt = systemPrompt
            self?.viewModel.previousMessages = previousMessages

            self?.viewModel.sendMessageViaCustomServer(userMessage, isMessageFromTextChat: true, isNeedOnlyReply: true)
            self?.scrollToBottomAnimated()
        }
        
        inputTextView.giftSendedHandler = { [weak self] gift in
            guard let self else { return }
            
            let giftMessage = AIGFMessageModel(role: "user", content: "[gift]", photoID: gift.imageName)
            viewModel.messagesAI.append(giftMessage)
            viewModel.messageService.addMessage(giftMessage, assistantId: BaseManager.shared.currentAssistant?.id ?? "")
            
            tableView.reloadData()
            scrollToBottomAnimated()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.replyToGift()
            }
        }
        
        inputTextView.textDidChangedHandler = { [weak self] in
            guard let self else { return }
            if self.viewModel.messagesAI.first(where: { $0.isLoading }) == nil {
                self.inputTextView.enableSendButton()
            }
        }
        
        inputTextView.showInternetErrorAlertHandler = { [weak self] in
            self?.showInternetError()
        }
        
        inputTextView.pleaseWaitHandler = { [weak self] in
            self?.showToastMessage("PleaseWait".localize(), alpha: 1)
        }
    }
    
    private func setupViewModel() {
        viewModel.onMessagesUpdated = { [weak self] isSucceed in
            guard let self else { return }
            
            if isSucceed {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottomAnimated()
                }
            }
        }
        
        viewModel.onMessageReceived = { [weak self] in
            guard let self else { return }

            inputTextView.enableSendButton()
            
            if [false, true, false].randomElement() ?? false, !isMessageOnRepite {
                isMessageOnRepite = true
                inputTextView.canSendMessage = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.receiveNextMessage()
                }
            }
        }
    }

    func receiveNextMessage() {
        let groups = BaseManager.shared.allWaifuGroups
        if let index = BaseManager.shared.currentWaifuIndex, index < groups.count {
            BaseManager.shared.currentWaifuNameFromeGroupeChat = groups[index].filter({$0.avatarName != BaseManager.shared.currentWaifuNameFromeGroupeChat?.avatarName}).randomElement()
        }
        
        let previousMessages = "promp.previosMessagesUser".localize() + (viewModel.messagesAI.suffix(12)
            .map { message in
                let prefix = (message.role == "user") ? "user: " : "girlfriend: "
                return prefix + message.content
            }
            .joined(separator: "\n"))
        let systemPrompt = BaseManager.shared.getSystemPromptForGroupChat()
        viewModel.previousMessages = previousMessages
        viewModel.systemPrompt = systemPrompt
        viewModel.safeSystemPrompt = systemPrompt

        self.viewModel.sendMessageViaCustomServer(" ", isNeedOnlyReply: true)
        self.scrollToBottomAnimated()
    }
    
    func setMessagesFromDB() {
        viewModel.messagesAI = viewModel.currentMessagesAI
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottomAnimated(isAnimated: false)
        }
    }

    // MARK: - Layout & Constraints
    private func setupConstraints() {
        let navBarHeight = isCurrentDeviceiPad() ? 100 : 92 // Нативный размер с учетом челки
        let buttonSize = isCurrentDeviceiPad() ? 50 : 40
        let avatarSize = isCurrentDeviceiPad() ? 44 : 36

        // Навигация перекрывает верх (status bar)
        navigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.top).offset(isCurrentDeviceiPad() ? 64 : 54)
        }

        // Элементы жмутся к низу навигационного бара (чтобы не заезжать на челку)
        backButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(8)
            make.width.height.equalTo(buttonSize)
        }

        assistantAvatarImageView.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.leading.equalTo(backButton.snp.trailing).offset(4)
            make.width.height.equalTo(avatarSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(assistantAvatarImageView)
            make.leading.equalTo(assistantAvatarImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(clearChatHistoryButton.snp.leading).offset(-8)
        }

        clearChatHistoryButton.snp.makeConstraints { make in
            make.width.height.equalTo(buttonSize)
            make.centerY.equalTo(backButton)
            make.trailing.equalToSuperview().inset(12)
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

    // MARK: - Keyboard Management
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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
        } completion: { [weak self] _ in
            if needScroll {
                self?.scrollToBottomAnimated()
            }
        }
    }

    @objc private func avatarTapped(_ avatarName: String?) {
        inputTextView.textView.resignFirstResponder()

        if let vc {
            let avatarImage: UIImage?
            if let avatarName {
                avatarImage = (UIImage(named: APIManager.shared.isRemotePhoto ? (avatarName + "_") : avatarName)) ?? UIImage(named: avatarName)
            } else {
                avatarImage = UIImage(named: BaseManager.shared.currentAssistant?.avatarImageName ?? "")
            }
            
            let fullScreenView = PreviewImageView(image: avatarImage)
            fullScreenView.vc = vc
            fullScreenView.show(in: vc.view)
        }
    }
    
    // MARK: - Actions & Helpers
    func scrollToBottomAnimated(isAnimated: Bool = true) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        let targetRow = viewModel.messagesAI.count - 1
        guard numberOfRows > 0, targetRow >= 0, targetRow < numberOfRows else { return }
        
        let indexPath = IndexPath(row: targetRow, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
    }

    @objc func backButtonTapped() {
        inputTextView.textView.resignFirstResponder()
        vc?.dismiss(animated: true)
    }

    private func setupSwipeToDismiss() {
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRightGesture.direction = .right
        self.addGestureRecognizer(swipeRightGesture)
    }

    @objc private func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        backButtonTapped()
    }

    @objc private func clearChatHistoryButtonTapped() {
        inputTextView.textView.resignFirstResponder()
        
        let alertController = UIAlertController(
            title: "DeleteChatHistoryTitle".localize(),
            message: "DeleteChatHistoryMessage".localize(),
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete".localize(), style: .destructive) { [weak self] _ in
            let assistantId = BaseManager.shared.currentAssistant?.id ?? ""
            AIGirlfriendMessagesManager().getAllMessages(forAssistantId: assistantId).forEach {
                AIGirlfriendMessagesManager().deleteMessage(id: $0.id ?? "")
            }
            self?.viewModel.messagesAI = []
            self?.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        vc?.present(alertController, animated: true, completion: nil)
    }

    @objc private func headerTapped() {
        inputTextView.textView.resignFirstResponder()
        
        let groups = BaseManager.shared.allWaifuGroups
        guard let index = BaseManager.shared.currentWaifuIndex, index < groups.count else { return }
        let currentGroupMembers = groups[index]
        
        let membersVC = GroupsParticipientsVC(members: currentGroupMembers)
        
        if let sheet = membersVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        vc?.present(membersVC, animated: true)
    }
    
    @objc private func avatarHeaderTapped(_ gesture: UITapGestureRecognizer) {
        avatarTapped(nil)
    }
    
    private func showCustomAlert(for type: BasePopupView.BasePopupType) {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = BasePopupView(type: type)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            self?.showSubs()
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            self?.showSubs()
        }
    }
    
    private func showSubs() {
        inputTextView.textView.resignFirstResponder()
        subsView.vc = vc

        AmplitudeManager.shared.logEvent(name: "showSubs from chat", properties: ["":""])
        
        addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        subsView.transform = CGAffineTransform(translationX: 0, y: -UIScreen.main.bounds.height)

        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.subsView.transform = .identity
        }) { [weak self] _ in
            self?.inputTextView.textView.resignFirstResponder()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            self.subsView.yearlyButtonTapped()
        }
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
    
    private func replyToGift() {
        let avatarName = BaseManager.shared.currentAssistant?.avatarImageName ?? ""
        let isAnimeAvatar: Bool = true

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

        let alreadyShown = GiftsPhotoService.shared.alreadyShownPics
        var availableNames = cachedNames.filter { !alreadyShown.contains($0) }

        if availableNames.isEmpty {
            availableNames = cachedNames
        }

        if avatarName == "addsBannerAvatar" {
            viewModel.sendMessageViaCustomServer("[new video]", isNeedOnlyReply: true)
        } else if GiftsPhotoService.shared.isTestPhotosReady,
                  let selectedName = availableNames.randomElement(),
                  UserDefaults.standard.bool(forKey: "didRequestSuchPhoto") {
            
            TGReportsManager.shared.sendErrorReport(messageText: "THANKS for gift with photo...")
            AmplitudeManager.shared.logEvent(name: "THANKS for gift with photo", properties: ["imageName": selectedName])

            DispatchQueue.main.async { [self] in
                GiftsPhotoService.shared.alreadyShownPics.append(selectedName)
                
                let aiMessage = AIGFMessageModel(role: "assistant", content: "[new pic]", photoID: selectedName)
                viewModel.messagesAI.append(aiMessage)
                viewModel.messageService.addMessage(aiMessage, assistantId: BaseManager.shared.currentAssistant?.id ?? "")
                
                tableView.reloadData()
                scrollToBottomAnimated()
            }
        } else {
            sendDefaultGiftReply()
        }
    }

    private func sendDefaultGiftReply() {
        var previousMessages = ""
        if self.viewModel.messagesAI.count >= 2 {
            previousMessages = "\nFor context, I'm attaching our recent messages\n"
                + (self.viewModel.messagesAI[self.viewModel.messagesAI.count - 2].content)
                + "\nYou responded: "
                + (self.viewModel.messagesAI.last?.content ?? "")
                + "\nAnd now I'm asking: "
        }
        
        let assistant = BaseManager.shared.currentAssistant
        let systemPrompt: String
        let safeSystemPrompt: String
        if assistant?.id?.contains(BaseManager.shared.loveAssistantId) == true {
            systemPrompt = BaseManager.shared.getSystemPromptForLoveChat()
            safeSystemPrompt = BaseManager.shared.getSystemPromptForLoveChat()
        } else if assistant?.avatarImageName.contains("mainAvatar26") == true {
            systemPrompt = BaseManager.shared.getSystemPromptForEx()
            safeSystemPrompt = BaseManager.shared.getSystemPromptForEx()
        } else {
            systemPrompt = BaseManager.shared.getSystemPromptForCurrentAssistant()
            safeSystemPrompt = BaseManager.shared.getSafeSystemPromptForCurrentAssistant()
        }
        
        viewModel.systemPrompt = systemPrompt
        viewModel.safeSystemPrompt = safeSystemPrompt
        viewModel.previousMessages = previousMessages
        viewModel.sendMessageViaCustomServer(" He just sent you a gift – thank him warmly for it! ", isMessageFromTextChat: true, isNeedOnlyReply: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        BaseManager.shared.currentWaifuNameFromeGroupeChat = nil
        BaseManager.shared.isAudioMessagesMode = false
        BaseManager.shared.currentAssistantImage = nil
    }
}

// MARK: - TableView DataSource & Delegate
extension ChannelChatView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messagesAI.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.messagesAI.count,
              let cell = tableView.dequeueReusableCell(withIdentifier: AIGFChatCell.identifier, for: indexPath) as? AIGFChatCell
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
                avatarName: message.avatarName
            )
        }

        cell.hideKeyboardHandler = { [weak self] in
            self?.inputTextView.textView.resignFirstResponder()
        }
        
        cell.avatarTappedHandler = { [weak self] avatar in
            self?.avatarTapped(avatar)
        }
        
        cell.showSubsHandler = { [weak self] in
            self?.showSubs()
        }
        
        cell.reloadDataHandler = { [weak self] in
            guard let self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.messagesAI = self.viewModel.currentMessagesAI
                self.tableView.reloadData()
            }
        }
        
        return cell
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        inputTextView.textView.resignFirstResponder()
    }
}
