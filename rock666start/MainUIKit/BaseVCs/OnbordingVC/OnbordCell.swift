import UIKit
import SnapKit

class OnbordCell: UICollectionViewCell {

    static let identifier = "OnbordCell"

    private let heroImageView: UIImageView = {
        let imageHolder = UIImageView()
        imageHolder.contentMode = .scaleAspectFill
        imageHolder.clipsToBounds = true
        return imageHolder
    }()

    private let dimmingBackdropView: UIView = {
        let container = UIView()
        return container
    }()

    private let headerTextLabel: UILabel = {
        let textDisplay = UILabel()
        textDisplay.font = .systemFont(ofSize: 28, weight: .bold)
        textDisplay.textColor = BasePalitColors.textPrimary
        textDisplay.textAlignment = .center
        textDisplay.numberOfLines = 0
        return textDisplay
    }()

    private let bodyTextLabel: UILabel = {
        let textDisplay = UILabel()
        textDisplay.font = .systemFont(ofSize: 15, weight: .regular)
        textDisplay.textColor = BasePalitColors.textSecondary
        textDisplay.textAlignment = .center
        textDisplay.numberOfLines = 0
        return textDisplay
    }()

    private lazy var contentGroupStack: UIStackView = {
        let containerStack = UIStackView(arrangedSubviews: [headerTextLabel, bodyTextLabel])
        containerStack.axis = .vertical
        containerStack.spacing = 10
        containerStack.alignment = .fill
        return containerStack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildCellStructure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderGradientBackground()
    }

    private func buildCellStructure() {
        contentView.backgroundColor = .clear

        contentView.addSubview(heroImageView)
        contentView.addSubview(dimmingBackdropView)
        contentView.addSubview(contentGroupStack)

        heroImageView.snp.makeConstraints { constraintMaker in
            constraintMaker.top.leading.trailing.equalToSuperview()
            constraintMaker.height.equalToSuperview().multipliedBy(0.68)
        }

        dimmingBackdropView.snp.makeConstraints { constraintMaker in
            constraintMaker.edges.equalTo(heroImageView)
        }

        contentGroupStack.snp.makeConstraints { constraintMaker in
            constraintMaker.top.equalTo(heroImageView.snp.bottom).offset(12)
            constraintMaker.leading.trailing.equalToSuperview().inset(28)
        }
    }

    private func renderGradientBackground() {
        dimmingBackdropView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let gradientLayerRef = CAGradientLayer()
        gradientLayerRef.frame = dimmingBackdropView.bounds
        gradientLayerRef.colors = [
            UIColor.clear.cgColor,
            BasePalitColors.background.withAlphaComponent(0.4).cgColor,
            BasePalitColors.background.cgColor
        ]
        gradientLayerRef.locations = [0.0, 0.6, 1.0]
        dimmingBackdropView.layer.addSublayer(gradientLayerRef)
    }

    func configure(with slide: OnboardingVC.OnbordModel) {
        heroImageView.image = UIImage(named: slide.imageName)
        headerTextLabel.text = slide.title
        bodyTextLabel.text = slide.subtitle
    }
}
