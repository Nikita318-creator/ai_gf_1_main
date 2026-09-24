import UIKit
import SnapKit

protocol CardViewDelegate: AnyObject {
    func cardSwiped(profile: AIGFProfileModel, liked: Bool)
}

class SearchAIGFFeatureVC: UIViewController {
    
    private let viewModel = SearchAIGFFeatureViewModel()
    private lazy var profiles: [AIGFProfileModel] = viewModel.profiles
    
    private var currentCardIndex: Int = 0
    private var isFirstCardShown: Bool = true
    private let floatingShapeTag = 9001

    // Background elements
    private let backgroundGradient = CAGradientLayer()
    private let floatingShapes = [UIView]()
    
    // Navigation / Exit
    private let backButton = UIButton(type: .system)
    
    // Initial screen elements
    private let logoContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let decorativeIcon = UIImageView()
    
    // Swipe screen elements
    private let cardStackView = UIView()
    private let hintLabel = UILabel()
    private let actionButtonsContainer = UIView()
    private let passButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private let superLikeButton = UIButton(type: .system)
    private var chatView = SearchAIGFFeatureChatView()

    private var isRTL: Bool {
        return view.effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupBackButton()
        setupInitialScreen()
        updateUIForIPadIfNeeded()
        animateInitialAppearance()
        
        superLikeButton.isHidden = true // todo отказался от этой кнопки - вызывает баги после breakUp
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AmplitudeManager.shared.logEvent(name: "SwipeModeVC viewWillAppear", properties: ["": ""])

        navigationController?.setNavigationBarHidden(true, animated: animated)

        if UserDefaults.standard.bool(forKey: "swipeModeAssistantExist") {
            goToChat()
        } else {
            addFloatingShapes()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    // MARK: - Navigation / Back Button Setup
    
    private func setupBackButton() {
        backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backButton.tintColor = MyColors.textPrimary
        backButton.backgroundColor = MyColors.inputBackground.withAlphaComponent(0.6)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = MyColors.separator.cgColor
        backButton.clipsToBounds = true
        
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        view.addSubview(backButton)
        view.bringSubviewToFront(backButton)
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(40)
        }
    }
    
    @objc private func didTapBack() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Background Setup
    
    private func setupBackground() {
        backgroundGradient.colors = [
            MyColors.gradientStart.cgColor,
            MyColors.gradientEnd.cgColor
        ]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
        
        animateGradient()
    }
    
    private func animateGradient() {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 8.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.fromValue = backgroundGradient.colors
        animation.toValue = [
            MyColors.gradientEnd.cgColor,
            MyColors.gradientStart.cgColor
        ]
        backgroundGradient.add(animation, forKey: "gradientAnimation")
    }
    
    private func addFloatingShapes() {
        let isIPad = isCurrentDeviceiPad()
        let cornerRadiusRange: ClosedRange<CGFloat> = isIPad ? 35...100 : 20...60
        let sizeRange: ClosedRange<CGFloat> = isIPad ? 70...200 : 40...120
        
        for i in 0..<5 {
            let shape = UIView()
            shape.backgroundColor = MyColors.userMessageBackground.withAlphaComponent(0.08)
            shape.layer.cornerRadius = CGFloat.random(in: cornerRadiusRange)
            shape.alpha = 0.3
            shape.tag = floatingShapeTag

            let size = CGFloat.random(in: sizeRange)
            shape.frame = CGRect(
                x: CGFloat.random(in: 0...view.frame.width),
                y: CGFloat.random(in: 0...view.frame.height),
                width: size,
                height: size
            )
            
            view.addSubview(shape)
            view.sendSubviewToBack(shape)
            animateFloatingShape(shape, delay: Double(i) * 0.5)
        }
    }
    
    private func animateFloatingShape(_ shape: UIView, delay: Double) {
        UIView.animate(withDuration: Double.random(in: 15...25), delay: delay, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
            shape.transform = CGAffineTransform(translationX: CGFloat.random(in: -100...100), y: CGFloat.random(in: -200...200))
                .rotated(by: CGFloat.random(in: 0...(.pi * 2)))
        })
    }
    
