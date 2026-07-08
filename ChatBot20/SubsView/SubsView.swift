import UIKit
import SnapKit
//import OneSignalFramework

class SubsView: UIView {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let benefitsLabel = UILabel()
//    private let specialOfferLabel = UILabel()
    private let plansStackView = UIStackView()
    private let weeklyPlanView = SubscriptionPlanView()
    private let yearlyPlanView = SubscriptionPlanView()
    private let continueButton = UIButton()
    private let bestValueBadge = UIView()
    private let bestValueLabel = UILabel()
    let closeButton = UIButton()
    private let termsOfUseButton = UIButton()
    private let privacyPolicyButton = UIButton()
    private let restorePurchaseButton = UIButton()
    private let trialInfoLabel = UILabel()
    private let cancelAnyTimeLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var selectedPlanType: PlanType = .yearly
    
    enum PlanType {
        case weekly
        case yearly
    }
    
    enum Constants {
        static let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        static let privacyUrl = "https://sites.google.com/view/aicgprivacy"
        static let appStoreUrl = "https://apps.apple.com/app/id6748720543"
    }
    
    weak var vc: UIViewController?
    let isOnboarding: Bool
    var purchasedHandler: (() -> Void)?
    var onPaywallClosedHandler: (() -> Void)?
    
    // MARK: - Initializer
    init(isOnboarding: Bool = false) {
        self.isOnboarding = isOnboarding
        super.init(frame: .zero)
        
        weeklyPlanView.isOnboarding = isOnboarding
        yearlyPlanView.isOnboarding = isOnboarding
        setupViews()
        setupConstraints()
        updatePlanSelection(.yearly)
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        // Основной фон с градиентом
        backgroundColor = UIColor(hex: "#1A1A1A")
        layer.cornerRadius = 20
        clipsToBounds = true
        
        setupBackgroundGradient()
        
        // ScrollView
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        addSubview(scrollView)
        
        // ContentView
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        // Header с тонким блюром
        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        headerView.layer.cornerRadius = 20
        contentView.addSubview(headerView)
        
        // Close Button - минималистичный
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        contentView.addSubview(closeButton)
        
        // Icon Image - больший размер и лучший дизайн
        let localeID = Locale(identifier: Locale.preferredLanguages.first ?? "en-US").identifier

        let actualImageName: String
        if GEOService.shared.isAsionGeo {
            actualImageName = "asion22"
        } else if localeID.range(of: "^ar", options: .regularExpression) != nil {
            actualImageName = "arab12"
        } else {
            actualImageName = "10"
        }
        
        iconImageView.image = UIImage(named: actualImageName)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 40
        iconImageView.layer.borderWidth = 3
        iconImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        contentView.addSubview(iconImageView)
        
        // Title Label - более выразительный
        titleLabel.text = "Subs.Title".localize()
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        contentView.addSubview(titleLabel)
        
        // Subtitle Label - убираем или делаем очень краткой
        subtitleLabel.text = "Subs.UnlockPremiumFeatures".localize()
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(subtitleLabel)
        
        // Benefits - ключевые преимущества простым текстом
        setupBenefitsLabel()
        contentView.addSubview(benefitsLabel)

//        specialOfferLabel.isHidden = true
//        contentView.addSubview(specialOfferLabel)
//        if !isOnboarding {
//            subtitleLabel.isHidden = true
//            setupSpecialOfferLabel()
//        }
        
//        if ConfigService.shared.needAlwaysProSubs || !ConfigService.shared.isProSubs {
//            specialOfferLabel.isHidden = true
//            subtitleLabel.isHidden = false
//        }
            
        // Plans Stack View
        plansStackView.axis = .horizontal
        plansStackView.distribution = .fillEqually
        plansStackView.spacing = 12
        contentView.addSubview(plansStackView)
        
        // Setup Subscription Plan Views
        setupPlanView(weeklyPlanView, title: "Subs.week".localize(), action: #selector(weeklyButtonTapped))
        setupPlanView(yearlyPlanView, title: "Subs.year".localize(), action: #selector(yearlyButtonTapped))
        
        plansStackView.addArrangedSubview(weeklyPlanView)
        plansStackView.addArrangedSubview(yearlyPlanView)
        
        // Best Value Badge - более заметный
        setupBestValueBadge()
        contentView.addSubview(bestValueBadge)
        
        // Trial Info Label - важная информация о пробном периоде
        trialInfoLabel.isHidden = true
        trialInfoLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        trialInfoLabel.textAlignment = .center
        trialInfoLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        trialInfoLabel.numberOfLines = 0
        contentView.addSubview(trialInfoLabel)
        
        cancelAnyTimeLabel.numberOfLines = 3
        cancelAnyTimeLabel.textColor = UIColor(hex: "#A0A0A0")
        cancelAnyTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        contentView.addSubview(cancelAnyTimeLabel)

        
        // Continue Button - более привлекательный
        setupContinueButton()
        addSubview(continueButton)
        
        // Bottom buttons - компактнее
        setupBottomButtons()
        
        yearlyButtonTapped()
        
        addSubview(loadingIndicator)
    }
    
    private func setupBackgroundGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: "#2C2C2E").cgColor,
            UIColor(hex: "#1A1A1A").cgColor,
            UIColor(hex: "#000000").cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupBenefitsLabel() {
        let benefits = [
            "Subs.features1".localize(),
            "Subs.features2".localize(),
            "Subs.features3".localize(),
            "Subs.features4".localize(),
            "Subs.features5".localize()
        ]
        
        let attributedText = NSMutableAttributedString()
        let benefitsLabelfontSize: CGFloat = isCurrentDeviceiPad() ? 25 : 15
        for (index, benefit) in benefits.enumerated() {
            let benefitText = NSAttributedString(
                string: benefit + (index < benefits.count - 1 ? "  •  " : ""),
                attributes: [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                    .font: UIFont.systemFont(ofSize: benefitsLabelfontSize, weight: .medium)
                ]
            )
            attributedText.append(benefitText)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        
        benefitsLabel.attributedText = attributedText
        benefitsLabel.numberOfLines = 0
        benefitsLabel.textAlignment = .center
    }

    // MARK: - Новый метод для настройки акционного текста
//    private func setupSpecialOfferLabel() {
//        specialOfferLabel.text = "specialOffer.text".localize()
//        specialOfferLabel.textAlignment = .center
//        specialOfferLabel.numberOfLines = 0
//        specialOfferLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
//        specialOfferLabel.textColor = .white
//
//        let attributedString = NSMutableAttributedString(string: specialOfferLabel.text!)
//        let range = (specialOfferLabel.text! as NSString).range(of: "specialOffer.highlighted.text".localize())
//
//        attributedString.addAttribute(.foregroundColor, value: UIColor(hex: "#FFC107"), range: range)
//        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 22, weight: .heavy), range: range)
//        
//        specialOfferLabel.attributedText = attributedString
//
//        specialOfferLabel.layer.shadowColor = UIColor(hex: "#FFC107").cgColor
//        specialOfferLabel.layer.shadowOffset = .zero
//        specialOfferLabel.layer.shadowRadius = 8
//        specialOfferLabel.layer.shadowOpacity = 1.0
//        specialOfferLabel.isHidden = false
//    }
    
    private func setupBestValueBadge() {
        // Более яркий и заметный badge
        bestValueBadge.backgroundColor = UIColor(hex: "#FF6B35")
        bestValueBadge.layer.cornerRadius = 12
        
        // Добавляем небольшое свечение
        bestValueBadge.layer.shadowColor = UIColor(hex: "#FF6B35").cgColor
        bestValueBadge.layer.shadowOffset = CGSize(width: 0, height: 0)
        bestValueBadge.layer.shadowRadius = 8
        bestValueBadge.layer.shadowOpacity = 0.6
        
        bestValueLabel.text = "Subs.BESTVALUE".localize()
        bestValueLabel.textColor = .white
        bestValueLabel.font = UIFont.systemFont(ofSize: 11, weight: .black)
        bestValueLabel.textAlignment = .center
        
        bestValueBadge.addSubview(bestValueLabel)
        bestValueLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
    }
    
    private func setupContinueButton() {
        continueButton.backgroundColor = UIColor(hex: "#007AFF")
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        continueButton.layer.cornerRadius = 16
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        
        // Простая тень без градиентов
        continueButton.layer.shadowColor = UIColor(hex: "#007AFF").cgColor
        continueButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        continueButton.layer.shadowRadius = 12
        continueButton.layer.shadowOpacity = 0.4
    }
    
    private func setupPlanView(_ planView: SubscriptionPlanView, title: String, action: Selector) {
        planView.setTitle(title)
        planView.layer.cornerRadius = 16
        planView.layer.borderWidth = 1
        planView.layer.borderColor = UIColor(hex: "#3A3A3A").cgColor
        planView.backgroundColor = UIColor(hex: "#2A2A2A")
        planView.layer.shadowColor = UIColor.black.cgColor
        planView.layer.shadowOffset = CGSize(width: 0, height: 2)
        planView.layer.shadowRadius = 4
        planView.layer.shadowOpacity = 0.2
        
        planView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        planView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupBottomButtons() {
        termsOfUseButton.setTitle("Subs.TermsOfUse".localize(), for: .normal)
        termsOfUseButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        termsOfUseButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        termsOfUseButton.addTarget(self, action: #selector(termsOfUseTapped), for: .touchUpInside)
        addSubview(termsOfUseButton)
        
        privacyPolicyButton.setTitle("Subs.PrivacyPolicy".localize(), for: .normal)
        privacyPolicyButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        privacyPolicyButton.addTarget(self, action: #selector(privacyPolicyTapped), for: .touchUpInside)
        addSubview(privacyPolicyButton)
        
        restorePurchaseButton.setTitle("Subs.Restore".localize(), for: .normal)
        restorePurchaseButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        restorePurchaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        restorePurchaseButton.addTarget(self, action: #selector(restorePurchaseTapped), for: .touchUpInside)
        addSubview(restorePurchaseButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Обновляем background gradient
        if let gradientLayer = layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bounds
        }
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // ScrollView
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).offset(-20)
        }
        
        // ContentView
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
            make.height.greaterThanOrEqualTo(scrollView)
        }
        
        // Header View
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        // Close Button
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(32)
        }
        
        // Icon Image - больше и центральнее
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(180)
        }
        
        // Title Label
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-32)
        }
        
