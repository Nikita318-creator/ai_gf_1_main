import UIKit
import SnapKit
import StoreKit

class RockStarChat: UIView {
    
    private let topNavigationHeader = RockStarChatNavBar()
    private let messageContentTable = UITableView()
    let inputTextView = ChatRockStarBottomTextFild()
    let subsView = PaywallView()
    
    private let backdropImageView = UIImageView()
    private let backdropMaskView = UIView()
    private let backgroundGradient = CAGradientLayer()
    private var streakNotificationCard: UIView?
    private var keyboardVerticalOffset: CGFloat = 0
    
    weak var vc: UIViewController?
    let viewModel = RockStarChatVM()

    var backButton: UIButton { get { topNavigationHeader.backButton } }
    var repository: RockStarRepository { get { viewModel.repository } }

    func setup() {
        registerSystemEvents()
        renderBackdropContainer()
        renderNavigationHeader()
        renderMessageTable()
        renderInputField()
        applyLayoutConstraints()
        bindViewModelEvents()
        
        viewModel.loadMessages()
        setNavView()
        attachDismissGesture()
        iPadCheck()
        
        if MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName.contains("swipeModeAvatar") == true {
            inputTextView.hideVideoPrompt()
            inputTextView.hidePhotoPrompt()
        }
        
        if let avatarIdentifier = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName, (21...26).map({ "mainAvatar\($0)" }).contains(avatarIdentifier) {
            inputTextView.hideVideoPrompt()
            if BackendService.shared.currentData.aiText.isEmpty {
                inputTextView.hidePhotoPrompt()
            }
        }
        
        if let avatarIdentifier = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName, avatarIdentifier.contains("waifuInOutfit_") {
            inputTextView.hidePhotoPrompt()
        }
    }

