import UIKit
import SnapKit

final class AIGFChatNavigationBar: UIView {
    
    let backButton = UIButton(type: .system)
    let callButton = UIButton(type: .system)
    let avatarImageView = UIImageView()
    let titleLabel = UILabel()
    
    var onBackTapped: (() -> Void)?
    var onCallTapped: (() -> Void)?
    var onAvatarTapped: (() -> Void)?
    var onProfileTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = MyColors.background.withAlphaComponent(0.88)
        
        let navSeparator = UIView()
        navSeparator.backgroundColor = MyColors.separator.withAlphaComponent(0.6)
        addSubview(navSeparator)
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = MyColors.textSecondary
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        addSubview(avatarImageView)

        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = MyColors.textPrimary
        addSubview(titleLabel)

        let buttonPointSize: CGFloat = isNeedBigTextForIPad() ? 30 : 18
        let cornerRadius: CGFloat = isNeedBigTextForIPad() ? 30 : 20
        
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        ), for: .normal)
        backButton.tintColor = MyColors.primary
        backButton.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        addSubview(backButton)

        let callImage = UIImage(systemName: "phone.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        )
        callButton.setImage(callImage, for: .normal)
        callButton.tintColor = MyColors.primary
        callButton.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        callButton.layer.cornerRadius = cornerRadius
        callButton.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
        addSubview(callButton)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(navigationBarTapped)))

        setupConstraints()
    }

    private func setupConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(titleLabel.snp.leading).offset(-8)
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
        }

        titleLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }

        callButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        
        backButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
    }

    func configure(title: String?, avatarImage: UIImage?) {
        titleLabel.text = title
        avatarImageView.image = avatarImage
    }

    func updateForIPad() {
        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        avatarImageView.layer.cornerRadius = 30
        backButton.layer.cornerRadius = 30

        avatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(60)
            make.trailing.equalTo(titleLabel.snp.leading).offset(-20)
        }
        
        callButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
        
        backButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
    }

    @objc private func backButtonTapped() { onBackTapped?() }
    @objc private func callButtonTapped() { onCallTapped?() }
    @objc private func avatarTapped() { onAvatarTapped?() }
    @objc private func navigationBarTapped() { onProfileTapped?() }
}
