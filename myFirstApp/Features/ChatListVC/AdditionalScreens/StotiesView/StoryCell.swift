import UIKit
import SnapKit

// MARK: - Ring (градиентное кольцо как в Telegram / серое для просмотренных)

private final class StoryRingView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let gradientMask = CAShapeLayer()
    private let viewedLayer = CAShapeLayer()
    
    var lineWidth: CGFloat = 2.5 {
        didSet { setNeedsLayout() }
    }
    
    var isViewed: Bool = false {
        didSet { applyState() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        gradientLayer.colors = [MyColors.link.cgColor, MyColors.primary.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        // Маска: цвет обводки тут не виден, важна только форма кольца
        gradientMask.fillColor = UIColor.clear.cgColor
        gradientMask.strokeColor = MyColors.textPrimary.cgColor
        gradientLayer.mask = gradientMask
        layer.addSublayer(gradientLayer)
        
        viewedLayer.fillColor = UIColor.clear.cgColor
        viewedLayer.strokeColor = MyColors.separator.cgColor
        layer.addSublayer(viewedLayer)
        
        applyState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func applyState() {
        gradientLayer.isHidden = isViewed
        viewedLayer.isHidden = !isViewed
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let path = UIBezierPath(ovalIn: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)).cgPath
        
        gradientLayer.frame = bounds
        gradientMask.frame = bounds
        gradientMask.path = path
        gradientMask.lineWidth = lineWidth
        
        viewedLayer.frame = bounds
        viewedLayer.path = path
        viewedLayer.lineWidth = lineWidth
        
        CATransaction.commit()
    }
}

// MARK: - StoryCell

class StoryCell: UICollectionViewCell {
    static let identifier = "StoryCell"

    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let seenBorderView = StoryRingView() // Кольцо вокруг аватара
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Мягкое «вдавливание» при нажатии
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.contentView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
            }
        }
    }

    private func setupViews() {
        contentView.backgroundColor = .clear

        // Кольцо: 66 = аватар 58 + зазор 2 + линия 2 с каждой стороны
        seenBorderView.lineWidth = 2
        contentView.addSubview(seenBorderView)

        // Аватарка сторис
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 29
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = MyColors.cardBackground
        contentView.addSubview(avatarImageView)

        // Имя под сторис
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)

        // Constraints
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(58)
        }
        
        seenBorderView.snp.makeConstraints { make in
            make.center.equalTo(avatarImageView)
            make.width.height.equalTo(66)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(seenBorderView.snp.bottom).offset(3)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    func configure(with story: StoryModel) {
        avatarImageView.image = UIImage(named: story.imageName)
        titleLabel.text = story.title
        seenBorderView.isViewed = story.isViewed
        titleLabel.textColor = story.isViewed ? MyColors.textSecondary : MyColors.textPrimary
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        titleLabel.text = nil
        seenBorderView.isViewed = false
        titleLabel.textColor = MyColors.textPrimary
        contentView.transform = .identity
    }
}

extension StoryCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        avatarImageView.layer.cornerRadius = 40
        seenBorderView.lineWidth = 3
        
        avatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(80)
        }
        
        seenBorderView.snp.updateConstraints { make in
            make.width.height.equalTo(92)
        }
    }
}