    private func bindViewModelEvents() {
        viewModel.onMessagesUpdated = { [weak self] isOperationSuccess in
            if isOperationSuccess {
                DispatchQueue.main.async {
                    self?.messageContentTable.reloadData()
                    self?.performScrollToBottom()
                }
            }
        }
        
        viewModel.onMessageReceived = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.inputTextView.enableSendButton()
            }
        }
        
        viewModel.onShowAlert = { [weak self] alertCategory in
            DispatchQueue.main.async {
                self?.presentAlertPopup(category: alertCategory)
            }
        }
        
        viewModel.onShowToast = { [weak self] textContent in
            DispatchQueue.main.async {
                self?.presentToastOverlay(textContent)
            }
        }
    }

    private func renderNavigationHeader() {
        addSubview(topNavigationHeader)
        
        topNavigationHeader.onBackTapped = { [weak self] in
            self?.plusButtonTapped()
        }
        
        topNavigationHeader.onCallTapped = { [weak self] in
            self?.callButtonTapped()
        }
        
        topNavigationHeader.onAvatarTapped = { [weak self] in
            if !BackendService.shared.currentData.aiText.isEmpty {
                self?.handleAvatarTap()
            }
        }
        
        topNavigationHeader.onProfileTapped = { [weak self] in
            if !BackendService.shared.currentData.aiText.isEmpty {
                self?.handleAvatarTap()
            }
        }
    }

    func setNavView() {
        topNavigationHeader.configure(
            title: MyGovnoSingltone.shared.selectedAICompanion?.assistantName,
            avatarImage: viewModel.getAvatarImage()
        )
        
        if !BackendService.shared.currentData.aiText.isEmpty {
            backdropImageView.image = viewModel.getAvatarImage()
        } else {
            backdropImageView.image = UIImage.gradientImage(
                colors: [BasePalitColors.gradientStart, BasePalitColors.gradientEnd],
                size: bounds.size.equalTo(.zero) ? CGSize(width: 300, height: 600) : bounds.size
            )
        }
    }

    private func renderBackdropContainer() {
        backgroundColor = BasePalitColors.background

        backdropImageView.contentMode = .scaleAspectFill
        backdropImageView.clipsToBounds = true
        addSubview(backdropImageView)

        backdropMaskView.backgroundColor = BasePalitColors.background.withAlphaComponent(0.6)
        addSubview(backdropMaskView)

        backgroundGradient.colors = [
            BasePalitColors.background.cgColor,
            BasePalitColors.gradientEnd.cgColor
        ]
        backgroundGradient.locations = [0.0, 1.0]
        layer.insertSublayer(backgroundGradient, at: 0)
    }

    private func renderMessageTable() {
        messageContentTable.backgroundColor = .clear
        messageContentTable.separatorStyle = .none
        messageContentTable.allowsSelection = false
        messageContentTable.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        messageContentTable.delegate = self
        messageContentTable.dataSource = self
        messageContentTable.showsVerticalScrollIndicator = false
        messageContentTable.showsHorizontalScrollIndicator = false
        messageContentTable.register(AbstractChatCell.self, forCellReuseIdentifier: AbstractChatCell.identifier)
        messageContentTable.register(TextChatCell.self, forCellReuseIdentifier: "AIGFTextChatCell")
        messageContentTable.register(MediaChatCell.self, forCellReuseIdentifier: "AIGFMediaChatCell")
        messageContentTable.register(VoiceChatCell.self, forCellReuseIdentifier: "AIGFVoiceChatCell")
        messageContentTable.register(LoaderChatCell.self, forCellReuseIdentifier: "AIGFLoaderChatCell")
        
        addSubview(messageContentTable)
    }

    private func renderInputField() {
        inputTextView.vc = vc
        addSubview(inputTextView)
        inputTextView.setup()

        inputTextView.layer.shadowColor = BasePalitColors.background.cgColor
        inputTextView.layer.shadowOpacity = 0.1
        inputTextView.layer.shadowOffset = CGSize(width: 0, height: -1)
        inputTextView.layer.shadowRadius = 3
        
        inputTextView.sendMessageHandler = { [weak self] outgoingText in
            guard let self = self else { return }
            self.viewModel.handleSendMessage(
                text: outgoingText,
                containerView: self,
                avatarView: self.topNavigationHeader.avatarImageView,
                tableView: self.messageContentTable
            )
            self.triggerSendHaptic()
        }
        
        inputTextView.showInternetErrorAlertHandler = { [weak self] in
            self?.presentNetworkErrorDialog()
        }
        
        inputTextView.pleaseWaitHandler = { [weak self] in
            self?.presentToastOverlay("Oh, sweetie, you're typing so fast! I can't catch my breath. Give me just a second to catch up? 💕", alpha: 1)
        }
        
        inputTextView.textDidChangedHandler = { [weak self] in
            guard let self = self else { return }
            if self.repository.dataModel.first(where: { $0.isWaiting }) == nil {
                self.inputTextView.enableSendButton()
            }
        }
        
        inputTextView.needPremiumForAudioHandler = { [weak self] in
            self?.presentAlertPopup(category: .needPremiumForAudio)
        }
    }

    private func applyLayoutConstraints() {
        backdropImageView.snp.makeConstraints { makeContainer in
            makeContainer.edges.equalToSuperview()
        }
        backdropMaskView.snp.makeConstraints { makeContainer in
            makeContainer.edges.equalToSuperview()
        }

        topNavigationHeader.snp.makeConstraints { makeContainer in
            makeContainer.top.equalTo(safeAreaLayoutGuide)
            makeContainer.leading.trailing.equalToSuperview()
            makeContainer.height.equalTo(60)
        }

        messageContentTable.snp.makeConstraints { makeContainer in
            makeContainer.top.equalTo(topNavigationHeader.snp.bottom)
            makeContainer.leading.trailing.equalToSuperview()
            makeContainer.bottom.equalTo(inputTextView.snp.top)
        }

        inputTextView.snp.makeConstraints { makeContainer in
            makeContainer.leading.trailing.equalToSuperview()
            makeContainer.bottom.equalTo(safeAreaLayoutGuide)
            makeContainer.height.equalTo(60)
        }
    }

    private func presentAlertPopup(category: BaseAlert.Types) {
        let alertModal = BaseAlert(type: category, onOk: ({ [weak self] in
            self?.displaySubscriptionPaywall()
        }))
        inputTextView.textView.resignFirstResponder()
        alertModal.show(on: self)
    }
    
    func fetchMessageHistory() {
        viewModel.loadMessages()
        DispatchQueue.main.async {
            self.messageContentTable.reloadData()
            self.performScrollToBottom(isAnimated: false)
        }
    }

    private func registerSystemEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func attachDismissGesture() {
        let rightSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRightGesture(_:)))
        rightSwipeRecognizer.direction = .right
        self.addGestureRecognizer(rightSwipeRecognizer)
    }

    @objc private func handleSwipeRightGesture(_ gesture: UISwipeGestureRecognizer) {
        guard let parentVC = vc else { return }
        inputTextView.textView.resignFirstResponder()
        let feedbackEngine = UIImpactFeedbackGenerator(style: .light)
        feedbackEngine.impactOccurred()
        parentVC.dismiss(animated: true)
    }

    private func triggerSendHaptic() {
        let feedbackEngine = UIImpactFeedbackGenerator(style: .light)
        feedbackEngine.impactOccurred()
    }

    func scrollToBottomAnimated(isAnimated: Bool = true) {
        performScrollToBottom(isAnimated: isAnimated)
    }

    private func performScrollToBottom(isAnimated: Bool = true) {
        let totalRows = messageContentTable.numberOfRows(inSection: 0)
        let destinationIndex = repository.dataModel.count - 1

        guard totalRows > 0, destinationIndex >= 0, destinationIndex < totalRows else { return }

        let targetIndexPath = IndexPath(row: destinationIndex, section: 0)
        messageContentTable.scrollToRow(at: targetIndexPath, at: .bottom, animated: isAnimated)
    }

    private func presentNetworkErrorDialog() {
        let feedbackEngine = UINotificationFeedbackGenerator()
        feedbackEngine.notificationOccurred(.error)
        
        let alertController = UIAlertController(
            title: "No Internet Connection",
            message: "Please check your network settings and try again.",
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(confirmAction)
        
        vc?.present(alertController, animated: true)
    }
    
    private func presentToastOverlay(_ messageText: String, alpha: CGFloat = 0.8) {
        let toastContainer = UIView()
        toastContainer.backgroundColor = BasePalitColors.messageBackground.withAlphaComponent(alpha)
        toastContainer.layer.cornerRadius = 18
        toastContainer.layer.borderWidth = 1
        toastContainer.layer.borderColor = BasePalitColors.separator.withAlphaComponent(0.5).cgColor
        toastContainer.clipsToBounds = true
        
        let toastLabel = UILabel()
        toastLabel.text = messageText
        toastLabel.textColor = BasePalitColors.textPrimary
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.numberOfLines = 0
        toastLabel.textAlignment = .center
        
        toastContainer.addSubview(toastLabel)
        addSubview(toastContainer)
        
        toastContainer.snp.makeConstraints { makeContainer in
            makeContainer.top.equalTo(self.topNavigationHeader.snp.bottom).offset(10)
            makeContainer.centerX.equalToSuperview()
            makeContainer.width.lessThanOrEqualTo(self).multipliedBy(0.8)
            makeContainer.height.greaterThanOrEqualTo(40)
        }
        
        toastLabel.snp.makeConstraints { makeContainer in
            makeContainer.edges.equalToSuperview().inset(12)
        }
        
        toastContainer.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            toastContainer.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, animations: {
                toastContainer.alpha = 0
            }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }

    @objc func plusButtonTapped() {
        inputTextView.textView.resignFirstResponder()
        let feedbackEngine = UIImpactFeedbackGenerator(style: .light)
        feedbackEngine.impactOccurred()

        vc?.dismiss(animated: true)
    }

    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardVerticalOffset = keyboardFrameValue.height
        repositionKeyboardLayout()
    }

    @objc private func handleKeyboardWillHide() {
        keyboardVerticalOffset = 8
        repositionKeyboardLayout()
    }

    @objc private func handleAvatarTap() {
        inputTextView.textView.resignFirstResponder()
        
        guard let parentVC = vc else { return }
        let previewModal = PhotoPreviewer(image: viewModel.getAvatarImage())
        previewModal.vc = parentVC
        previewModal.show(in: parentVC.view)
    }
    
    @objc func callButtonTapped() {
        guard SubscriptionManager.shared.hasActiveSubscription else {
            displaySubscriptionPaywall()
            return
        }
    }

    private func repositionKeyboardLayout() {
        var shouldScrollToBottom = false
        let inputContainerHeight: CGFloat = isIPad() ? 70 : 60
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            if self.keyboardVerticalOffset == 8 {
                self.inputTextView.snp.remakeConstraints { makeContainer in
                    makeContainer.leading.trailing.equalToSuperview()
                    makeContainer.bottom.equalTo(self.safeAreaLayoutGuide)
                    makeContainer.height.equalTo(inputContainerHeight)
                }
            } else {
                shouldScrollToBottom = true
                self.inputTextView.snp.remakeConstraints { makeContainer in
                    makeContainer.leading.trailing.equalToSuperview()
                    makeContainer.bottom.equalToSuperview().inset(self.keyboardVerticalOffset)
                    makeContainer.height.equalTo(inputContainerHeight)
                }
            }

            self.layoutIfNeeded()
        } completion: { _ in
            if shouldScrollToBottom {
                self.performScrollToBottom()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundGradient.frame = bounds
    }

    private func displaySubscriptionPaywall() {
        inputTextView.textView.resignFirstResponder()
        subsView.vc = vc
        
        addSubview(subsView)

        subsView.snp.remakeConstraints { makeContainer in
            makeContainer.edges.equalToSuperview()
        }

        subsView.transform = CGAffineTransform(translationX: 0, y: -UIScreen.main.bounds.height)

        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.subsView.transform = .identity
        }) { [weak self] _ in
            self?.inputTextView.textView.resignFirstResponder()
        }
    }

    deinit {
        MyGovnoSingltone.shared.voiceChatToggleOn = false
        NotificationCenter.default.removeObserver(self)
    }
}

