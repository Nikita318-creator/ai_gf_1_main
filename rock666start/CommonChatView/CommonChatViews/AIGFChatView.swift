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
        setupNavTitleAndAvatar()
        setupSwipeToDismiss()
        updateTextForIPadIfNeeded()
        
        if MyGovnoSingltone.shared.currentAssistant?.avatarImageName.contains("swipeModeAvatar") == true {
            inputTextView.hideVideoPrompt()
            inputTextView.hidePhotoPrompt()
        }
        
        if let name = MyGovnoSingltone.shared.currentAssistant?.avatarImageName, (21...26).map({ "mainAvatar\($0)" }).contains(name) {
            inputTextView.hideVideoPrompt()
            if BackendService.shared.currentData.userPromptMain.isEmpty {
                inputTextView.hidePhotoPrompt()
            }
        }
        
        if let name = MyGovnoSingltone.shared.currentAssistant?.avatarImageName, name.contains("waifuInOutfit_") {
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
            if !BackendService.shared.currentData.userPromptMain.isEmpty {
                self?.avatarTapped()
            }
        }
        
        navigationBar.onProfileTapped = { [weak self] in
            if !BackendService.shared.currentData.userPromptMain.isEmpty {
                self?.avatarTapped()
            }
        }
    }

    func setupNavTitleAndAvatar() {
        navigationBar.configure(
            title: MyGovnoSingltone.shared.currentAssistant?.assistantName,
            avatarImage: viewModel.getAvatarImage()
        )
        
        if !BackendService.shared.currentData.userPromptMain.isEmpty {
            backgroundImageView.image = viewModel.getAvatarImage()
        } else {
            backgroundImageView.image = UIImage.gradientImage(
                colors: [MyColors.gradientStart, MyColors.gradientEnd],
                size: bounds.size.equalTo(.zero) ? CGSize(width: 300, height: 600) : bounds.size
            )
        }
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
        
        inputTextView.showInternetErrorAlertHandler = { [weak self] in
            self?.showInternetError()
        }
        
        inputTextView.pleaseWaitHandler = { [weak self] in
            self?.showToastMessage("Oh, sweetie, you're typing so fast! I can't catch my breath. Give me just a second to catch up? 💕", alpha: 1)
        }
        
        inputTextView.textDidChangedHandler = { [weak self] in
            guard let self = self else { return }
            if self.repository.messagesAI.first(where: { $0.isLoading }) == nil {
                self.inputTextView.enableSendButton()
            }
        }
        
        inputTextView.needPremiumForAudioHandler = { [weak self] in
            self?.showCustomPopupAlert(type: .needPremiumForAudio)
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

    private func showCustomPopupAlert(type: BasePopupView.BasePopupType) {
        let popup = BasePopupView(type: type, onOk: ({ [weak self] in
            self?.showSubs()
        }))
        inputTextView.textView.resignFirstResponder()
        popup.show(on: self)
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
            title: "No Internet Connection",
            message: "Please check your network settings and try again.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default)
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
        
        guard let vc else { return }
        let fullScreenView = PreviewImageView(image: viewModel.getAvatarImage())
        fullScreenView.vc = vc
        fullScreenView.show(in: vc.view)
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
        let inputTextViewHeight: CGFloat = isIPad() ? 70 : 60
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
        MyGovnoSingltone.shared.isAudioMessagesMode = false
        MyGovnoSingltone.shared.notFriendProfileAvatar = nil
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
            
            cell.avatarTappedHandler = { [weak self] in
                self?.avatarTapped()
            }
        }

        if message.isLoading {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIGFLoaderChatCell", for: indexPath) as? AIGFLoaderChatCell else {
                return UITableViewCell()
            }
            setupCommonHandlers(for: cell)
            cell.configureLoader()
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
                reaction: message.reaction
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
                reaction: message.reaction
            )
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIGFTextChatCell", for: indexPath) as? AIGFTextChatCell else {
            return UITableViewCell()
        }
        setupCommonHandlers(for: cell)
        
        cell.configure(
            message: message.content,
            isUserMessage: isUser,
            needHideActionButtons: true,
            id: messageID,
            reaction: message.reaction
        )
        
        return cell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        inputTextView.textView.resignFirstResponder()
    }
}

extension AIGFChatView {
    func updateTextForIPadIfNeeded() {
        guard isIPad() else { return }
        
        navigationBar.updateForIPad()
        
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(90)
        }
        
        inputTextView.snp.updateConstraints { make in
            make.height.equalTo(70)
        }
    }
}
