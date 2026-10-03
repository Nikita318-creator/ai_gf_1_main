import UIKit
import SnapKit

final class PaywallView: UIView {
    
    enum Constants {
        static let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
        static let privacyUrl = "https://sites.google.com/view/privacymyfirstapp"
    }
    
    // MARK: - Properties
    
    var purchasedHandler: (() -> Void)?
    var onPaywallClosed: (() -> Void)?
    
    private var selectedProductId: String = StoreIDs.yearly {
        didSet {
            updateSelectionState()
        }
    }
    
    // MARK: - UI Elements
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // Добавьте фоновое изображение в Assets (например, "paywall_bg")
        imageView.image = UIImage(named: "firstFoto_")
        return imageView
    }()
    
    private let gradientOverlayView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 18
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Meet Your AI Soulmate"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Unlimited chats, voice messages & exclusive photos"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // Cards
    private let weeklyCard = SubscriptionCardView(
        title: "Weekly Plan",
        badgeText: nil
    )
    
    private let yearlyCard = SubscriptionCardView(
        title: "Yearly Plan",
        badgeText: "BEST VALUE"
    )
    
    private lazy var cardsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [weeklyCard, yearlyCard])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .white
        button.layer.cornerRadius = 26
        return button
    }()
    
    // Bottom Bar (Restore / Terms / Privacy)
    private let restoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Restore", for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        return button
    }()
    
    private let termsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Terms of Use", for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        return button
    }()
    
    private let privacyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Privacy Policy", for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        return button
    }()
    
    private lazy var bottomLinksStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [termsButton, restoreButton, privacyButton])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
        configurePrices()
        updateSelectionState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradientOverlay()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .black
        
        addSubview(backgroundImageView)
        addSubview(gradientOverlayView)
        addSubview(closeButton)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(cardsStackView)
        addSubview(continueButton)
        addSubview(bottomLinksStackView)
        addSubview(loadingIndicator)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        gradientOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(36)
        }
        
        bottomLinksStackView.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(12)
            make.centerX.equalToSuperview()
        }
        
        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(bottomLinksStackView.snp.top).offset(-16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(54)
        }
        
        cardsStackView.snp.makeConstraints { make in
            make.bottom.equalTo(continueButton.snp.top).offset(-24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        weeklyCard.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(cardsStackView.snp.top).offset(-24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(subtitleLabel.snp.top).offset(-8)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restorePurchaseTapped), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)
        
        weeklyCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(weeklyCardTapped)))
        yearlyCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(yearlyCardTapped)))
    }
    
    private func applyGradientOverlay() {
        gradientOverlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let gradient = CAGradientLayer()
        gradient.frame = gradientOverlayView.bounds
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0.95).cgColor
        ]
        gradient.locations = [0.0, 0.4, 1.0]
        gradientOverlayView.layer.addSublayer(gradient)
    }
    
    // MARK: - Price Fetching
    
    private func configurePrices() {
        let weeklyPrice = getPrice(for: StoreIDs.weekly) ?? "--"
        let yearlyPrice = getPrice(for: StoreIDs.yearly) ?? "--"
        
        weeklyCard.setPrice("\(weeklyPrice) / week")
        yearlyCard.setPrice("\(yearlyPrice) / year")
    }
    
    private func getPrice(for currentProductId: String) -> String? {
        if let product = SubscriptionManager.shared.products.first(where: { $0.productId == currentProductId }) {
            return product.skProduct?.localizedPrice()
        }
        return nil
    }
    
    // MARK: - Selection State
    
    private func updateSelectionState() {
        weeklyCard.setSelected(selectedProductId == StoreIDs.weekly)
        yearlyCard.setSelected(selectedProductId == StoreIDs.yearly)
    }
    
    // MARK: - User Actions
    
    @objc private func weeklyCardTapped() {
        selectedProductId = StoreIDs.weekly
    }
    
    @objc private func yearlyCardTapped() {
        selectedProductId = StoreIDs.yearly
    }
    
    @objc private func closeTapped() {
        onPaywallClosed?()
    }
    
    @objc private func continueTapped() {
        purchaseSubsInAppStore(productIdentifier: selectedProductId)
    }
    
    @objc private func termsTapped() {
        openUrl(Constants.termsOfUseUrl)
    }
    
    @objc private func privacyTapped() {
        openUrl(Constants.privacyUrl)
    }
    
    private func openUrl(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Purchases & Restore
    
    private func purchaseSubsInAppStore(productIdentifier: String) {
        showLoadingIndicator()
        
        SubscriptionManager.shared.purchase(productId: productIdentifier) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed:
                    self?.hideLoadingIndicator()
                case .purchased, .restored:
                    self?.purchasedHandler?()
                    self?.hideLoadingIndicator()
                    self?.onPaywallClosed?()
                }
            }
        }
    }
    
    @objc private func restorePurchaseTapped() {
        showLoadingIndicator()
        
        SubscriptionManager.shared.restorePurchases() { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()
                switch result {
                case .failed: break
                case .purchased, .restored:
                    self?.onPaywallClosed?()
                }
            }
        }
    }
    
    // MARK: - Loading Indicator
    
    private func showLoadingIndicator() {
        loadingIndicator.startAnimating()
        isUserInteractionEnabled = false
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
        isUserInteractionEnabled = true
    }
}

// MARK: - Helper SubscriptionCardView

private final class SubscriptionCardView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = .black
        label.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Gold
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, priceLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()
    
    init(title: String, badgeText: String?) {
        super.init(frame: .zero)
        titleLabel.text = title
        
        if let badgeText = badgeText {
            badgeLabel.text = "  \(badgeText)  "
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.12)
        layer.cornerRadius = 16
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
        
        addSubview(textStackView)
        addSubview(badgeLabel)
        
        textStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
    }
    
    func setPrice(_ price: String) {
        priceLabel.text = price
    }
    
    func setSelected(_ isSelected: Bool) {
        if isSelected {
            layer.borderColor = UIColor.systemPink.cgColor
            backgroundColor = UIColor.systemPink.withAlphaComponent(0.2)
        } else {
            layer.borderColor = UIColor.clear.cgColor
            backgroundColor = UIColor.white.withAlphaComponent(0.12)
        }
    }
}