        // Subtitle Label
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-32)
        }
        
//        specialOfferLabel.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).offset(8)
//            make.leading.equalToSuperview().offset(32)
//            make.trailing.equalToSuperview().offset(-32)
//        }
        
        // Benefits Label
        benefitsLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
//            if isOnboarding || specialOfferLabel.isHidden {
//                make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
//            } else {
//                make.top.equalTo(specialOfferLabel.snp.bottom).offset(32)
//            }
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        // Plans Stack View - больше места
        plansStackView.snp.makeConstraints { make in
            make.top.equalTo(benefitsLabel.snp.bottom).offset(40)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(100)
        }
        
        // Best Value Badge
        bestValueBadge.snp.makeConstraints { make in
            make.bottom.equalTo(yearlyPlanView.snp.top).offset(8)
            make.centerX.equalTo(yearlyPlanView)
        }
        
        // Trial Info Label
        trialInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(plansStackView.snp.bottom).offset(0)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-32)
        }
        
        cancelAnyTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(trialInfoLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-32)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        // Continue Button
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(termsOfUseButton.snp.top).offset(-20).priority(.low)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(56)
        }
        
        // Bottom buttons - в одну строку
        privacyPolicyButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            make.centerX.equalToSuperview()
        }
        
        termsOfUseButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            make.trailing.equalTo(privacyPolicyButton.snp.leading).offset(-24)
        }
        
        restorePurchaseButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            make.leading.equalTo(privacyPolicyButton.snp.trailing).offset(24)
        }
    }
    
    // MARK: - Button Actions
        
    private func onPaywallClosed() {
        onPaywallClosedHandler?()
        removeFromSuperview()
    }
    
    @objc private func closeButtonTapped() {
        onPaywallClosed()
    }
    
    @objc private func weeklyButtonTapped() {
        let currentProductId: String
        if ConfigService.shared.isUSHaveDifferentPrice {
            currentProductId = SubsIDs.weekly2025last
        } else {
            currentProductId = (ConfigService.shared.isProSubs && isOnboarding) || ConfigService.shared.needAlwaysProSubs ? SubsIDs.weeklyPRO : SubsIDs.weeklySpecial
        }

        if let product = IAPService.shared.products.first(where: { $0.productId == currentProductId }) {
            let priceString = product.skProduct?.localizedPrice() ?? ""
            weeklyPlanView.setTitle("Subs.week".localize())
            yearlyPlanView.setTitle("Subs.month".localize())
            trialInfoLabel.text = "Subs.Price.week".localize(attribut: "Subs.Price.week", arguments: priceString)
            continueButton.setTitle("Continue".localize(), for: .normal)
            
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            
            updatePlanSelection(.weekly)
        }
    }
    
    @objc func yearlyButtonTapped() {
        let currentProductId: String
        if ConfigService.shared.isUSHaveDifferentPrice {
            currentProductId = SubsIDs.monthly2025last
        } else {
            currentProductId = (ConfigService.shared.isProSubs && isOnboarding) || ConfigService.shared.needAlwaysProSubs ? SubsIDs.monthlyPRO : SubsIDs.monthlySpecial
        }

        if let product = IAPService.shared.products.first(where: { $0.productId == currentProductId }) {
            let priceString = product.skProduct?.localizedPrice() ?? ""
            weeklyPlanView.setTitle("Subs.week".localize())
            yearlyPlanView.setTitle("Subs.month".localize())
            trialInfoLabel.text = "Subs.Price.year".localize(attribut: "Subs.Price.year".localize(), arguments: priceString)
            let attributedText = NSMutableAttributedString(string: "Subs.CancelAnytime".localize())
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineSpacing = 4
            attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
            cancelAnyTimeLabel.attributedText = attributedText
            continueButton.setTitle("Continue".localize(), for: .normal)
                            
            updatePlanSelection(.yearly)
        }
    }
    
    @objc private func continueTapped() {
        let productIdentifier: String
        switch selectedPlanType {
        case .weekly:
            if ConfigService.shared.isUSHaveDifferentPrice {
                productIdentifier = SubsIDs.weekly2025last
            } else {
                productIdentifier = (ConfigService.shared.isProSubs && isOnboarding) || ConfigService.shared.needAlwaysProSubs ? SubsIDs.weeklyPRO : SubsIDs.weeklySpecial
            }
        case .yearly:
            if ConfigService.shared.isUSHaveDifferentPrice {
                productIdentifier = SubsIDs.monthly2025last
            } else {
                productIdentifier = (ConfigService.shared.isProSubs && isOnboarding) || ConfigService.shared.needAlwaysProSubs ? SubsIDs.monthlyPRO : SubsIDs.monthlySpecial
            }
        }
        
        continueButton.alpha = 0.8
        UIView.animate(withDuration: 0.15) {
            self.continueButton.alpha = 1.0
        }
        
        purchaseSubsInAppStore(productIdentifier: productIdentifier)
    }
    
    @objc private func termsOfUseTapped() {
        if let url = URL(string: Constants.termsOfUseUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func privacyPolicyTapped() {
        if let url = URL(string: Constants.privacyUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func restorePurchaseTapped() {
        IAPService.shared.restorePurchases() { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed: break
                case .purchased, .restored:
//                    OneSignal.User.addTag(key: "hasActiveSubscription", value: "\(IAPService.shared.hasActiveSubscription)")
//                    OneSignal.User.addTag(key: "hasActiveSubscription", value: "true")
                    
                    self.onPaywallClosed()
                }
            }
        }
    }
    
    private func updatePlanSelection(_ planType: PlanType) {
        selectedPlanType = planType
        weeklyPlanView.setSelected(planType == .weekly)
        yearlyPlanView.setSelected(planType == .yearly)
        
        // Простое обновление видимости badge без анимаций
        bestValueBadge.isHidden = planType != .yearly
        
        // Обновляем цвет кнопки в зависимости от выбранного плана
        let buttonColor = planType == .yearly ? UIColor(hex: "#34C759") : UIColor(hex: "#007AFF")
        continueButton.backgroundColor = buttonColor
        continueButton.layer.shadowColor = buttonColor.cgColor
    }
}

extension SubsView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .bold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        trialInfoLabel.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        cancelAnyTimeLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        bestValueLabel.font = UIFont.systemFont(ofSize: 21, weight: .black)

        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        termsOfUseButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        restorePurchaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        closeButton.layer.cornerRadius = 24

        let smallerSide = UIScreen.main.bounds.height < UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        iconImageView.snp.updateConstraints { make in
            make.width.height.equalTo(smallerSide / 2)
        }
        
        continueButton.snp.updateConstraints { make in
            make.height.equalTo(76)
        }
        
        plansStackView.snp.updateConstraints { make in
            make.height.equalTo(170)
        }
        
        closeButton.snp.updateConstraints { make in
            make.width.height.equalTo(48)
        }
        
        layoutIfNeeded()
    }
    
    func scrollToBottom(animated: Bool = true) {
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        scrollView.setContentOffset(bottomOffset, animated: animated)
    }
    
    func showLoadingIndicator() {
        loadingIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
    }
    
    private func purchaseSubsInAppStore(productIdentifier: String) {
        showLoadingIndicator()
        
        IAPService.shared.purchase(productId: productIdentifier) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed:
                    self?.hideLoadingIndicator()
                case .purchased, .restored:
//                    OneSignal.User.addTag(key: "hasActiveSubscription", value: "\(IAPService.shared.hasActiveSubscription)")
//                    OneSignal.User.addTag(key: "hasActiveSubscription", value: "true")
                    UserDefaults.standard.set(false, forKey: MainHelper.shared.needShowTrialPayWallKey)
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyPush"])
                    
                    // фиксим баг что после оплаты подписки нужно перезайти в чат:
                    MainHelper.shared.isCurrentAssistantPremium = false
                    
                    let productPlanID: String
                    switch productIdentifier {
                    case SubsIDs.weeklyPRO:
                        productPlanID = "weeklyPRO"
                    case SubsIDs.monthlyPRO:
                        productPlanID = "monthlyPRO"
//                    case SubsIDs.yearlyOld:
//                        productPlanID = "trial"
                    case SubsIDs.monthlySpecial:
                        productPlanID = "monthly"
                    case SubsIDs.weeklySpecial:
                        productPlanID = "weekly"
                    case SubsIDs.weekly2025last:
                        productPlanID = "weeklyDiffUS"
                    case SubsIDs.monthly2025last:
                        productPlanID = "monthlyDiffUS"
                    default:
                        productPlanID = "unknown ???"
                    }
                    
                    WebHookAnaliticksService.shared.sendErrorReport(messageText: "💵💸 PURCHASED!!! \(productPlanID) \((self?.isOnboarding ?? false) ? "from Onboarding" : "from limits") for user: \(WebHookAnaliticksService.shared.randomID) + \(Locale.preferredLanguages.first ?? "en-US")")
                    self?.purchasedHandler?()
                    self?.hideLoadingIndicator()
                    self?.onPaywallClosed()
                }
            }
        }
    }
}
