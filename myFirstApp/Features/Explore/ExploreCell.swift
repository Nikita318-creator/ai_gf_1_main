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
            MyColors.background.withAlphaComponent(0.55).cgColor,
            MyColors.background.withAlphaComponent(0.96).cgColor
        ]
        gradient.locations = [0, 0.5, 1]
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
    private let subtitleLabel = UILabel()
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
                self.layer.shadowOpacity = self.isHighlighted ? 0.12 : 0.28
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.transform = .identity
        imageView.image = nil
        roleLabel.text = nil
        roleLabel.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let radius: CGFloat = isNeedBigTextForIPad() ? 28 : 20

        // Скругляем углы самой ячейки
        contentView.layer.cornerRadius = radius
        contentView.layer.masksToBounds = true

        // Тень вешаем на layer ячейки (не contentView — у него masksToBounds = true и тень будет обрезана)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Тень карточки — даёт вес на фоне остальной сетки
        layer.shadowColor = MyColors.pureBlack.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.28

        contentView.backgroundColor = MyColors.cardBackground
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = MyColors.cardBackground
        contentView.addSubview(imageView)

        contentView.addSubview(scrimView)

        // Тег в углу — раньше добавлялся на экран, но никогда не получал текст.
        // Теперь реально показывает assistantInfo и скрыт, если он пустой.
        roleLabel.textColor = MyColors.textPrimary
        roleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        roleLabel.textAlignment = .center
        roleLabel.backgroundColor = MyColors.primary
        roleLabel.layer.cornerRadius = 10
        roleLabel.clipsToBounds = true
        roleLabel.numberOfLines = 1
        roleLabel.isHidden = true
        contentView.addSubview(roleLabel)

        nameLabel.textColor = MyColors.textPrimary
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)

        subtitleLabel.textColor = MyColors.textPrimary.withAlphaComponent(0.75)
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 1
        contentView.addSubview(subtitleLabel)

        // MARK: Constraints
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrimView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.45)
        }

        roleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(10)
            make.height.equalTo(20)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
        }
        roleLabel.setContentHuggingPriority(.required, for: .horizontal)

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(subtitleLabel.snp.top).offset(-1)
        }
        
        subtitleLabel.isHidden = true
        roleLabel.isHidden = true
    }

    // MARK: - Configure Cell
    func configure(with model: ExploreDataModel) {
        let imageName = model.image ?? ""
        imageView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (imageName + "_") : imageName)) ?? UIImage(named: imageName)

        nameLabel.text = model.name

        let trimmedInfo = model.assistantInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleLabel.text = trimmedInfo

        // Короткий тег в углу — первые несколько слов assistantInfo, если есть
//        if let firstChunk = trimmedInfo.split(separator: ",").first, !firstChunk.isEmpty {
//            roleLabel.text = "  \(firstChunk.trimmingCharacters(in: .whitespaces))  "
//            roleLabel.isHidden = false
//        }
    }
}

extension ExploreCell {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }

        nameLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 20, weight: .regular)
        roleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        roleLabel.snp.updateConstraints { make in
            make.height.equalTo(30)
        }
        roleLabel.layer.cornerRadius = 15
    }
}
