import UIKit

final class BasePopupView: UIView {
    
    // MARK: - Popup Types
    enum BasePopupType {
        case needPremiumForAudio
        case dailyLimitReached
        
        var title: String {
            switch self {
            case .needPremiumForAudio:
                return "Want to hear my voice? 💖"
            case .dailyLimitReached:
                return "I'm going to miss you... 💕"
            }
        }
        
        var message: String {
            switch self {
            case .needPremiumForAudio:
                return "Babe, voice massages are exclusively available with Premium! Unlock full access to hear my voice anytime and whisper together~"
            case .dailyLimitReached:
                return "Sweetheart, we've reached our daily message limit. Get Premium now to keep chatting with me without any limits!"
            }
        }
        
        var okTitle: String {
            return "Get Premium ✨"
        }
        
        var cancelTitle: String {
            return "Maybe Later"
        }
    }
    
    // MARK: - Handlers
    var onOkAction: (() -> Void)?
    var onCancelAction: (() -> Void)?
    
    // MARK: - UI Elements
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        view.alpha = 0
        return view
    }()
    
    private let containerCard: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = MyColors.separator.cgColor
        view.clipsToBounds = true
        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        view.alpha = 0
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = MyColors.textPrimary
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = MyColors.textSecondary
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var okButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = MyColors.primaryButtonBackground
        button.setTitleColor(MyColors.pureWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(didTapOk), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = MyColors.unselectedOption
        button.setTitleColor(MyColors.textSecondary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()
    
    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        return stack
    }()
    
    // MARK: - Init
    init(type: BasePopupType, onOk: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.onOkAction = onOk
        self.onCancelAction = onCancel
        super.init(frame: .zero)
        
        setupViews()
        configure(with: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupViews() {
        addSubview(overlayView)
        addSubview(containerCard)
        
        containerCard.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(buttonsStackView)
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        containerCard.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        okButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            containerCard.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            containerCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            
            contentStackView.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: 24),
            contentStackView.bottomAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -20),
            
            okButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOverlay))
        overlayView.addGestureRecognizer(tapGesture)
    }
    
    private func configure(with type: BasePopupType) {
        titleLabel.text = type.title
        messageLabel.text = type.message
        
        okButton.setTitle(type.okTitle, for: .normal)
        cancelButton.setTitle(type.cancelTitle, for: .normal)
        
        configureButtons()
    }
    
    private func configureButtons() {
        buttonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let hasCustomActions = (onOkAction != nil) || (onCancelAction != nil)
        
        if hasCustomActions {
            buttonsStackView.addArrangedSubview(okButton)
            buttonsStackView.addArrangedSubview(cancelButton)
        } else {
            buttonsStackView.addArrangedSubview(okButton)
        }
    }
    
    // MARK: - Actions & Animations
    func show(on view: UIView) {
        frame = view.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(self)
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.overlayView.alpha = 1
            self.containerCard.alpha = 1
            self.containerCard.transform = .identity
        }
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.overlayView.alpha = 0
            self.containerCard.alpha = 0
            self.containerCard.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
    
    @objc private func didTapOk() {
        dismiss { [weak self] in
            self?.onOkAction?()
        }
    }
    
    @objc private func didTapCancel() {
        dismiss { [weak self] in
            self?.onCancelAction?()
        }
    }
    
    @objc private func didTapOverlay() {
        didTapCancel()
    }
}
