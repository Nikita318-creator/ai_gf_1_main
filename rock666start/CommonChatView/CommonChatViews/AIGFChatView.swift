import UIKit
import SnapKit
import StoreKit

class AIGFChatView: UIView {
    
    // MARK: - Views & Controls
    
    private let navigationBar = AIGFChatNavigationBar()
    private let tableView = UITableView()
    let inputTextView = AIGFChatBottomInputView()
    let subsView = PaywallView()
    
    private let backgroundImageView = UIImageView()
    private let backgroundOverlayView = UIView()
    private let gradientLayer = CAGradientLayer()
    private var streakPopup: UIView?
    private var keyboardOffset: CGFloat = 0
    
    weak var vc: UIViewController?
    let viewModel = AIGFChatViewModel()

    // MARK: - Legacy Bridge Accessors (Чтобы ничего не отвалилось в зависимостях)
    
    var callButton: UIButton { get { navigationBar.callButton } }
    var plusButton: UIButton { get { navigationBar.backButton } }
    var repository: CommonChatRepository { get { viewModel.repository } }

    // MARK: - Setup
    
    func setup() {
        setupObservers()
        setupBackground()
        setupNavigationBar()
        setupTableView()
        setupInputView()
        setupConstraints()
        setupViewModelBindings()
        
        viewModel.loadMessages()
        viewModel.checkForeStreak()
        setupNavTitleAndAvatar()
        setupSwipeToDismiss()
        updateTextForIPadIfNeeded()
        
        if BaseManager.shared.currentAssistant?.avatarImageName.contains("swipeModeAvatar") == true {
            inputTextView.hideVideoPrompt()
            inputTextView.hidePhotoPrompt()
        }
        
        if let name = BaseManager.shared.currentAssistant?.avatarImageName, (21...26).map({ "mainAvatar\($0)" }).contains(name) {
            inputTextView.hideVideoPrompt()
            if !BackendService.shared.currentData.isABTestRandom {
                inputTextView.hidePhotoPrompt()
            }
        }
        
        if let name = BaseManager.shared.currentAssistant?.avatarImageName, name.contains("waifuInOutfit_") {
            inputTextView.hidePhotoPrompt()
        }
    }

    private func setupViewModelBindings() {
        viewModel.onMessagesUpdated = { [weak self] isSucceed in
            if isSucceed {
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.scrollToBottomAnimated()
                }
            }
        }
        