extension RockStarChat: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repository.dataModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < repository.dataModel.count else {
            return UITableViewCell()
        }
        
        let currentMessage = repository.dataModel[indexPath.row]
        let messageIdentifier = currentMessage.id ?? ""
        let isUserAuthor = currentMessage.authoreRole == "man"

        func configureCellHandlers(for reusableCell: AbstractChatCell) {
            reusableCell.vc = self.vc
            
            reusableCell.hideKeyboardHandler = { [weak self] in
                self?.inputTextView.textView.resignFirstResponder()
            }
            
            reusableCell.openPaywallHandler = { [weak self] in
                self?.displaySubscriptionPaywall()
            }
            
            reusableCell.needReloadTableHandler = { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.viewModel.loadMessages()
                    self.messageContentTable.reloadData()
                }
            }
            
            reusableCell.avatarTappedHandler = { [weak self] in
                self?.handleAvatarTap()
            }
        }

        if currentMessage.isWaiting {
            guard let loaderCell = tableView.dequeueReusableCell(withIdentifier: "AIGFLoaderChatCell", for: indexPath) as? LoaderChatCell else {
                return UITableViewCell()
            }
            configureCellHandlers(for: loaderCell)
            loaderCell.configureLoader()
            return loaderCell
        }

        if currentMessage.isAudio && !isUserAuthor {
            guard let voiceCell = tableView.dequeueReusableCell(withIdentifier: "AIGFVoiceChatCell", for: indexPath) as? VoiceChatCell else {
                return UITableViewCell()
            }
            configureCellHandlers(for: voiceCell)
            voiceCell.configure(
                message: currentMessage.theMessage,
                isUserMessage: isUserAuthor,
                id: messageIdentifier,
                reaction: currentMessage.emogi
            )
            return voiceCell
        }

        if !currentMessage.mediaFileID.isEmpty {
            guard let mediaCell = tableView.dequeueReusableCell(withIdentifier: "AIGFMediaChatCell", for: indexPath) as? MediaChatCell else {
                return UITableViewCell()
            }
            configureCellHandlers(for: mediaCell)
            mediaCell.configure(
                message: currentMessage.theMessage,
                isUserMessage: isUserAuthor,
                photoID: currentMessage.mediaFileID,
                id: messageIdentifier,
                reaction: currentMessage.emogi
            )
            return mediaCell
        }

        guard let textCell = tableView.dequeueReusableCell(withIdentifier: "AIGFTextChatCell", for: indexPath) as? TextChatCell else {
            return UITableViewCell()
        }
        configureCellHandlers(for: textCell)
        
        textCell.configure(
            message: currentMessage.theMessage,
            isUserMessage: isUserAuthor,
            needHideActionButtons: true,
            id: messageIdentifier,
            reaction: currentMessage.emogi
        )
        
        return textCell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        inputTextView.textView.resignFirstResponder()
    }
}

extension RockStarChat {
    func iPadCheck() {
        guard isIPad() else { return }
        
        topNavigationHeader.updateForIPad()
        
        topNavigationHeader.snp.updateConstraints { makeContainer in
            makeContainer.height.equalTo(90)
        }
        
        inputTextView.snp.updateConstraints { makeContainer in
            makeContainer.height.equalTo(70)
        }
    }
}