    private func removeFloatingShapes() {
        for subview in view.subviews {
            if subview.tag == floatingShapeTag {
                subview.layer.removeAllAnimations()
                subview.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Initial Screen Setup
    
    private func setupInitialScreen() {
        setupLogoContainer()
        setupLabels()
        setupStartButton()
    }
    
    private func setupLogoContainer() {
        logoContainer.backgroundColor = MyColors.inputBackground
        logoContainer.layer.cornerRadius = 30
        logoContainer.layer.borderWidth = 1
        logoContainer.layer.borderColor = MyColors.separator.cgColor

        decorativeIcon.image = UIImage(systemName: "heart.fill")
        decorativeIcon.tintColor = MyColors.userMessageBackground
        decorativeIcon.contentMode = .scaleAspectFit
        logoContainer.addSubview(decorativeIcon)
        
        view.addSubview(logoContainer)
        
        logoContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.size.equalTo(100)
        }
        
        decorativeIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(50)
        }
    }
    
    private func setupLabels() {
        titleLabel.text = "LoveChat.title".localize()
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        subtitleLabel.text = "LoveChat.subTitle".localize()
        subtitleLabel.textColor = MyColors.textSecondary
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoContainer.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(30)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
    
    private func setupStartButton() {
        startButton.setTitle("LoveChat.ButtonText".localize(), for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.setTitleColor(MyColors.textPrimary, for: .normal)
        startButton.backgroundColor = MyColors.primaryButtonBackground
        startButton.layer.cornerRadius = 28
        startButton.clipsToBounds = true
        
        startButton.layer.shadowColor = MyColors.primaryButtonBackground.cgColor
        startButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        startButton.layer.shadowOpacity = 0.3
        startButton.layer.shadowRadius = 12
        
        startButton.addTarget(self, action: #selector(didTapStartSearch), for: .touchUpInside)
        view.addSubview(startButton)
        
        startButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(56)
        }
    }
    
    private func animateInitialAppearance() {
        logoContainer.alpha = 0
        logoContainer.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 30)
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 30)
        startButton.alpha = 0
        startButton.transform = CGAffineTransform(translationX: 0, y: 50)
        
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.logoContainer.alpha = 1
            self.logoContainer.transform = .identity
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.4) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.6) {
            self.subtitleLabel.alpha = 1
            self.subtitleLabel.transform = .identity
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.8, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.startButton.alpha = 1
            self.startButton.transform = .identity
        }
    }
    
    @objc private func didTapStartSearch() {
        UIView.animate(withDuration: 0.1, animations: {
            self.startButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            }
        }
        
        animateToSwipeScreen()
    }
    
    private func animateToSwipeScreen() {
        UIView.animate(withDuration: 0.5, animations: {
            self.logoContainer.alpha = 0
            self.logoContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.titleLabel.alpha = 0
            self.titleLabel.transform = CGAffineTransform(translationX: -50, y: 0)
            self.subtitleLabel.alpha = 0
            self.subtitleLabel.transform = CGAffineTransform(translationX: -50, y: 0)
            self.startButton.alpha = 0
            self.startButton.transform = CGAffineTransform(translationX: 0, y: 50)
        }) { _ in
            self.removeInitialScreenElements()
            self.setupSwipeScreen()
            self.showNextCard()
        }
    }
    
    private func removeInitialScreenElements() {
        logoContainer.removeFromSuperview()
        titleLabel.removeFromSuperview()
        subtitleLabel.removeFromSuperview()
        startButton.removeFromSuperview()
    }
    
    // MARK: - Swipe Screen Setup
    
    private func setupSwipeScreen() {
        setupCardStack()
        setupActionButtons()
        setupHintLabel()
        animateSwipeScreenAppearance()
    }
    
    private func setupCardStack() {
        cardStackView.backgroundColor = .clear
        view.addSubview(cardStackView)
        
        let bottomOffset: CGFloat = isCurrentDeviceiPad() ? -180 : -140
        let sideInset: CGFloat = isCurrentDeviceiPad() ? 32 : 20
        
        cardStackView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(sideInset)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(bottomOffset)
        }
    }
    
    private func setupActionButtons() {
        actionButtonsContainer.backgroundColor = .clear
        view.addSubview(actionButtonsContainer)
        
        let isIPad = isCurrentDeviceiPad()
        
        // Pass button (X)
        passButton.backgroundColor = MyColors.unselectedOption
        passButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        passButton.tintColor = MyColors.accentRed
        passButton.layer.cornerRadius = isIPad ? 48 : 30
        passButton.layer.borderWidth = 1
        passButton.layer.borderColor = MyColors.separator.cgColor
        passButton.addTarget(self, action: #selector(didTapPass), for: .touchUpInside)
        
        // Super like button (Star)
        superLikeButton.backgroundColor = MyColors.unselectedOption
        superLikeButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        superLikeButton.tintColor = MyColors.userMessageBackground
        superLikeButton.layer.cornerRadius = isIPad ? 40 : 25
        superLikeButton.layer.borderWidth = 1
        superLikeButton.layer.borderColor = MyColors.separator.cgColor
        superLikeButton.addTarget(self, action: #selector(didTapSuperLike), for: .touchUpInside)
        
        // Like button (Heart)
        likeButton.backgroundColor = MyColors.selectedOption
        likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        likeButton.tintColor = MyColors.userMessageBackground
        likeButton.layer.cornerRadius = isIPad ? 48 : 30
        likeButton.layer.borderWidth = 1
        likeButton.layer.borderColor = MyColors.userMessageBackground.cgColor
        likeButton.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        
        [passButton, superLikeButton, likeButton].forEach { actionButtonsContainer.addSubview($0) }
        
        let containerWidth: CGFloat = isIPad ? 300 : 200
        let containerHeight: CGFloat = isIPad ? 100 : 70
        let mainBtnSize: CGFloat = isIPad ? 96 : 60
        let superBtnSize: CGFloat = isIPad ? 80 : 50
        let bottomOffset: CGFloat = isIPad ? -40 : -30
        
        actionButtonsContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(bottomOffset)
            make.height.equalTo(containerHeight)
            make.width.equalTo(containerWidth)
        }
        
        passButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(mainBtnSize)
        }
        
        superLikeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(superBtnSize)
        }
        
        likeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(mainBtnSize)
        }
    }
    
    private func setupHintLabel() {
        hintLabel.text = "LoveChat.HintText".localize()
        hintLabel.textColor = MyColors.textSecondary
        hintLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 24 : 15, weight: .medium)
        hintLabel.textAlignment = .center
        hintLabel.alpha = 0
        
        view.addSubview(hintLabel)
        
        hintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }
    
    private func animateSwipeScreenAppearance() {
        cardStackView.alpha = 0
        cardStackView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        actionButtonsContainer.alpha = 0
        actionButtonsContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        
        UIView.animate(withDuration: 0.6, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.cardStackView.alpha = 1
            self.cardStackView.transform = .identity
        }
        
        UIView.animate(withDuration: 0.8, delay: 0.4, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.actionButtonsContainer.alpha = 1
            self.actionButtonsContainer.transform = .identity
        }
    }
    
    // MARK: - Card Logic
    
    private func showNextCard() {
        guard currentCardIndex < profiles.count else {
            showEndMessage()
            return
        }
        
        let profile = profiles[currentCardIndex]
        let newCard = SearchAIGFFeatureCardView(profile: profile, delegate: self)
        newCard.layer.cornerRadius = isCurrentDeviceiPad() ? 38 : 24
        newCard.clipsToBounds = true
        
        cardStackView.addSubview(newCard)
        newCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        newCard.alpha = 0
        newCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            newCard.alpha = 1
            newCard.transform = .identity
        }
        
        if isFirstCardShown {
            showHintWithAnimation()
            isFirstCardShown = false
        }
    }
    
    private func showHintWithAnimation() {
        UIView.animate(withDuration: 0.5, delay: 1.0) {
            self.hintLabel.alpha = 1
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                UIView.animate(withDuration: 0.5) {
                    self.hintLabel.alpha = 0
                }
            }
        }
    }
    
    private func showEndMessage() {
        let endLabel = UILabel()
        endLabel.text = "LoveChat.NoMoreGirls".localize()
        endLabel.textColor = MyColors.textPrimary
        endLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 28 : 18, weight: .medium)
        endLabel.textAlignment = .center
        endLabel.numberOfLines = 0
        endLabel.alpha = 0
        
        cardStackView.addSubview(endLabel)
        endLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        UIView.animate(withDuration: 0.5) {
            endLabel.alpha = 1
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func didTapPass() {
        animateButtonPress(passButton)
        guard currentCardIndex < profiles.count else { return }
        if let topCard = cardStackView.subviews.last as? SearchAIGFFeatureCardView {
            // В LTR крестик слева (-1), в RTL крестик справа (1)
            let direction: CGFloat = isRTL ? 1 : -1
            topCard.animateSwipeOut(direction: direction)
            cardSwiped(profile: profiles[currentCardIndex], liked: false)
        }
    }

    @objc private func didTapLike() {
        animateButtonPress(likeButton)
        guard currentCardIndex < profiles.count else { return }
        if let topCard = cardStackView.subviews.last as? SearchAIGFFeatureCardView {
            // В LTR сердечко справа (1), в RTL сердечко слева (-1)
            let direction: CGFloat = isRTL ? -1 : 1
            topCard.animateSwipeOut(direction: direction)
            cardSwiped(profile: profiles[currentCardIndex], liked: true)
        }
    }
    
    @objc private func didTapSuperLike() {
        currentCardIndex += 1
        animateButtonPress(superLikeButton)
        guard currentCardIndex < profiles.count else { return }
        if let topCard = cardStackView.subviews.last as? SearchAIGFFeatureCardView {
            topCard.animateSwipeOut(direction: 0)
            presentSuperLikeMatch(with: profiles[currentCardIndex])
        }
    }
    
    private func animateButtonPress(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
    
    // MARK: - Match Presentation
    
    private func presentChat(with profile: AIGFProfileModel) {
        presentMatchAnimation(with: profile, type: .regular)
    }
    
    private func presentSuperLikeMatch(with profile: AIGFProfileModel) {
        presentMatchAnimation(with: profile, type: .superLike)
    }
    
    private enum MatchType {
        case regular, superLike
    }
    
    private func presentMatchAnimation(with profile: AIGFProfileModel, type: MatchType) {
        let overlayView = UIView()
        overlayView.backgroundColor = MyColors.gradientStart.withAlphaComponent(0.95)
        overlayView.alpha = 0
        
        let matchLabel = UILabel()
        matchLabel.text = type == .superLike ? "LoveChat.SUPERMATCH".localize() : "LoveChat.ITSAMATCH".localize()
        matchLabel.textColor = MyColors.textPrimary
        matchLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 50 : 32, weight: .heavy)
        matchLabel.textAlignment = .center
        matchLabel.alpha = 0
        matchLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        view.addSubview(overlayView)
        view.addSubview(matchLabel)
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        matchLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            overlayView.alpha = 1
        })
        
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            matchLabel.alpha = 1
            matchLabel.transform = .identity
        } completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIView.animate(withDuration: 0.5, animations: {
                    overlayView.alpha = 0
                    matchLabel.alpha = 0
                }) { [weak self] _ in
                    overlayView.removeFromSuperview()
                    matchLabel.removeFromSuperview()
                    self?.goToChat()
                }
            }
        }
    }
    
    private func goToChat() {
        let currentProfile: AIGFProfileModel

        if !UserDefaults.standard.bool(forKey: "swipeModeAssistantExist") {
            UserDefaults.standard.set(true, forKey: "swipeModeAssistantExist")
            currentProfile = profiles[(currentCardIndex > 0) ? currentCardIndex - 1 : 0]
            UserDefaults.standard.setCodable(currentProfile, forKey: "swipeModeCurrentProfile")
        } else {
            currentProfile = UserDefaults.standard.getCodable(AIGFProfileModel.self, forKey: "swipeModeCurrentProfile") ?? AIGFProfileModel(id: 111, name: "Mia", age: 22, bio: "", imageName: "swipeModeAvatar2", interests: [])
        }

        removeFloatingShapes()
        
        let currentAssistant = AIGirlfriendsConfig(
            id: BaseManager.shared.loveAssistantId,
            assistantName: currentProfile.name,
            assistantInfo: "",
            avatarImageName: currentProfile.imageName
        )
        
        BaseManager.shared.currentAssistant = currentAssistant
        
        chatView.removeFromSuperview()
        chatView = SearchAIGFFeatureChatView()
        view.addSubview(chatView)
        chatView.vc = self
        chatView.setup()
        chatView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        chatView.setMessagesFromDB()
        chatView.setupNavTitleAndAvatar()
        chatView.setupLoveChatView()
        
        chatView.breakUpHandler = { [weak self] in
            self?.clearChatButtonTapped()
        }
        
        view.bringSubviewToFront(backButton)
    }
    
    @objc private func clearChatButtonTapped() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
                
        let alertController = UIAlertController(
            title: "BreakUp".localize(),
            message: "BreakUp.Message".localize(),
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "BreakUp".localize(), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            AIGirlfriendMessagesManager().getAllMessages(forAssistantId: BaseManager.shared.loveAssistantId).forEach {
                AIGirlfriendMessagesManager().deleteMessage(id: $0.id ?? "")
            }
            UserDefaults.standard.set(false, forKey: "swipeModeAssistantExist")
            chatView.removeFromSuperview()
            CoinsService.shared.removeAllSentGifts(for: BaseManager.shared.loveAssistantId)
        }
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

