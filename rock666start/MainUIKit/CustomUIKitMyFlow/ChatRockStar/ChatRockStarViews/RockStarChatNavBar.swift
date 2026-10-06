import UIKit
import SnapKit

final class RockStarChatNavBar: UIView {
    
    let backButton = UIButton(type: .system)
    let avatarImageView = UIImageView()
    let titleLabel = UILabel()
    
    var onBackTapped: (() -> Void)?
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
        backgroundColor = BasePalitColors.background.withAlphaComponent(0.88)
        
        let navSeparator = UIView()
        navSeparator.backgroundColor = BasePalitColors.separator.withAlphaComponent(0.6)
        addSubview(navSeparator)
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = BasePalitColors.textSecondary
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        addSubview(avatarImageView)

        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = BasePalitColors.textPrimary
        addSubview(titleLabel)

        let buttonPointSize: CGFloat = isIPad() ? 30 : 18
        let cornerRadius: CGFloat = isIPad() ? 30 : 20
        
        backButton.setImage(UIImage(systemName: "chevron.backward")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: buttonPointSize, weight: .medium)
        ), for: .normal)
        backButton.tintColor = BasePalitColors.primary
        backButton.backgroundColor = BasePalitColors.primary.withAlphaComponent(0.15)
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        addSubview(backButton)

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
        
        backButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
    }

    @objc private func backButtonTapped() { onBackTapped?() }
    @objc private func avatarTapped() { onAvatarTapped?() }
    @objc private func navigationBarTapped() { onProfileTapped?() }
}
