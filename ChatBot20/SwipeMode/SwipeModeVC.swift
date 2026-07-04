import UIKit
import SnapKit

protocol CardViewDelegate: AnyObject {
    func cardSwiped(profile: Profile, liked: Bool)
}

class SwipeModeVC: UIViewController {
    private struct ModernColors {
        static let primary = UIColor(red: 0.98, green: 0.31, blue: 0.45, alpha: 1.0) // Modern pink gradient
        static let secondary = UIColor(red: 1.0, green: 0.40, blue: 0.25, alpha: 1.0) // Orange gradient
        static let background = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0) // Deep dark
        static let cardBackground = UIColor.white
        static let overlayBackground = UIColor.black.withAlphaComponent(0.1)
        static let textPrimary = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
        static let textSecondary = UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0)
        static let likeGreen = UIColor(red: 0.30, green: 0.85, blue: 0.39, alpha: 1.0)
        static let passRed = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        static let glassMorphism = UIColor.white.withAlphaComponent(0.1)
    }
    
    private let viewModel = SwipeModeViewModel()
    private lazy var profiles: [Profile] = viewModel.profiles
    
    private var currentCardIndex: Int = 0
    private var isFirstCardShown: Bool = true
    private let floatingShapeTag = 9001

    // Background elements
    private let backgroundGradient = CAGradientLayer()
    private let floatingShapes = [UIView]()
    
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
    private var chatView = LoveChatView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupInitialScreen()
        animateInitialAppearance()
        
        superLikeButton.isHidden = true // todo откзался от этой кнопки - вызывает баги после breakUp
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AnalyticService.shared.logEvent(name: "SwipeModeVC viewWillAppear", properties: ["": ""])

        if UserDefaults.standard.bool(forKey: "swipeModeAssistantExist") {
            goToChat()
        } else {
            addFloatingShapes()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        setupBackground()
    }
    
    // MARK: - Background Setup
    
    private func setupBackground() {
        // Animated gradient background
        backgroundGradient.colors = [
            ModernColors.primary.cgColor,
            ModernColors.secondary.cgColor,
            ModernColors.background.cgColor
        ]
        backgroundGradient.locations = [0.0, 0.6, 1.0]
        backgroundGradient.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradient.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(backgroundGradient, at: 0)
        
        // Add subtle animation to gradient
        animateGradient()
    }
    
    private func animateGradient() {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 8.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.fromValue = backgroundGradient.colors
        animation.toValue = [
            ModernColors.secondary.cgColor,
            ModernColors.primary.cgColor,
            ModernColors.background.cgColor
        ]
        backgroundGradient.add(animation, forKey: "gradientAnimation")
    }
    
    private func addFloatingShapes() {
        for i in 0..<5 {
            let shape = UIView()
            shape.backgroundColor = ModernColors.glassMorphism
            shape.layer.cornerRadius = CGFloat.random(in: 20...60)
            shape.alpha = 0.3
            shape.tag = floatingShapeTag

            let size = CGFloat.random(in: 40...120)
            shape.frame = CGRect(
                x: CGFloat.random(in: 0...view.frame.width),
                y: CGFloat.random(in: 0...view.frame.height),
                width: size,
                height: size
            )
            
            view.addSubview(shape)
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
        logoContainer.backgroundColor = ModernColors.glassMorphism
        logoContainer.layer.cornerRadius = 30
        logoContainer.layer.borderWidth = 1
        logoContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

        // Decorative heart icon
        decorativeIcon.image = UIImage(systemName: "heart.fill")
        decorativeIcon.tintColor = ModernColors.primary
        decorativeIcon.contentMode = .scaleAspectFit
        logoContainer.addSubview(decorativeIcon)
        
        view.addSubview(logoContainer)
        
        // Constraints
        logoContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(120)
            make.size.equalTo(100)
        }
        
        decorativeIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(50)
        }
    }
    
    private func setupLabels() {
        // Main title
        titleLabel.text = "LoveChat.title".localize()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 36, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Add shadow for depth
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        titleLabel.layer.shadowOpacity = 0.3
        titleLabel.layer.shadowRadius = 4
        
        // Subtitle
        subtitleLabel.text = "LoveChat.subTitle".localize()
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoContainer.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(30)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
    
    private func setupStartButton() {
        startButton.setTitle("LoveChat.ButtonText".localize(), for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 28
        startButton.clipsToBounds = true
        
        // Gradient background for button
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ModernColors.primary.cgColor, ModernColors.secondary.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 28
        startButton.layer.insertSublayer(gradientLayer, at: 0)
        
        // Add subtle shadow
        startButton.layer.shadowColor = ModernColors.primary.cgColor
        startButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        startButton.layer.shadowOpacity = 0.3
        startButton.layer.shadowRadius = 16
        
        startButton.addTarget(self, action: #selector(didTapStartSearch), for: .touchUpInside)
        view.addSubview(startButton)
        
        startButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
            make.height.equalTo(56)
        }
        
        // Update gradient frame when layout changes
        DispatchQueue.main.async {
            gradientLayer.frame = self.startButton.bounds
        }
    }
    
    private func animateInitialAppearance() {
        // Initial state - hidden
        logoContainer.alpha = 0
        logoContainer.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 30)
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 30)
        startButton.alpha = 0
        startButton.transform = CGAffineTransform(translationX: 0, y: 50)
        
        // Animate appearance
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
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.startButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            }
        }
        
        // Animate out initial screen
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
        // Update background for card viewing
        backgroundGradient.colors = [
            UIColor.white.cgColor,
            UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1.0).cgColor
        ]
        
        setupCardStack()
        setupActionButtons()
        setupHintLabel()
        animateSwipeScreenAppearance()
    }
    
    private func setupCardStack() {
        cardStackView.backgroundColor = .clear
        view.addSubview(cardStackView)
        
        cardStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-180)
        }
    }
    
    private func setupActionButtons() {
        actionButtonsContainer.backgroundColor = .clear
        view.addSubview(actionButtonsContainer)
        
        // Pass button (X)
        passButton.backgroundColor = .white
        passButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        passButton.tintColor = ModernColors.passRed
        passButton.layer.cornerRadius = 30
        passButton.layer.shadowColor = UIColor.black.cgColor
        passButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        passButton.layer.shadowOpacity = 0.1
        passButton.layer.shadowRadius = 8
        passButton.addTarget(self, action: #selector(didTapPass), for: .touchUpInside)
        
        // Super like button (Star)
        superLikeButton.backgroundColor = .white
        superLikeButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        superLikeButton.tintColor = ModernColors.secondary
        superLikeButton.layer.cornerRadius = 25
        superLikeButton.layer.shadowColor = UIColor.black.cgColor
        superLikeButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        superLikeButton.layer.shadowOpacity = 0.1
        superLikeButton.layer.shadowRadius = 8
        superLikeButton.addTarget(self, action: #selector(didTapSuperLike), for: .touchUpInside)
        
        // Like button (Heart)
        likeButton.backgroundColor = .white
        likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        likeButton.tintColor = ModernColors.likeGreen
        likeButton.layer.cornerRadius = 30
        likeButton.layer.shadowColor = UIColor.black.cgColor
        likeButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        likeButton.layer.shadowOpacity = 0.1
        likeButton.layer.shadowRadius = 8
        likeButton.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        
        [passButton, superLikeButton, likeButton].forEach { actionButtonsContainer.addSubview($0) }
        
        actionButtonsContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
            make.height.equalTo(80)
            make.width.equalTo(200)
        }
        
        passButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
        }
        
        superLikeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        likeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
        }
    }
    
    private func setupHintLabel() {
        hintLabel.text = "LoveChat.HintText".localize()
        hintLabel.textColor = ModernColors.textSecondary
        hintLabel.font = .systemFont(ofSize: 16, weight: .medium)
        hintLabel.textAlignment = .center
        hintLabel.alpha = 0
        
        hintLabel.layer.shadowColor = UIColor.black.cgColor
        hintLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        hintLabel.layer.shadowOpacity = 0.6
        hintLabel.layer.shadowRadius = 2.0
        
        view.addSubview(hintLabel)
        
        hintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }
    
    private func animateSwipeScreenAppearance() {
        // Initial state
        cardStackView.alpha = 0
        cardStackView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        actionButtonsContainer.alpha = 0
        actionButtonsContainer.transform = CGAffineTransform(translationX: 0, y: 50)
        
        // Animate appearance
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
        let newCard = ModernCardView(profile: profile, delegate: self)
        newCard.layer.cornerRadius = 25
        newCard.clipsToBounds = true
        
        cardStackView.addSubview(newCard)
        newCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Add entrance animation
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
        endLabel.textColor = ModernColors.textPrimary
        endLabel.font = .systemFont(ofSize: 20, weight: .medium)
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
        if let topCard = cardStackView.subviews.last as? ModernCardView {
            topCard.animateSwipeOut(direction: -1)
            cardSwiped(profile: profiles[currentCardIndex], liked: false)
        }
    }
    
    @objc private func didTapLike() {
        animateButtonPress(likeButton)
        guard currentCardIndex < profiles.count else { return }
        if let topCard = cardStackView.subviews.last as? ModernCardView {
            topCard.animateSwipeOut(direction: 1)
            cardSwiped(profile: profiles[currentCardIndex], liked: true)
        }
    }
    
    @objc private func didTapSuperLike() {
        currentCardIndex += 1
        animateButtonPress(superLikeButton)
        guard currentCardIndex < profiles.count else { return }
        if let topCard = cardStackView.subviews.last as? ModernCardView {
            topCard.animateSwipeOut(direction: 0) // Up direction for super like
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
    
    private func presentChat(with profile: Profile) {
        presentMatchAnimation(with: profile, type: .regular)
    }
    
    private func presentSuperLikeMatch(with profile: Profile) {
        presentMatchAnimation(with: profile, type: .superLike)
    }
    
    private enum MatchType {
        case regular, superLike
    }
    
    private func presentMatchAnimation(with profile: Profile, type: MatchType) {
        let overlayView = UIView()
        overlayView.backgroundColor = type == .superLike ? ModernColors.secondary.withAlphaComponent(0.95) : ModernColors.primary.withAlphaComponent(0.95)
        overlayView.alpha = 0
        
        let matchLabel = UILabel()
        matchLabel.text = type == .superLike ? "LoveChat.SUPERMATCH".localize() : "LoveChat.ITSAMATCH".localize()
        matchLabel.textColor = .white
        matchLabel.font = .systemFont(ofSize: 32, weight: .heavy)
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
        
        // Animate match screen
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
        if !UserDefaults.standard.bool(forKey: "swipeModeAssistantExist") {
            UserDefaults.standard.set(true, forKey: "swipeModeAssistantExist")
            UserDefaults.standard.set(currentCardIndex, forKey: "swipeModeAssistantExist_Index")
        } else {
            currentCardIndex = UserDefaults.standard.integer(forKey: "swipeModeAssistantExist_Index")
        }

        removeFloatingShapes()
        
        let currentProfile = profiles[(currentCardIndex > 0) ? currentCardIndex - 1 : 0]
        let currentAssistant = AssistantConfig(
            id: MainHelper.shared.loveAssistantId,
            assistantName: currentProfile.name,
            aiModel: .gemini2,
            tone: .soft,
            style: .neutral,
            expertise: .casual,
            assistantInfo: "",
            userInfo: "",
            avatarImageName: currentProfile.imageName
        )
        
        MainHelper.shared.isCurrentAssistantPremium = false
        MainHelper.shared.currentAssistant = currentAssistant
        
        chatView.removeFromSuperview()
        chatView = LoveChatView()
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
            
            MessageHistoryService().getAllMessages(forAssistantId: MainHelper.shared.loveAssistantId).forEach {
                MessageHistoryService().deleteMessage(id: $0.id ?? "")
            }
            UserDefaults.standard.set(false, forKey: "swipeModeAssistantExist")
            chatView.removeFromSuperview()
            viewModel.resetAvatars()
            CoinsService.shared.removeAllSentGifts(for: MainHelper.shared.loveAssistantId)
        }
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

extension SwipeModeVC: CardViewDelegate {
    func cardSwiped(profile: Profile, liked: Bool) {
        AnalyticService.shared.logEvent(name: "SwipeModeVC cardSwiped", properties: ["currentCardIndex:": "\(currentCardIndex)", "liked:":"\(liked)"])

        currentCardIndex += 1
        
        if liked {
            presentChat(with: profile)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (liked ? 2.5 : 0.3)) {
            self.showNextCard()
        }
    }
}