extension SearchAIGFFeatureVC: CardViewDelegate {
    func cardSwiped(profile: AIGFProfileModel, liked: Bool) {
        AmplitudeManager.shared.logEvent(name: "SwipeModeVC cardSwiped", properties: ["currentCardIndex:": "\(currentCardIndex)", "liked:":"\(liked)"])

        currentCardIndex += 1
        
        if liked {
            presentChat(with: profile)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (liked ? 2.5 : 0.3)) {
            self.showNextCard()
        }
    }
}

// MARK: - iPad Layout Adaptation

extension SearchAIGFFeatureVC {
    private func isCurrentDeviceiPad() -> Bool {
        return view.isNeedBigTextForIPad()
    }
    
    func updateUIForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        // Navigation / Back Button
        backButton.layer.cornerRadius = 32
        backButton.snp.updateConstraints { make in
            make.size.equalTo(64)
        }
        
        // Initial Screen - Logo
        logoContainer.layer.cornerRadius = 50
        logoContainer.snp.updateConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(90)
            make.size.equalTo(160)
        }
        
        decorativeIcon.snp.updateConstraints { make in
            make.size.equalTo(80)
        }
        
        // Initial Screen - Typography
        titleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        subtitleLabel.font = .systemFont(ofSize: 26, weight: .regular)
        
        titleLabel.snp.updateConstraints { make in
            make.top.equalTo(logoContainer.snp.bottom).offset(48)
        }
        
        subtitleLabel.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
        }
        
        // Initial Screen - Start Button
        startButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .semibold)
        startButton.layer.cornerRadius = 44
        
        startButton.snp.updateConstraints { make in
            make.height.equalTo(88)
        }
    }
}
