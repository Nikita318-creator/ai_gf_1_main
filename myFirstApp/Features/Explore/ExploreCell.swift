import UIKit
import SnapKit

// MARK: - Data Model
struct ExploreDataModel {
    let id: Int
    let name: String
    let image: String?
    let assistantInfo: String
}

// MARK: - Scrim (мягкое затемнение снизу карточки под именем)
private final class ExploreScrimView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [
            MyColors.background.withAlphaComponent(0).cgColor,
            MyColors.background.withAlphaComponent(0.5).cgColor,
            MyColors.background.withAlphaComponent(0.92).cgColor
        ]
        gradient.locations = [0, 0.55, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ExploreCell: UICollectionViewCell {
    
    static let identifier = "ExploreCell"
    
    // MARK: - UI Components
    private let imageView = UIImageView()
    private let scrimView = ExploreScrimView()
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Мягкое «вдавливание» при нажатии (как в сторис)
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.contentView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.transform = .identity
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Закругляем углы ячейки
        contentView.layer.cornerRadius = isCurrentDeviceiPad() ? 28 : 20
        contentView.layer.masksToBounds = true
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        contentView.backgroundColor = MyColors.cardBackground
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        contentView.addSubview(scrimView)
        
        nameLabel.textColor = MyColors.textPrimary
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)
        
        roleLabel.textColor = MyColors.textPrimary
        roleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        roleLabel.textAlignment = .center
        roleLabel.backgroundColor = MyColors.primary
        roleLabel.layer.cornerRadius = 10
        roleLabel.clipsToBounds = true
        roleLabel.numberOfLines = 2
        contentView.addSubview(roleLabel)
        
        // Setup Constraints
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrimView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.4)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        
        roleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(10)
            make.height.greaterThanOrEqualTo(24)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.8)
        }
    }
    
    // MARK: - Configure Cell
    func configure(with model: ExploreDataModel) {
        let imageName = model.image ?? ""
        imageView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (imageName + "_") : imageName)) ?? UIImage(named: imageName)
        nameLabel.text = model.name
    }
}

extension ExploreCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        nameLabel.font = .systemFont(ofSize: 34, weight: .semibold)
        roleLabel.font = .systemFont(ofSize: 24, weight: .medium)
    }
}
