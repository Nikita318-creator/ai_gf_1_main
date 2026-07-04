import UIKit
import SnapKit

class ModernCardView: UIView {
    private struct ModernColors {
        static let primary = UIColor(red: 0.98, green: 0.31, blue: 0.45, alpha: 1.0)
        static let secondary = UIColor(red: 1.0, green: 0.40, blue: 0.25, alpha: 1.0)
        static let cardBackground = UIColor.white
        static let textPrimary = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
        static let textSecondary = UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0)
        static let likeGreen = UIColor(red: 0.30, green: 0.85, blue: 0.39, alpha: 1.0)
        static let passRed = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        static let glassMorphism = UIColor.white.withAlphaComponent(0.9)
        static let interestTag = UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1.0)
    }
    
    weak var delegate: CardViewDelegate?
    private let profile: Profile
    
    // UI Elements
    private let imageView = UIImageView()
    private let gradientOverlay = CAGradientLayer()
    private let infoContainer = UIView()
    private let nameLabel = UILabel()
    private let ageLabel = UILabel()
    private let bioLabel = UILabel()
    private let interestsStackView = UIStackView()
    private let swipeIndicatorContainer = UIView()
    private let likeIndicator = UILabel()
    private let passIndicator = UILabel()
    private let superLikeIndicator = UILabel()
    
    // Gesture handling
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var originalCenter: CGPoint!
    private var isAnimating = false
    
    init(profile: Profile, delegate: CardViewDelegate) {
        self.profile = profile
        self.delegate = delegate
        super.init(frame: .zero)
        setupView()
        configure(with: profile)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = ModernColors.cardBackground
        layer.cornerRadius = 20
        layer.masksToBounds = true
        
        // Add modern shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 20
        layer.masksToBounds = false
        
        setupImageView()
        setupGradientOverlay()
        setupInfoContainer()
        setupSwipeIndicators()
        setupGestures()
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupGradientOverlay() {
        gradientOverlay.colors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        gradientOverlay.locations = [0.0, 0.5, 0.8, 1.0]
        gradientOverlay.startPoint = CGPoint(x: 0.5, y: 0)
        gradientOverlay.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientOverlay)
    }
    
    private func setupInfoContainer() {
        infoContainer.backgroundColor = .clear
        addSubview(infoContainer)
        
        infoContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(28)
            make.height.equalTo(160)
        }
        
        setupLabels()
        setupInterestsView()
    }
    
    private func setupLabels() {
        // Name label
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 1
        // 💡 Добавляем тень для лучшей читаемости
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        nameLabel.layer.shadowOpacity = 0.6
        nameLabel.layer.shadowRadius = 2.0
        
        // Age label
        ageLabel.font = .systemFont(ofSize: 24, weight: .medium)
        ageLabel.textColor = .white
        ageLabel.numberOfLines = 1
        // 💡 Добавляем тень для лучшей читаемости
        ageLabel.layer.shadowColor = UIColor.black.cgColor
        ageLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        ageLabel.layer.shadowOpacity = 0.6
        ageLabel.layer.shadowRadius = 2.0
        
        // Bio label
        bioLabel.font = .systemFont(ofSize: 16, weight: .regular)
        bioLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        bioLabel.numberOfLines = 3
        // 💡 Добавляем тень для лучшей читаемости
        bioLabel.layer.shadowColor = UIColor.black.cgColor
        bioLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        bioLabel.layer.shadowOpacity = 0.6
        bioLabel.layer.shadowRadius = 2.0
        
        [nameLabel, ageLabel, bioLabel].forEach { infoContainer.addSubview($0) }
        
        // Layout
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }
        
        ageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.lastBaseline.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
        
        bioLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(nameLabel.snp.bottom).offset(12)
        }
    }
    
    private func setupInterestsView() {
        interestsStackView.axis = .horizontal
        interestsStackView.spacing = 8
        interestsStackView.distribution = .fillProportionally
        infoContainer.addSubview(interestsStackView)
        
        interestsStackView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.top.equalTo(bioLabel.snp.bottom).offset(12)
        }
    }
    
    private func setupSwipeIndicators() {
        swipeIndicatorContainer.backgroundColor = .clear
        addSubview(swipeIndicatorContainer)
        
        swipeIndicatorContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Like indicator (right swipe)
        likeIndicator.text = "LIKE".localize()
        likeIndicator.font = .systemFont(ofSize: 48, weight: .black)
        likeIndicator.textColor = ModernColors.likeGreen
        likeIndicator.textAlignment = .center
        likeIndicator.layer.borderWidth = 4
        likeIndicator.layer.borderColor = ModernColors.likeGreen.cgColor
        likeIndicator.layer.cornerRadius = 8
        likeIndicator.alpha = 0
        likeIndicator.transform = CGAffineTransform(rotationAngle: -0.3)
        
        // Pass indicator (left swipe)
        passIndicator.text = "PASS".localize()
        passIndicator.font = .systemFont(ofSize: 48, weight: .black)
        passIndicator.textColor = ModernColors.passRed
        passIndicator.textAlignment = .center
        passIndicator.layer.borderWidth = 4
        passIndicator.layer.borderColor = ModernColors.passRed.cgColor
        passIndicator.layer.cornerRadius = 8
        passIndicator.alpha = 0
        passIndicator.transform = CGAffineTransform(rotationAngle: 0.3)
        
        // Super like indicator (up swipe)
        superLikeIndicator.text = "SUPERLIKE".localize()
        superLikeIndicator.font = .systemFont(ofSize: 32, weight: .black)
        superLikeIndicator.textColor = ModernColors.secondary
        superLikeIndicator.textAlignment = .center
        superLikeIndicator.numberOfLines = 2
        superLikeIndicator.layer.borderWidth = 4
        superLikeIndicator.layer.borderColor = ModernColors.secondary.cgColor
        superLikeIndicator.layer.cornerRadius = 8
        superLikeIndicator.alpha = 0
        
        [likeIndicator, passIndicator, superLikeIndicator].forEach { swipeIndicatorContainer.addSubview($0) }
        
        likeIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(60)
        }
        
        passIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.centerY.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(60)
        }
        
        superLikeIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.width.equalTo(200)
            make.height.equalTo(80)
        }
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGestureRecognizer)
        
        // Add tap gesture for info interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    private func configure(with profile: Profile) {
        imageView.image = UIImage(named: profile.imageName)
        nameLabel.text = profile.name
        ageLabel.text = String(profile.age)
        bioLabel.text = profile.bio
        
        setupInterestTags(profile.interests)
    }
    
    private func setupInterestTags(_ interests: [String]) {
        // Clear existing tags
        interestsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for interest in interests.prefix(3) { // Show max 3 interests
            let tagView = createInterestTag(text: interest)
            interestsStackView.addArrangedSubview(tagView)
        }
    }
    
    private func createInterestTag(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = ModernColors.glassMorphism
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        container.addSubview(blurView)
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        // 💡 Меняем цвет текста на темный для читаемости на светлом фоне
        label.textColor = ModernColors.textPrimary
        label.textAlignment = .center
        container.addSubview(label)
        
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(2)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        container.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        
        return container
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientOverlay.frame = bounds
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleTap(sender: UITapGestureRecognizer) {
        // Add subtle feedback animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
    
    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        guard !isAnimating, let superview = superview else { return }
        
        let translation = sender.translation(in: superview)
        let velocity = sender.velocity(in: superview)
        
        switch sender.state {
        case .began:
            originalCenter = center
            
        case .changed:
            handlePanChanged(translation: translation)
            
        case .ended:
            handlePanEnded(translation: translation, velocity: velocity)
            
        default:
            break
        }
    }
    
    private func handlePanChanged(translation: CGPoint) {
        // Update position
        center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y + translation.y)
        
        // Calculate rotation
        let rotationStrength = min(translation.x / frame.width, 1.0)
        let angle = rotationStrength * .pi / 8
        transform = CGAffineTransform(rotationAngle: angle)
        
        // Update swipe indicators
        updateSwipeIndicators(translation: translation)
    }
    
    private func updateSwipeIndicators(translation: CGPoint) {
        let threshold: CGFloat = 80
        
        // Right swipe - Like
        if translation.x > 0 {
            let alpha = min(translation.x / threshold, 1.0)
            likeIndicator.alpha = alpha
            passIndicator.alpha = 0
            superLikeIndicator.alpha = 0
        }
        // Left swipe - Pass
        else if translation.x < 0 {
            let alpha = min(abs(translation.x) / threshold, 1.0)
            passIndicator.alpha = alpha
            likeIndicator.alpha = 0
            superLikeIndicator.alpha = 0
        }
        
        // Up swipe - Super Like
        if translation.y < -50 {
            let alpha = min(abs(translation.y) / threshold, 1.0)
            superLikeIndicator.alpha = alpha
            if translation.x < 30 && translation.x > -30 {
                likeIndicator.alpha = 0
                passIndicator.alpha = 0
            }
        }
    }
    
    private func handlePanEnded(translation: CGPoint, velocity: CGPoint) {
        let swipeThreshold: CGFloat = 100
        let velocityThreshold: CGFloat = 1000
        
        // Determine swipe direction
        if translation.y < -swipeThreshold || velocity.y < -velocityThreshold {
            // Super like (up)
            animateSwipeOut(direction: 0)
            delegate?.cardSwiped(profile: profile, liked: true) // Super like counts as like
        } else if translation.x > swipeThreshold || velocity.x > velocityThreshold {
            // Like (right)
            animateSwipeOut(direction: 1)
            delegate?.cardSwiped(profile: profile, liked: true)
        } else if translation.x < -swipeThreshold || velocity.x < -velocityThreshold {
            // Pass (left)
            animateSwipeOut(direction: -1)
            delegate?.cardSwiped(profile: profile, liked: false)
        } else {
            // Return to center
            animateReturn()
        }
    }
    
    // MARK: - Animations
    
    func animateSwipeOut(direction: CGFloat) {
        guard let superview = superview else { return }
        isAnimating = true
        
        var finishPoint: CGPoint
        var finalRotation: CGFloat
        
        if direction == 0 {
            // Super like - animate up
            finishPoint = CGPoint(x: center.x, y: -superview.frame.height)
            finalRotation = 0
        } else {
            // Like/Pass - animate left or right
            finishPoint = CGPoint(x: superview.center.x + direction * superview.frame.width * 1.5, y: center.y + direction * 100)
            finalRotation = direction * .pi / 4
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8) {
            self.center = finishPoint
            self.transform = CGAffineTransform(rotationAngle: finalRotation)
            self.alpha = 0
            
            // Fade out indicators
            self.likeIndicator.alpha = 0
            self.passIndicator.alpha = 0
            self.superLikeIndicator.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    private func animateReturn() {
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6) {
            self.center = self.originalCenter
            self.transform = .identity
            
            // Fade out indicators
            self.likeIndicator.alpha = 0
            self.passIndicator.alpha = 0
            self.superLikeIndicator.alpha = 0
        }
    }
    
    // Add entrance animation
    func animateEntrance() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}
