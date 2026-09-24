import UIKit
import SnapKit

class SearchAIGFFeatureCardView: UIView {
    
    weak var delegate: CardViewDelegate?
    private let profile: AIGFProfileModel
    
    // MARK: - UI Elements
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
    
    // MARK: - Gesture handling
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var originalCenter: CGPoint = .zero
    private var isAnimating = false
    
    private var isRTL: Bool {
        return effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    // MARK: - Initializer
    init(profile: AIGFProfileModel, delegate: CardViewDelegate) {
        self.profile = profile
        self.delegate = delegate
        super.init(frame: .zero)
        setupView()
        configure(with: profile)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = MyColors.cardBackground
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = MyColors.separator.cgColor
        
        // Shadow Effect
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.25
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
        imageView.layer.cornerRadius = 24
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupGradientOverlay() {
        gradientOverlay.colors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            MyColors.background.withAlphaComponent(0.4).cgColor,
            MyColors.background.withAlphaComponent(0.85).cgColor
        ]
        gradientOverlay.locations = [0.0, 0.45, 0.75, 1.0]
        gradientOverlay.startPoint = CGPoint(x: 0.5, y: 0)
        gradientOverlay.endPoint = CGPoint(x: 0.5, y: 1)
        gradientOverlay.cornerRadius = 24
        imageView.layer.addSublayer(gradientOverlay)
    }
    
    private func setupInfoContainer() {
        infoContainer.backgroundColor = .clear
        addSubview(infoContainer)
        
        infoContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(24)
        }
        
        setupLabels()
        setupInterestsView()
    }
    
    private func setupLabels() {
        // Name label
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = MyColors.textPrimary
        nameLabel.numberOfLines = 1
        nameLabel.layer.shadowColor = UIColor.black.cgColor
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        nameLabel.layer.shadowOpacity = 0.8
        nameLabel.layer.shadowRadius = 3.0
        
        // Age label
        ageLabel.font = .systemFont(ofSize: 24, weight: .medium)
        ageLabel.textColor = MyColors.textSecondary
        ageLabel.numberOfLines = 1
        ageLabel.layer.shadowColor = UIColor.black.cgColor
        ageLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        ageLabel.layer.shadowOpacity = 0.8
        ageLabel.layer.shadowRadius = 3.0
        
        // Bio label
        bioLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bioLabel.textColor = MyColors.textPrimary.withAlphaComponent(0.9)
        bioLabel.numberOfLines = 3
        bioLabel.layer.shadowColor = UIColor.black.cgColor
        bioLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        bioLabel.layer.shadowOpacity = 0.8
        bioLabel.layer.shadowRadius = 3.0
        
        [nameLabel, ageLabel, bioLabel].forEach { infoContainer.addSubview($0) }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(8)
        }
        
        ageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.lastBaseline.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
        
        bioLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
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
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupSwipeIndicators() {
        swipeIndicatorContainer.backgroundColor = .clear
        swipeIndicatorContainer.isUserInteractionEnabled = false
        addSubview(swipeIndicatorContainer)
        
        swipeIndicatorContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Like indicator (right swipe)
        configureIndicator(likeIndicator, text: "LIKE".localize(), color: MyColors.primary, rotation: -0.2)
        
        // Pass indicator (left swipe)
        configureIndicator(passIndicator, text: "PASS".localize(), color: MyColors.accentRed, rotation: 0.2)
        
        // Super like indicator (up swipe)
        configureIndicator(superLikeIndicator, text: "SUPER LIKE".localize(), color: MyColors.link, rotation: 0)
        
        [likeIndicator, passIndicator, superLikeIndicator].forEach { swipeIndicatorContainer.addSubview($0) }
        
        likeIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-30)
            make.top.equalToSuperview().offset(40)
            make.width.equalTo(130)
            make.height.equalTo(52)
        }
        
        passIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.top.equalToSuperview().offset(40)
            make.width.equalTo(130)
            make.height.equalTo(52)
        }
        
        superLikeIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(60)
            make.width.equalTo(180)
            make.height.equalTo(52)
        }
    }
    
    private func configureIndicator(_ label: UILabel, text: String, color: UIColor, rotation: CGFloat) {
        label.text = text
        label.font = .systemFont(ofSize: 28, weight: .black)
        label.textColor = color
        label.textAlignment = .center
        label.layer.borderWidth = 3
        label.layer.borderColor = color.cgColor
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.backgroundColor = MyColors.background.withAlphaComponent(0.4)
        label.alpha = 0
        label.transform = CGAffineTransform(rotationAngle: rotation)
    }
    
    private func setupGestures() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGestureRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    private func configure(with profile: AIGFProfileModel) {
        imageView.image = UIImage(named: profile.imageName)
        nameLabel.text = profile.name
        ageLabel.text = String(profile.age)
        bioLabel.text = profile.bio
        
        setupInterestTags(profile.interests)
    }
    
    private func setupInterestTags(_ interests: [String]) {
        interestsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for interest in interests.prefix(3) {
            let tagView = createInterestTag(text: interest)
            interestsStackView.addArrangedSubview(tagView)
        }
    }
    
    private func createInterestTag(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.7)
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.layer.borderColor = MyColors.separator.cgColor
        container.clipsToBounds = true
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        container.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        
        container.snp.makeConstraints { make in
            make.height.equalTo(26)
        }
        
        return container
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientOverlay.frame = bounds
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleTap(sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.12, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.12) {
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
        center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y + translation.y)
        
        // Поворот карточки следует за физическим пальцем
        let rotationStrength = min(translation.x / frame.width, 1.0)
        let angle = rotationStrength * .pi / 8
        transform = CGAffineTransform(rotationAngle: angle)
        
        updateSwipeIndicators(translation: translation)
    }

    private func updateSwipeIndicators(translation: CGPoint) {
        let threshold: CGFloat = 80
        // effectiveX > 0 означает свайп в сторону LIKE (вправо для LTR, влево для RTL)
        let effectiveX = isRTL ? -translation.x : translation.x
        
        if effectiveX > 0 {
            let alpha = min(effectiveX / threshold, 1.0)
            likeIndicator.alpha = alpha
            passIndicator.alpha = 0
            superLikeIndicator.alpha = 0
        } else if effectiveX < 0 {
            let alpha = min(abs(effectiveX) / threshold, 1.0)
            passIndicator.alpha = alpha
            likeIndicator.alpha = 0
            superLikeIndicator.alpha = 0
        }
        
        if translation.y < -50 {
            let alpha = min(abs(translation.y) / threshold, 1.0)
            superLikeIndicator.alpha = alpha
            if abs(translation.x) < 30 {
                likeIndicator.alpha = 0
                passIndicator.alpha = 0
            }
        }
    }

    private func handlePanEnded(translation: CGPoint, velocity: CGPoint) {
        let swipeThreshold: CGFloat = 100
        let velocityThreshold: CGFloat = 1000
        
        // Приводим все к единому визуальному вектору
        let effectiveX = isRTL ? -translation.x : translation.x
        let effectiveVelocityX = isRTL ? -velocity.x : velocity.x
        
        if translation.y < -swipeThreshold || velocity.y < -velocityThreshold {
            // Super Like / Up
            animateSwipeOut(direction: 0)
            delegate?.cardSwiped(profile: profile, liked: true)
        } else if effectiveX > swipeThreshold || effectiveVelocityX > velocityThreshold {
            // Физический улет карточки по X направления движения пальца
            let physicalDirection: CGFloat = translation.x > 0 ? 1 : -1
            animateSwipeOut(direction: physicalDirection)
            
            // Визуально смахнули в сторону LIKE (Heart)
            delegate?.cardSwiped(profile: profile, liked: true)
        } else if effectiveX < -swipeThreshold || effectiveVelocityX < -velocityThreshold {
            // Физический улет карточки по X направления движения пальца
            let physicalDirection: CGFloat = translation.x > 0 ? 1 : -1
            animateSwipeOut(direction: physicalDirection)
            
            // Визуально смахнули в сторону PASS (Cross)
            delegate?.cardSwiped(profile: profile, liked: false)
        } else {
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
            finishPoint = CGPoint(x: center.x, y: -superview.frame.height)
            finalRotation = 0
        } else {
            finishPoint = CGPoint(x: superview.center.x + direction * superview.frame.width * 1.5, y: center.y + direction * 100)
            finalRotation = direction * .pi / 4
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8) {
            self.center = finishPoint
            self.transform = CGAffineTransform(rotationAngle: finalRotation)
            self.alpha = 0
            
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
            
            self.likeIndicator.alpha = 0
            self.passIndicator.alpha = 0
            self.superLikeIndicator.alpha = 0
        }
    }
    
    func animateEntrance() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}
