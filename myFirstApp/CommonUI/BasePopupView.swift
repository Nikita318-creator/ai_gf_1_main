import UIKit
import SnapKit

class BasePopupView: UIView {
    
    enum BasePopupType {
        case dailyLimitReached
        case giftFromUs
        case onlyPremiumUserCanSentPhotos
        case needPremiumForAudio
    }
    
    // MARK: - UI Elements
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let rateButton = AnimatedButton(type: .system)
    private let laterButton = AnimatedButton(type: .system)
    
    // MARK: - Callbacks
    var onRateButtonTapped: (() -> Void)?
    var onLaterButtonTapped: (() -> Void)?
    
    let type: BasePopupType
    
    // MARK: - Initialization
    init(type: BasePopupType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Dimmed overlay background
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        addSubview(backgroundView)
        
        // Container
        containerView.backgroundColor = MyColors.cardBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = MyColors.separator.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        containerView.layer.shadowRadius = 16
        containerView.layer.shadowOpacity = 0.4
        addSubview(containerView)
        
        // Dynamic Icon & Localized Texts
        let (iconName, title, message, okButtonText, laterText) = configureContent(for: type)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .semibold)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: iconConfig)
        iconImageView.tintColor = MyColors.primary
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        // Title
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        // Message
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = MyColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        containerView.addSubview(messageLabel)
        
        // Buttons Stack View
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 12
        containerView.addSubview(buttonsStackView)
        
        // Action Button (Primary)
        rateButton.setTitle(okButtonText, for: .normal)
        rateButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        rateButton.setTitleColor(MyColors.textPrimary, for: .normal)
        rateButton.backgroundColor = MyColors.primary
        rateButton.layer.cornerRadius = 14
        rateButton.titleLabel?.adjustsFontSizeToFitWidth = true
        rateButton.titleLabel?.minimumScaleFactor = 0.6
        
        // Secondary / Cancel Button
        laterButton.setTitle(laterText, for: .normal)
        laterButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        laterButton.setTitleColor(MyColors.textSecondary, for: .normal)
        laterButton.backgroundColor = MyColors.messageBackground
        laterButton.layer.cornerRadius = 14
        laterButton.layer.borderWidth = 1
        laterButton.layer.borderColor = MyColors.separator.cgColor
        laterButton.titleLabel?.adjustsFontSizeToFitWidth = true
        laterButton.titleLabel?.minimumScaleFactor = 0.6
        
        buttonsStackView.addArrangedSubview(laterButton)
        buttonsStackView.addArrangedSubview(rateButton)
    }
    
    private func configureContent(for type: BasePopupType) -> (icon: String, title: String, message: String, okText: String, laterText: String) {
        switch type {
        case .dailyLimitReached:
            return (
                "hourglass.circle.fill",
                "Popup_DailyLimit_Title".localize(),
                "Popup_DailyLimit_Message".localize(),
                "Popup_Limit_Action".localize(),
                "Popup_OK".localize()
            )
        case .giftFromUs:
            return (
                "gift.circle.fill",
                "Popup_Gift_Title".localize(),
                "Popup_Gift_Message".localize(),
                "Popup_Gift_Action".localize(),
                "OK".localize()
            )
        case .onlyPremiumUserCanSentPhotos:
            return (
                "photo.circle.fill",
                "Popup_PhotosLimit_Title".localize(),
                "Popup_PhotosLimit_Message".localize(),
                "Popup_Limit_Action".localize(),
                "Popup_OK".localize()
            )
        case .needPremiumForAudio:
            return (
                "waveform.circle.fill",
                "Popup_AudioLimit_Title".localize(),
                "Popup_AudioLimit_Message".localize(),
                "Popup_Limit_Action".localize(),
                "Popup_OK".localize()
            )
        }
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(28)
            make.trailing.lessThanOrEqualToSuperview().offset(-28)
            make.width.lessThanOrEqualTo(340)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        buttonsStackView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(48)
        }
    }
    
    private func setupActions() {
        rateButton.addTarget(self, action: #selector(rateButtonTapped), for: .touchUpInside)
        laterButton.addTarget(self, action: #selector(laterButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func rateButtonTapped() {
        dismiss { [weak self] in
            self?.onRateButtonTapped?()
        }
    }
    
    @objc private func laterButtonTapped() {
        dismiss { [weak self] in
            self?.onLaterButtonTapped?()
        }
    }
    
    @objc private func backgroundTapped() {
        // Опционально: можно раскомментировать, если нужно закрывать по тапу на фон
        // laterButtonTapped()
    }
    
    // MARK: - Public Presentation Methods
    func show(in parentView: UIView) {
        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
