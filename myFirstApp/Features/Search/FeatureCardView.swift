import UIKit
import SnapKit

final class FeatureCardView: UIControl {
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = MyColors.textSecondary
        label.numberOfLines = 0
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        let iconName = ""
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iv.image = UIImage(systemName: "chevron.forward", withConfiguration: config)
        iv.tintColor = MyColors.textSecondary
        return iv
    }()
    
    init(badgeText: String, title: String, description: String, iconName: String, accentColor: UIColor) {
        super.init(frame: .zero)
        setupView()
        setupConstraints()
        configure(badgeText: badgeText, title: title, description: description, iconName: iconName, accentColor: accentColor)
        updateForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = MyColors.cardBackground
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = MyColors.separator.cgColor
        
        addSubview(badgeLabel)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(iconImageView)
        addSubview(arrowImageView)
    }
    
    private func setupConstraints() {
        badgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badgeLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(iconImageView.snp.leading).offset(-12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(12)
            make.height.equalTo(18)
        }
    }
    
    private func configure(badgeText: String, title: String, description: String, iconName: String, accentColor: UIColor) {
        badgeLabel.text = "  \(badgeText)  "
        badgeLabel.backgroundColor = accentColor.withAlphaComponent(0.2)
        badgeLabel.textColor = accentColor
        
        titleLabel.text = title
        descriptionLabel.text = description
        
        let config = UIImage.SymbolConfiguration(pointSize: isCurrentDeviceiPad() ? 42 : 26, weight: .semibold)
        if let systemImage = UIImage(systemName: iconName, withConfiguration: config) {
            iconImageView.image = systemImage
            iconImageView.tintColor = accentColor
        } else {
            iconImageView.image = UIImage(named: iconName)
        }
    }
    
    // MARK: - Touch Animations
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.85 : 1.0
            }
        }
    }
}

// MARK: - iPad FeatureCardView Layout Support

extension FeatureCardView {
    func updateForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }

        layer.cornerRadius = 30

        badgeLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        badgeLabel.layer.cornerRadius = 10
        
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        descriptionLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)

        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        arrowImageView.image = UIImage(systemName: "chevron.forward", withConfiguration: arrowConfig)

        badgeLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(32)
        }

        iconImageView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().offset(-28)
            make.size.equalTo(52)
        }

        titleLabel.snp.updateConstraints { make in
            make.top.equalTo(badgeLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalTo(iconImageView.snp.leading).offset(-18)
        }

        descriptionLabel.snp.updateConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-18)
            make.bottom.equalToSuperview().offset(-28)
        }

        arrowImageView.snp.updateConstraints { make in
            make.trailing.equalToSuperview().offset(-28)
            make.bottom.equalToSuperview().offset(-28)
            make.width.equalTo(18)
            make.height.equalTo(28)
        }
    }
}

