import UIKit

class LoaderChatCell: AbstractChatCell {

    private let activitySpinnerView = UIActivityIndicatorView(style: .medium)
    private let stateDescriptionLabel: UILabel = {
        let textElement = UILabel()
        textElement.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textElement.textColor = BasePalitColors.textSecondary
        return textElement
    }()

    override func setupSubviews() {
        activitySpinnerView.color = BasePalitColors.textSecondary
        bobleView.addSubview(activitySpinnerView)
        bobleView.addSubview(stateDescriptionLabel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        activitySpinnerView.stopAnimating()
        stateDescriptionLabel.text = nil
    }

    func configureLoader() {
        activitySpinnerView.startAnimating()
        stateDescriptionLabel.text = RockStarRepository.waitingForNewMessageWithType.rawValue
        stateDescriptionLabel.textColor = BasePalitColors.textSecondary

        updateBaseUI(isUserMessage: false, reaction: nil)
        applyAssistantLoaderLayout()
    }

    private func applyAssistantLoaderLayout() {
        bobleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        bobleView.backgroundColor = BasePalitColors.assistantMessageBackground

        let iconDimension: CGFloat = isIPad() ? 52 : 36
        authorImageView.snp.remakeConstraints { layoutConstraint in
            layoutConstraint.leading.equalToSuperview().inset(16)
            layoutConstraint.bottom.equalToSuperview().inset(4)
            layoutConstraint.width.height.equalTo(iconDimension)
        }

        bobleView.snp.remakeConstraints { layoutConstraint in
            layoutConstraint.top.equalToSuperview().inset(4)
            layoutConstraint.bottom.equalToSuperview().inset(4)
            layoutConstraint.leading.equalTo(authorImageView.snp.trailing).offset(8)
            layoutConstraint.trailing.lessThanOrEqualToSuperview().inset(80)
            layoutConstraint.width.greaterThanOrEqualTo(150)
            layoutConstraint.height.equalTo(44)
        }

        let edgeSpacing: CGFloat = isIPad() ? 12 : 8
        let spinnerDimension: CGFloat = isIPad() ? 24 : 20

        activitySpinnerView.snp.remakeConstraints { layoutConstraint in
            layoutConstraint.leading.equalToSuperview().inset(edgeSpacing)
            layoutConstraint.centerY.equalToSuperview()
            layoutConstraint.width.height.equalTo(spinnerDimension)
        }

        stateDescriptionLabel.snp.remakeConstraints { layoutConstraint in
            layoutConstraint.leading.equalTo(activitySpinnerView.snp.trailing).offset(edgeSpacing / 2)
            layoutConstraint.trailing.equalToSuperview().inset(edgeSpacing)
            layoutConstraint.centerY.equalToSuperview()
        }
    }

    override func iPadCheck() {
        super.iPadCheck()
        guard isIPad() else { return }
        stateDescriptionLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
    }
}
