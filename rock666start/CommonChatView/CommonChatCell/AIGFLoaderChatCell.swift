import UIKit

class AIGFLoaderChatCell: AIGFChatCell {

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = MyColors.textSecondary
        return label
    }()

    override func setupSubviews() {
        loadingIndicator.color = MyColors.textSecondary
        messageContainerView.addSubview(loadingIndicator)
        messageContainerView.addSubview(statusLabel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingIndicator.stopAnimating()
        statusLabel.text = nil
    }

    func configureLoader() {
        loadingIndicator.startAnimating()
        statusLabel.text = MyGovnoSingltone.shared.currentAIMessageType.rawValue
        statusLabel.textColor = MyColors.textSecondary

        updateBaseUI(isUserMessage: false, reaction: nil)
        configureAssistantMessageForLoader()
    }

    private func configureAssistantMessageForLoader() {
        messageContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        messageContainerView.backgroundColor = MyColors.assistantMessageBackground

        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
            make.width.greaterThanOrEqualTo(150)
            make.height.equalTo(44)
        }

        let padding: CGFloat = isNeedBigTextForIPad() ? 12 : 8
        let indicatorSize: CGFloat = isNeedBigTextForIPad() ? 24 : 20

        loadingIndicator.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(indicatorSize)
        }

        statusLabel.snp.remakeConstraints { make in
            make.leading.equalTo(loadingIndicator.snp.trailing).offset(padding / 2)
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
        }
    }

    override func updateTextForIPadIfNeeded() {
        super.updateTextForIPadIfNeeded()
        guard isNeedBigTextForIPad() else { return }
        statusLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
    }
}
