import UIKit
import SnapKit

struct StorylineModel {
    let id: String
    let title: String
    let imageName: String
}

class SectionTitleView: UICollectionReusableView {
    static let identifier = "SectionTitleView"
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 24, weight: .black)
        label.textColor = MyColors.textPrimary
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

class StorylineCell: UICollectionViewCell {
    static let identifier = "StorylineCell"
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }
    
    private func setupUI() {
        // Контейнер ячейки
        containerView.backgroundColor = MyColors.cardBackground
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        contentView.addSubview(containerView)
        
        // Картинка заполняет ячейку
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        
        // Градиент для читаемости текста поверх фото
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            MyColors.gradientStart.withAlphaComponent(0.6).cgColor,
            MyColors.gradientEnd.withAlphaComponent(0.95).cgColor
        ]
        gradientLayer.locations = [0.4, 0.7, 1.0]
        containerView.layer.addSublayer(gradientLayer)
        
        // Текст карточки
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    
    func configure(with model: StorylineModel) {
        titleLabel.text = model.title
        imageView.image = MiniGamesPhotoCacheService.shared.getImage(named: model.imageName)
    }
}
