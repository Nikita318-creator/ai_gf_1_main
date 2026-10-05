import UIKit
import SafariServices
import StoreKit

class AIGFTextChatCell: AIGFChatCell {

    private lazy var messageLabel: UITextView = {
        let messageTextView = UITextView()
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.isSelectable = false
        messageTextView.dataDetectorTypes = .link
        messageTextView.backgroundColor = .clear
        messageTextView.textContainerInset = .zero
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        messageTextView.textColor = BasePalitColors.textPrimary
        messageTextView.linkTextAttributes = [
            .foregroundColor: BasePalitColors.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        messageTextView.delegate = self
        return messageTextView
    }()

    var messageLabelText: String? {
        return messageLabel.text
    }

    override func setupSubviews() {
        messageContainerView.addSubview(messageLabel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
    }

    func configure(message: String, isUserMessage: Bool, needHideActionButtons: Bool, id: String, reaction: String?) {
        self.messageID = id

        messageLabel.text = message
        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction)

        if isUserMessage {
            messageContainerView.backgroundColor = BasePalitColors.userMessageBackground
            configureUserMessageForText()
        } else {
            messageContainerView.backgroundColor = BasePalitColors.assistantMessageBackground
            configureAssistantMessageForText()
        }
    }

    func enableTextSelection() {
        messageLabel.isSelectable = true
        messageLabel.becomeFirstResponder()
        if let textRange = messageLabel.textRange(from: messageLabel.beginningOfDocument, to: messageLabel.endOfDocument) {
            messageLabel.selectedTextRange = textRange
        }
    }

    func disableTextSelection() {
        messageLabel.isSelectable = false
    }

    private func configureUserMessageForText() {
        messageContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(80)
        }

        messageLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }
    }

    private func configureAssistantMessageForText() {
        let avatarViewSize: CGFloat = isIPad() ? 52 : 36
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
        }

        messageLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }
    }

    override func iPadCheck() {
        super.iPadCheck()
        guard isIPad() else { return }
        messageLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
    }
}

extension AIGFTextChatCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let vc = vc else { return false }
        hideKeyboardHandler?()

        let safariVC = SFSafariViewController(url: URL)
        safariVC.modalPresentationStyle = .pageSheet
        vc.present(safariVC, animated: true)
        return false
    }
}