        viewModel.onMessageReceived = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.inputTextView.enableSendButton()
            }
        }
        
        viewModel.onShowStreakNotification = { [weak self] type in
            DispatchQueue.main.async {
                self?.inputTextView.textView.resignFirstResponder()
                self?.showStreakNotification(type: type)
            }
        }
        
        viewModel.onShowAlert = { [weak self] popupType in
            DispatchQueue.main.async {
                self?.showCustomPopupAlert(type: popupType)
            }
        }
        
        viewModel.onShowToast = { [weak self] message in
            DispatchQueue.main.async {
                self?.showToastMessage(message)
            }
        }
    }

    private func setupNavigationBar() {
        addSubview(navigationBar)
        
        navigationBar.onBackTapped = { [weak self] in
            self?.plusButtonTapped()
        }
        
        navigationBar.onCallTapped = { [weak self] in
            self?.callButtonTapped()
        }
        
        navigationBar.onAvatarTapped = { [weak self] in
            self?.avatarTapped()
        }
        
        navigationBar.onProfileTapped = { [weak self] in
            self?.openProfile()
        }
        
        navigationBar.onStreakTapped = { [weak self] in
            self?.streakTapped()
        }
    }

    func setupNavTitleAndAvatar() {
        navigationBar.configure(
            title: BaseManager.shared.currentAssistant?.assistantName,
            avatarImage: viewModel.getAvatarImage(),
            streakCount: viewModel.streakCount,
            hideStreak: viewModel.shouldHideStreak()
        )
        
        backgroundImageView.image = viewModel.getAvatarImage()
    }

    private func setupBackground() {
        backgroundColor = MyColors.background

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        backgroundOverlayView.backgroundColor = MyColors.background.withAlphaComponent(0.6)
        addSubview(backgroundOverlayView)

        gradientLayer.colors = [
            MyColors.background.cgColor,
            MyColors.gradientEnd.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
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
        tableView.register(AIGFChatCell.self, forCellReuseIdentifier: AIGFChatCell.identifier)
        tableView.register(AIGFTextChatCell.self, forCellReuseIdentifier: "AIGFTextChatCell")
        tableView.register(AIGFMediaChatCell.self, forCellReuseIdentifier: "AIGFMediaChatCell")
        tableView.register(AIGFVoiceChatCell.self, forCellReuseIdentifier: "AIGFVoiceChatCell")
        tableView.register(AIGFLoaderChatCell.self, forCellReuseIdentifier: "AIGFLoaderChatCell")
        
        addSubview(tableView)
    }

    private func setupInputView() {
        inputTextView.vc = vc
        addSubview(inputTextView)
        inputTextView.setup()

        inputTextView.layer.shadowColor = MyColors.background.cgColor
        inputTextView.layer.shadowOpacity = 0.1
        inputTextView.layer.shadowOffset = CGSize(width: 0, height: -1)
        inputTextView.layer.shadowRadius = 3
        
        inputTextView.sendMessageHandler = { [weak self] text in
            guard let self = self else { return }
            self.viewModel.handleSendMessage(
                text: text,
                containerView: self,
                avatarView: self.navigationBar.avatarImageView,
                tableView: self.tableView
            )
            self.animateMessageSend()
        }

        inputTextView.giftSendedHandler = { [weak self] gift in
            guard let self = self else { return }
            self.viewModel.handleSendGift(gift)
        }
        
        inputTextView.showInternetErrorAlertHandler = { [weak self] in
            self?.showInternetError()
        }
        
        inputTextView.pleaseWaitHandler = { [weak self] in
            self?.showToastMessage("PleaseWait".localize(), alpha: 1)
        }
        
        inputTextView.textDidChangedHandler = { [weak self] in
            guard let self = self else { return }
            if self.repository.messagesAI.first(where: { $0.isLoading }) == nil {
                self.inputTextView.enableSendButton()
            }
        }
        
        inputTextView.needPremiumForAudioHandler = { [weak self] in
            self?.showCustomAlert(for: .needPremiumForAudio)
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

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputTextView.snp.top)
        }

        inputTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(60)
        }
    }

    // MARK: - User Action Handlers & Alerts
    
    private func streakTapped() {
        inputTextView.textView.resignFirstResponder()
        showStreakPopup()
    }

    private func showCustomAlert(for type: BasePopupView.BasePopupType) {
        showCustomPopupAlert(type: type)
    }

    private func showCustomPopupAlert(type: BasePopupView.BasePopupType) {
        inputTextView.textView.resignFirstResponder()
        let customAlertView = BasePopupView(type: type)
        customAlertView.show(in: self)

        customAlertView.onRateButtonTapped = { [weak self] in
            if type == .giftFromUs {
                CoinsService.shared.addCoins(10)
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            } else {
                self?.showSubs()
            }
        }

        customAlertView.onLaterButtonTapped = { [weak self] in
            if type == .giftFromUs {
                CoinsService.shared.addCoins(10)
                DispatchQueue.main.async {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            } else {
                self?.showSubs()
            }
        }
    }

    private func showStreakPopup() {
        if streakPopup != nil { return }
        
        let overlay = UIView()
        overlay.backgroundColor = MyColors.background.withAlphaComponent(0.8)
        overlay.alpha = 0
        
        let container = UIView()
        container.backgroundColor = MyColors.cardBackground
        container.layer.cornerRadius = 24
        container.layer.borderWidth = 1
        container.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        container.clipsToBounds = true
        
        let fireLabel = UILabel()
        fireLabel.text = "🔥"
        fireLabel.font = UIFont.systemFont(ofSize: 60)
        fireLabel.textAlignment = .center
        
        let infoLabel = UILabel()
        infoLabel.text = "Streak.infoLabelText".localize() + " \(viewModel.streakCount)"
        infoLabel.numberOfLines = 0
        infoLabel.textColor = MyColors.textPrimary
        infoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        infoLabel.textAlignment = .center
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Streak.GotIt".localize(), for: .normal)
        closeButton.setTitleColor(MyColors.textPrimary, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        closeButton.backgroundColor = MyColors.primary
        closeButton.layer.cornerRadius = 14
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
        
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
        }
    }

    private func showStreakNotification(type: FlameType) {
        guard BaseManager.shared.notFriendProfileAvatar == nil else { return }
        
        if streakPopup != nil { dismissStreakPopup() }
                
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
        container.layer.borderWidth = 1
        container.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        container.layer.shadowColor = MyColors.background.cgColor
        container.layer.shadowOpacity = 0.4
        container.layer.shadowOffset = CGSize(width: 0, height: 6)
        container.layer.shadowRadius = 12
        container.alpha = 0
        container.transform = CGAffineTransform(translationX: 0, y: -20)
        
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
        titleLabel.textColor = MyColors.textPrimary
        
        let descLabel = UILabel()
        descLabel.text = message
        descLabel.numberOfLines = 0
        descLabel.font = .systemFont(ofSize: 16)
        descLabel.textColor = MyColors.textSecondary
        
        let okButton = UIButton(type: .system)
        okButton.setTitle("OK", for: .normal)
        okButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
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
        
        viewModel.checkForeStreak()
        setupNavTitleAndAvatar()
    }

    @objc private func dismissStreakPopup() {
        guard let popup = streakPopup else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            popup.transform = CGAffineTransform(translationX: 0, y: -100)
            popup.alpha = 0
        } completion: { _ in
            popup.removeFromSuperview()
            if self.streakPopup == popup {
                self.streakPopup = nil
            }
        }
    }

    func updateForRLTIfNeeded() {
        inputTextView.updateForRLTIfNeeded()
    }
    
    func setMessagesFromDB() {
        viewModel.loadMessages()
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.scrollToBottomAnimated(isAnimated: false)
        }
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

    private func setupSwipeToDismiss() {
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeRightGesture.direction = .right
        self.addGestureRecognizer(swipeRightGesture)
    }

    @objc private func handleSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        guard let vc = vc else { return }
        inputTextView.textView.resignFirstResponder()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        vc.dismiss(animated: true)
    }

    private func animateMessageSend() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    func scrollToBottomAnimated(isAnimated: Bool = true) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        let targetRow = repository.messagesAI.count - 1

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
        toastView.backgroundColor = MyColors.messageBackground.withAlphaComponent(alpha)
        toastView.layer.cornerRadius = 18
        toastView.layer.borderWidth = 1
        toastView.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        toastView.clipsToBounds = true
        
        let label = UILabel()
        label.text = message
        label.textColor = MyColors.textPrimary
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
            UIView.animate(withDuration: 0.5, delay: 2.0, animations: {
                toastView.alpha = 0
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
    }

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
            BaseManager.shared.notFriendProfileAvatar == nil,
            let assistantProfile = viewModel.getAssistantProfile()
        else { return }
        
        let profileVC = AIProfileVC(assistant: assistantProfile)
        profileVC.sendGiftTappedHandler = { [weak self] in
            guard let self = self else { return }
            profileVC.dismiss(animated: false)
        }
        profileVC.modalPresentationStyle = .fullScreen
        vc?.present(profileVC, animated: true)
    }
    
    @objc func callButtonTapped() {
        guard SubscriptionManager.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        
       //test111
    }

    private func updateKeyboardConstraints() {
        var needScroll = false
        let inputTextViewHeight: CGFloat = isNeedBigTextForIPad() ? 70 : 60
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
    }

    deinit {
        BaseManager.shared.isAudioMessagesMode = false
        BaseManager.shared.notFriendProfileAvatar = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TableView DataSource & Delegate

extension AIGFChatView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repository.messagesAI.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < repository.messagesAI.count else {
            return UITableViewCell()
        }
        
        let message = repository.messagesAI[indexPath.row]
        let messageID = message.id ?? ""
        let isUser = message.role == "user"

        func setupCommonHandlers(for cell: AIGFChatCell) {
            cell.vc = self.vc
            
            cell.hideKeyboardHandler = { [weak self] in
                self?.inputTextView.textView.resignFirstResponder()
            }
            
            cell.showSubsHandler = { [weak self] in
                self?.showSubs()
            }
            
            cell.reloadDataHandler = { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.viewModel.loadMessages()
                    self.tableView.reloadData()
                }
            }
            
            cell.avatarTappedHandler = { [weak self] _ in
                self?.avatarTapped()
            }
        }

        if message.isLoading {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIGFLoaderChatCell", for: indexPath) as? AIGFLoaderChatCell else {
                return UITableViewCell()
            }
            setupCommonHandlers(for: cell)
            cell.configureLoader(avatarName: nil)
            return cell
        }

        if message.isVoiceMessage && !isUser {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIGFVoiceChatCell", for: indexPath) as? AIGFVoiceChatCell else {
                return UITableViewCell()
            }
            setupCommonHandlers(for: cell)
            cell.configure(
                message: message.content,
                isUserMessage: isUser,
                id: messageID,
                reaction: message.reaction,
                avatarName: nil
            )
            return cell
        }

        if !message.photoID.isEmpty {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIGFMediaChatCell", for: indexPath) as? AIGFMediaChatCell else {
                return UITableViewCell()
            }
            setupCommonHandlers(for: cell)
            cell.configure(
                message: message.content,
                isUserMessage: isUser,
                photoID: message.photoID,
                id: messageID,
                reaction: message.reaction,
                avatarName: nil
            )
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIGFTextChatCell", for: indexPath) as? AIGFTextChatCell else {
            return UITableViewCell()
        }
        setupCommonHandlers(for: cell)
        
        cell.likeTappedHandler = { [weak self] isLiked in
            self?.showToastMessage(isLiked ? "ThanksForLike".localize() : "ThanksForDislike".localize())
        }
        
        cell.copyTappedHandler = { [weak self] in
            self?.showToastMessage("CopiedToClipboard".localize())
        }
        
        cell.configure(
            message: message.content,
            isUserMessage: isUser,
            needHideActionButtons: true,
            id: messageID,
            reaction: message.reaction,
            avatarName: nil
        )
        
        return cell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        inputTextView.textView.resignFirstResponder()
    }
}

extension AIGFChatView {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }
        
        navigationBar.updateForIPad()
        
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(90)
        }
        
        inputTextView.snp.updateConstraints { make in
            make.height.equalTo(70)
        }
    }
}
