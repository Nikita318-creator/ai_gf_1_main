import UIKit
import SafariServices
import StoreKit

class TextChatCell: AbstractChatCell {

    private lazy var contentBodyDisplayView: UITextView = {
        let txtContainerView = UITextView()
        txtContainerView.isEditable = false
        txtContainerView.isScrollEnabled = false
        txtContainerView.isSelectable = false
        txtContainerView.dataDetectorTypes = .link
        txtContainerView.backgroundColor = .clear
        txtContainerView.textContainerInset = .zero
        txtContainerView.textContainer.lineFragmentPadding = 0
        txtContainerView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        txtContainerView.textColor = BasePalitColors.textPrimary
        txtContainerView.linkTextAttributes = [
            .foregroundColor: BasePalitColors.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        txtContainerView.delegate = self
        return txtContainerView
    }()

    var messageLabelText: String? {
        return contentBodyDisplayView.text
    }

    override func setupSubviews() {
        bobleView.addSubview(contentBodyDisplayView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentBodyDisplayView.text = nil
    }

    func configure(message: String, isUserMessage: Bool, needHideActionButtons: Bool, id: String, reaction: String?) {
        self.currentMessageID = id

        contentBodyDisplayView.text = message
        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction)

        if isUserMessage {
            bobleView.backgroundColor = BasePalitColors.userMessageBackground
            applyOutgoingTextLayout()
        } else {
            bobleView.backgroundColor = BasePalitColors.assistantMessageBackground
            applyIncomingTextLayout()
        }
    }

    func enableTextSelection() {
        contentBodyDisplayView.isSelectable = true
        contentBodyDisplayView.becomeFirstResponder()
        if let activeSelectionRange = contentBodyDisplayView.textRange(from: contentBodyDisplayView.beginningOfDocument, to: contentBodyDisplayView.endOfDocument) {
            contentBodyDisplayView.selectedTextRange = activeSelectionRange
        }
    }

    func disableTextSelection() {
        contentBodyDisplayView.isSelectable = false
    }

    private func applyOutgoingTextLayout() {
        bobleView.snp.remakeConstraints { constraintMaker in
            constraintMaker.top.equalToSuperview().inset(4)
            constraintMaker.bottom.equalToSuperview().inset(4)
            constraintMaker.trailing.equalToSuperview().inset(16)
            constraintMaker.leading.greaterThanOrEqualToSuperview().inset(80)
        }

        contentBodyDisplayView.snp.remakeConstraints { constraintMaker in
            constraintMaker.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }
    }

    private func applyIncomingTextLayout() {
        let sideAvatarDimensions: CGFloat = isIPad() ? 52 : 36
        authorImageView.snp.remakeConstraints { constraintMaker in
            constraintMaker.leading.equalToSuperview().inset(16)
            constraintMaker.bottom.equalToSuperview().inset(4)
            constraintMaker.width.height.equalTo(sideAvatarDimensions)
        }

        bobleView.snp.remakeConstraints { constraintMaker in
            constraintMaker.top.equalToSuperview().inset(4)
            constraintMaker.bottom.equalToSuperview().inset(4)
            constraintMaker.leading.equalTo(authorImageView.snp.trailing).offset(8)
            constraintMaker.trailing.lessThanOrEqualToSuperview().inset(80)
        }

        contentBodyDisplayView.snp.remakeConstraints { constraintMaker in
            constraintMaker.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }
    }

    override func iPadCheck() {
        super.iPadCheck()
        guard isIPad() else { return }
        contentBodyDisplayView.font = UIFont.systemFont(ofSize: 26, weight: .regular)
    }
}

extension TextChatCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let hostController = vc else { return false }
        hideKeyboardHandler?()

        let browserController = SFSafariViewController(url: URL)
        browserController.modalPresentationStyle = .pageSheet
        hostController.present(browserController, animated: true)
        return false
    }
}
