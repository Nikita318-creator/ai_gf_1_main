import UIKit
import SnapKit

// MARK: - Data Model
struct RoleplayModel {
    let id: Int
    let name: String
    let role: String
    let image: String?
    let assistantInfo: String
}

class RoleplayCell: UICollectionViewCell {
    
    static let identifier = "RoleplayCell"
    
    // MARK: - UI Components
    private let imageView = UIImageView()
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Закругляем углы ячейки
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        contentView.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 1
        nameLabel.layer.shadowColor = UIColor.black.cgColor // Цвет тени (черный)
        nameLabel.layer.shadowOffset = CGSize(width: 1, height: 2) // Смещение тени (немного вниз)
        nameLabel.layer.shadowOpacity = 1 // Прозрачность тени
        nameLabel.layer.shadowRadius = 2 // Радиус размытия тени
        contentView.addSubview(nameLabel)
        
        roleLabel.textColor = .white
        roleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        roleLabel.textAlignment = .center
        roleLabel.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        roleLabel.layer.cornerRadius = 8
        roleLabel.clipsToBounds = true
        roleLabel.numberOfLines = 2
        contentView.addSubview(roleLabel)
        
        // Setup Constraints
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }
        
        roleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(8)
            make.height.greaterThanOrEqualTo(24)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.8)
        }
    }
    
    // MARK: - Configure Cell
    func configure(with model: RoleplayModel) {
        imageView.image = UIImage(named: model.image ?? "")
        nameLabel.text = model.name
        roleLabel.text = " " + model.role + "  "
    }
}

extension RoleplayCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        nameLabel.font = .systemFont(ofSize: 40, weight: .semibold)
        roleLabel.font = .systemFont(ofSize: 32, weight: .medium)
    }
}
