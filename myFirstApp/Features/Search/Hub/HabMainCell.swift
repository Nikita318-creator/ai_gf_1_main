import UIKit
import SnapKit

struct HabMainDataModel {
    let id: String
    let title: String
    let imageName: String
}

class HabMainCell: UICollectionViewCell {
    static let identifier = "GameCell"
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let labelBackgroundView = UIView()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        // Карточка
        containerView.backgroundColor = MyColors.cardBackground
        containerView.layer.cornerRadius = 16
        
        // Рамка
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = MyColors.pureWhite.withAlphaComponent(0.08).cgColor
        
        containerView.clipsToBounds = true
        contentView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Картинка
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = MyColors.cardBackground
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Градиент
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            MyColors.pureBlack.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.locations = [0.6, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        // Подложка лейбла
        labelBackgroundView.backgroundColor = MyColors.background
        labelBackgroundView.layer.cornerRadius = 10
        labelBackgroundView.layer.borderWidth = 1.0
        labelBackgroundView.layer.borderColor = MyColors.pureWhite.withAlphaComponent(0.1).cgColor
        labelBackgroundView.alpha = 0.95
        containerView.addSubview(labelBackgroundView)

        // Название игры
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        labelBackgroundView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
        }

        labelBackgroundView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
            make.leading.trailing.lessThanOrEqualToSuperview().inset(12)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    func configure(with model: HabMainDataModel) {
        titleLabel.text = model.title
        imageView.image = MiniGamesPhotoCacheService.shared.getImage(named: model.imageName)
    }
}
