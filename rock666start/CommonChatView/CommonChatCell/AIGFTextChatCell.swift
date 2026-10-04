import UIKit
import SafariServices
import StoreKit

class AIGFTextChatCell: AIGFChatCell {

    var copyTappedHandler: (() -> Void)?
    var likeTappedHandler: ((Bool) -> Void)?

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
        messageTextView.textColor = MyColors.textPrimary
        messageTextView.linkTextAttributes = [
            .foregroundColor: MyColors.link,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        messageTextView.delegate = self
        return messageTextView
    }()

    private lazy var copyAllTextButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isNeedBigTextForIPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        button.setImage(UIImage(systemName: "doc.on.doc")?.withConfiguration(config), for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()

    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isNeedBigTextForIPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        button.setImage(UIImage(systemName: "hand.thumbsup.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()

    private lazy var dislikeButton: UIButton = {
        let button = UIButton(type: .system)
        let pointSize: CGFloat = isNeedBigTextForIPad() ? 18 : 12
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        button.setImage(UIImage(systemName: "hand.thumbsdown.fill")?.withConfiguration(config), for: .normal)
        button.tintColor = MyColors.textSecondary
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = isNeedBigTextForIPad() ? 16 : 8
        stackView.isHidden = true
        return stackView
    }()

    var messageLabelText: String? {
        return messageLabel.text
    }

    override func setupSubviews() {
        messageContainerView.addSubview(messageLabel)
        
        buttonStackView.addArrangedSubview(copyAllTextButton)
        buttonStackView.addArrangedSubview(likeButton)
        buttonStackView.addArrangedSubview(dislikeButton)
        messageContainerView.addSubview(buttonStackView)

        copyAllTextButton.addTarget(self, action: #selector(copyAllTextButtonTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        dislikeButton.addTarget(self, action: #selector(dislikeButtonTapped), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        buttonStackView.isHidden = true
        likeButton.tintColor = MyColors.textSecondary
        dislikeButton.tintColor = MyColors.textSecondary
    }

    func configure(message: String, isUserMessage: Bool, needHideActionButtons: Bool, id: String, reaction: String?, avatarName: String?) {
        self.messageID = id
        let parsed = parseMessagePrefix(message: message)
        let cleanText = parsed.cleanMessage.replacingOccurrences(
            of: "[\\*\\[\\]\\(\\)]",
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        messageLabel.text = cleanText
        updateBaseUI(isUserMessage: isUserMessage, reaction: reaction, avatarName: avatarName, characterName: parsed.characterName)

        if isUserMessage {
            messageContainerView.backgroundColor = MyColors.userMessageBackground
            configureUserMessageForText()
            buttonStackView.isHidden = true
        } else {
            messageContainerView.backgroundColor = MyColors.assistantMessageBackground
            configureAssistantMessageForText(hasNameLabel: parsed.characterName != nil)
            buttonStackView.isHidden = needHideActionButtons
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

    private func configureAssistantMessageForText(hasNameLabel: Bool) {
        let avatarViewSize: CGFloat = isNeedBigTextForIPad() ? 52 : 36
        avatarView.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
            make.width.height.equalTo(avatarViewSize)
        }

        messageContainerView.snp.remakeConstraints { make in
            if hasNameLabel {
                make.top.equalTo(characterNameLabel.snp.bottom).offset(4)
            } else {
                make.top.equalToSuperview().inset(4)
            }
            make.bottom.equalToSuperview().inset(4)
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(80)
        }

        messageLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 14, bottom: 9, right: 14))
        }
    }

    @objc private func copyAllTextButtonTapped() {
        UIPasteboard.general.string = messageLabel.text
        copyTappedHandler?()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        UIView.animate(withDuration: 0.1, animations: {
            self.copyAllTextButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 6, options: [], animations: {
                self.copyAllTextButton.transform = .identity
            })
        }
    }

    @objc private func likeButtonTapped() {
        if likeButton.tintColor == MyColors.textPrimary {
            likeButton.tintColor = MyColors.textSecondary
        } else {
            likeButton.tintColor = MyColors.textPrimary
            dislikeButton.tintColor = MyColors.textSecondary
            likeTappedHandler?(true)

            if BaseManager.shared.shouldRequestReviewAfterLikeTapped() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
    }

    @objc private func dislikeButtonTapped() {
        if dislikeButton.tintColor == MyColors.textPrimary {
            dislikeButton.tintColor = MyColors.textSecondary
        } else {
            dislikeButton.tintColor = MyColors.textPrimary
            likeButton.tintColor = MyColors.textSecondary
            likeTappedHandler?(false)
        }
    }

    override func updateTextForIPadIfNeeded() {
        super.updateTextForIPadIfNeeded()
        guard isNeedBigTextForIPad() else { return }
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
