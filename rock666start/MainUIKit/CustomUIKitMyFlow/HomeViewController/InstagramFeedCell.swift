import UIKit
import SnapKit

final class InstagramFeedCell: UICollectionViewCell {
    
    static let reuseIdentifier = "InstagramFeedCell"
    
    // MARK: - UI Components
    
    private let containerCardView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1.5
        view.layer.borderColor = BasePalitColors.separator.cgColor
        
        // Настройка тени
        view.layer.shadowColor = BasePalitColors.pureBlack.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.4
        return view
    }()
    
    private let cardContentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()
    
    private let mainImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // Контейнер под блюр и градиент
    private let overlayContainerView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    // Эффект легкого блюра
    private let blurEffectView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()
    
    // Маска для блюра, чтобы он плавно растворялся наверх
    private let blurMaskLayer = CAGradientLayer()
    
    // Градиент сверху блюра для глубокого темного фона под белым текстом
    private let gradientLayer = CAGradientLayer()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = BasePalitColors.pureWhite
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private let roleBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.primary.withAlphaComponent(0.85)
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let roleLabel: UILabel = {
        let label = UILabel()
        label.textColor = BasePalitColors.pureWhite
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.textColor = BasePalitColors.textPrimary
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 3
        return label
    }()
    
    private let actionButtonView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.primaryButtonBackground
        view.layer.cornerRadius = 14
        return view
    }()
    
    private let actionButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "Chat Now"
        label.textColor = BasePalitColors.pureWhite
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let overlayBounds = overlayContainerView.bounds
        
        // Обновляем фреймы градиента и маски
        gradientLayer.frame = overlayBounds
        blurEffectView.frame = overlayBounds
        blurMaskLayer.frame = overlayBounds
        
        containerCardView.layer.shadowPath = UIBezierPath(roundedRect: containerCardView.bounds, cornerRadius: 24).cgPath
    }
    
    // MARK: - Setup UI
    
    private func setupViews() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(containerCardView)
        containerCardView.addSubview(cardContentView)
        
        cardContentView.addSubview(mainImageView)
        cardContentView.addSubview(overlayContainerView)
        
        setupBlurAndGradient()
        
        cardContentView.addSubview(nameLabel)
        cardContentView.addSubview(roleBadgeView)
        roleBadgeView.addSubview(roleLabel)
        cardContentView.addSubview(bioLabel)
        cardContentView.addSubview(actionButtonView)
        actionButtonView.addSubview(actionButtonLabel)
    }
    
    private func setupBlurAndGradient() {
        // 1. Настройка плавной маски блюра (сверху 0% альфа -> снизу 100%)
        blurMaskLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor,
            UIColor.black.cgColor
        ]
        blurMaskLayer.locations = [0.0, 0.3, 0.7, 1.0]
        
        blurEffectView.layer.mask = blurMaskLayer
        overlayContainerView.addSubview(blurEffectView)
        
        // 2. Дополнительный мягкий затемняющий градиент поверх блюра
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            BasePalitColors.pureBlack.withAlphaComponent(0.3).cgColor,
            BasePalitColors.pureBlack.withAlphaComponent(0.85).cgColor
        ]
        gradientLayer.locations = [0.0, 0.4, 1.0]
        overlayContainerView.layer.addSublayer(gradientLayer)
    }
    
    private func setupConstraints() {
        containerCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        cardContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mainImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Занимает нижние 55% карточки для плавного перехода
        overlayContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.55)
        }
        
        actionButtonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(50)
        }
        
        actionButtonLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bioLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(actionButtonView.snp.top).offset(-16)
        }
        
        roleBadgeView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(bioLabel.snp.top).offset(-10)
        }
        
        roleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalTo(roleBadgeView.snp.top).offset(-8)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with role: RoleModel) {
        mainImageView.image = UIImage(named: role.image)
        nameLabel.text = role.name
        roleLabel.text = role.roleTitle.uppercased()
        bioLabel.text = role.bio
    }
    
    // MARK: - iPad Layout Update
    
    func adaptForIPad() {
        nameLabel.font = .systemFont(ofSize: 32, weight: .bold)
        roleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        bioLabel.font = .systemFont(ofSize: 20, weight: .regular)
        actionButtonLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        actionButtonView.snp.updateConstraints { make in
            make.height.equalTo(64)
        }
    }
}
