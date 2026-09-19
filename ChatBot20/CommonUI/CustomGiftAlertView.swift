import UIKit
import SnapKit

// MARK: - Custom Base Alert View

class CustomGiftAlertView: UIView {
    
    let alertView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = MyColors.separator.cgColor
        
        // Премиальная тень
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 25
        view.layer.shadowOpacity = 0.5
        return view
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.6
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBase()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBase() {
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(alertView)
        alertView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOverlay))
        blurEffectView.addGestureRecognizer(tapGesture)
    }
    
    @objc open func didTapOverlay() {
        dismissAlert()
    }
    
    func show(on viewController: UIViewController) {
        self.frame = viewController.view.bounds
        viewController.view.addSubview(self)
        
        alertView.alpha = 0
        alertView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        blurEffectView.alpha = 0
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.alertView.alpha = 1
            self.alertView.transform = .identity
            self.blurEffectView.alpha = 0.6
        }
    }
    
    @objc func dismissAlert() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.alertView.alpha = 0
            self.alertView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.blurEffectView.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - GiftConfirmAlert

class GiftConfirmAlert: CustomGiftAlertView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()
    
    private let giftContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.messageBackground
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1
        view.layer.borderColor = MyColors.separator.cgColor
        return view
    }()
    
    private let giftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let sendButton: AlertAnimatedButton = {
        let button = AlertAnimatedButton(type: .system)
        button.setTitle("Send".localize(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(MyColors.textPrimary, for: .normal)
        button.backgroundColor = MyColors.primary
        button.layer.cornerRadius = 16
        
        button.layer.shadowColor = MyColors.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.35
        return button
    }()
    
    private var completion: (() -> Void)?
    
    init(gift: GirlfriendGiftModel, completion: @escaping () -> Void) {
        super.init(frame: .zero)
        self.completion = completion
        setupAlert(gift: gift)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAlert(gift: GirlfriendGiftModel) {
        titleLabel.text = "".localize(attribut: "SendTheGift", arguments: "\(gift.price)")
        
        closeButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        giftImageView.image = UIImage(named: gift.imageName)
        
        alertView.addSubview(titleLabel)
        alertView.addSubview(closeButton)
        alertView.addSubview(giftContainerView)
        giftContainerView.addSubview(giftImageView)
        alertView.addSubview(sendButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(14)
            make.size.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(closeButton.snp.leading).offset(-8)
        }
        
        giftContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(180)
        }
        
        giftImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        sendButton.snp.makeConstraints { make in
            make.top.equalTo(giftContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    @objc private func sendButtonTapped() {
        completion?()
        dismissAlert()
    }
}

// MARK: - NotEnoughCoinsAlert

class NotEnoughCoinsAlert: CustomGiftAlertView {
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 42, weight: .medium)
        iv.image = UIImage(systemName: "circle.circle.fill", withConfiguration: config) // Можно заменить на ассет монетки
        iv.tintColor = MyColors.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "NotEnoughCoins".localize()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let okButton: AlertAnimatedButton = {
        let button = AlertAnimatedButton(type: .system)
        button.setTitle("OK".localize(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(MyColors.textPrimary, for: .normal)
        button.backgroundColor = MyColors.primary
        button.layer.cornerRadius = 16
        
        button.layer.shadowColor = MyColors.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.35
        return button
    }()
    
    var okButtonTappedHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAlert()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAlert() {
        closeButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        okButton.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        
        alertView.addSubview(closeButton)
        alertView.addSubview(iconImageView)
        alertView.addSubview(titleLabel)
        alertView.addSubview(okButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(14)
            make.size.equalTo(32)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(54)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        okButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    @objc func okButtonTapped() {
        dismissAlert()
        okButtonTappedHandler?()
    }
}
