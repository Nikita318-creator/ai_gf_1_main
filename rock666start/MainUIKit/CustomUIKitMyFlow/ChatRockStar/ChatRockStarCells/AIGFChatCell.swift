import UIKit
import StoreKit

class AbstractChatCell: UITableViewCell {
    static let identifier = "AIGFChatCell"

    let reactions = [
        (emoji: "❤️", id: "heart"),
        (emoji: "👍", id: "up"),
        (emoji: "👎", id: "down"),
        (emoji: "😂", id: "laugh"),
        (emoji: "😭", id: "cry"),
        (emoji: "😡", id: "angry")
    ]

    let reactionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 11
        view.layer.borderWidth = 2
        view.layer.borderColor = BasePalitColors.background.cgColor
        view.isHidden = true
        return view
    }()

    let reactionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        return label
    }()

    let messageContainerView = UIView()
    let avatarView = UIImageView()

    private var overlayView: UIView?
    var photoForDressUp: UIImage?
    var messageID = ""

    weak var vc: UIViewController?
    var hideKeyboardHandler: (() -> Void)?
    var showSubsHandler: (() -> Void)?
    var reloadDataHandler: (() -> Void)?
    var avatarTappedHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupBaseCell()
        setupSubviews()
        iPadCheck()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {}

    private func setupBaseCell() {
        backgroundColor = .clear
        selectionStyle = .none

        messageContainerView.layer.cornerRadius = 18
        messageContainerView.layer.masksToBounds = false
        messageContainerView.layer.shadowColor = BasePalitColors.background.cgColor
        messageContainerView.layer.shadowOpacity = 0.1
        messageContainerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        messageContainerView.layer.shadowRadius = 2
        contentView.addSubview(messageContainerView)

        avatarView.contentMode = .scaleAspectFill
        avatarView.backgroundColor = BasePalitColors.avatarBackground
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        contentView.addSubview(avatarView)

        contentView.addSubview(reactionContainer)
        reactionContainer.addSubview(reactionLabel)
        reactionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
        setupLongPressForReactions()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reactionLabel.text = ""
        reactionContainer.isHidden = true
        avatarView.image = nil
        avatarView.isHidden = false
    }

    func updateBaseUI(isUserMessage: Bool, reaction: String?) {
        avatarView.isHidden = isUserMessage
        messageContainerView.layer.maskedCorners = isUserMessage
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        if !isUserMessage {
           if let imageName = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName {
                avatarView.image = (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? (imageName + "_") : imageName)) ?? UIImage(named: imageName)
            }

            if let photoForDressUp {
                avatarView.image = photoForDressUp
            }
        }

        if let reactionId = reaction,
           let emoji = reactions.first(where: { $0.id == reactionId })?.emoji {
            reactionContainer.isHidden = false
            reactionLabel.text = emoji
            reactionContainer.backgroundColor = isUserMessage ? BasePalitColors.userMessageBackground : BasePalitColors.assistantMessageBackground

            reactionContainer.snp.remakeConstraints { make in
                make.bottom.equalTo(messageContainerView.snp.bottom).offset(6)
                if isUserMessage {
                    make.trailing.equalTo(messageContainerView.snp.trailing).offset(-8)
                } else {
                    make.leading.equalTo(messageContainerView.snp.leading).offset(8)
                }
                make.height.equalTo(22)
            }
        } else {
            reactionContainer.isHidden = true
        }
    }

    @objc private func avatarTapped() {
        avatarTappedHandler?()
    }

    // MARK: - Long Press & Context Menu
    private func setupLongPressForReactions() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        messageContainerView.isUserInteractionEnabled = true
        messageContainerView.addGestureRecognizer(longPress)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let window = window,
              let snapshot = messageContainerView.snapshotView(afterScreenUpdates: true)
        else { return }

        hideKeyboardHandler?()

        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .clear

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlay.bounds
        blurView.alpha = 0
        overlay.addSubview(blurView)

        let tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissOverlay(_:)))
        overlay.addGestureRecognizer(tapToDismiss)

        let cellFrameInWindow = messageContainerView.convert(messageContainerView.bounds, to: window)

        snapshot.frame = cellFrameInWindow
        snapshot.layer.cornerRadius = messageContainerView.layer.cornerRadius
        snapshot.clipsToBounds = true
        snapshot.layer.shadowColor = BasePalitColors.background.cgColor
        snapshot.layer.shadowOpacity = 0.2
        snapshot.layer.shadowOffset = CGSize(width: 0, height: 2)
        snapshot.layer.shadowRadius = 6
        overlay.addSubview(snapshot)

        let screenWidth = window.bounds.width
        let sidePadding: CGFloat = 24
        let bottomPadding: CGFloat = 40
        let topPadding: CGFloat = 60
        let menuWidth: CGFloat = screenWidth * 0.52

        var targetCenterX = cellFrameInWindow.midX
        if targetCenterX - (menuWidth / 2) < sidePadding {
            targetCenterX = sidePadding + (menuWidth / 2)
        }
        if targetCenterX + (menuWidth / 2) > screenWidth - sidePadding {
            targetCenterX = screenWidth - sidePadding - (menuWidth / 2)
        }

        let reactionsWidthEstimate = CGFloat(reactions.count) * 40 + 80
        var reactionsWidth = max(reactionsWidthEstimate, menuWidth * 0.9)
        reactionsWidth = min(reactionsWidth, screenWidth - sidePadding * 2)

        let reactionsContainer = UIView()
        reactionsContainer.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.96)
        reactionsContainer.layer.cornerRadius = 28
        overlay.addSubview(reactionsContainer)

        let reactionsStack = UIStackView()
        reactionsStack.axis = .horizontal
        reactionsStack.spacing = 20
        reactionsStack.distribution = .fillProportionally
        reactionsStack.alignment = .center

        for (index, item) in reactions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item.emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.7
            button.tag = index
            button.addTarget(self, action: #selector(selectReaction(_:)), for: .touchUpInside)
            reactionsStack.addArrangedSubview(button)
        }

        reactionsContainer.addSubview(reactionsStack)
        reactionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24))
        }

        let actionsContainer = UIView()
        actionsContainer.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.96)
        actionsContainer.layer.cornerRadius = 18
        actionsContainer.clipsToBounds = true
        overlay.addSubview(actionsContainer)

        let actionsStack = UIStackView()
        actionsStack.axis = .vertical
        actionsStack.spacing = 0

        let actionsData: [(title: String, image: String, destructive: Bool, handler: () -> Void)] = [
            ("Copy", "doc.on.doc", false, { [weak self] in
                guard let self = self else { return }
                if let textCell = self as? AIGFTextChatCell {
                    UIPasteboard.general.string = textCell.messageLabelText
                }
                self.dismissOverlay()
            }),
            ("Select Text", "text.cursor", false, { [weak self] in
                guard let self = self else { return }
                if let textCell = self as? AIGFTextChatCell {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        textCell.enableTextSelection()
                    }
                }
                self.dismissOverlay()
            }),
            ("Share", "square.and.arrow.up", false, { [weak self] in
                guard let self = self else { return }
                var activityItems: [Any] = []
                if let mediaCell = self as? MediaChatCell, let image = mediaCell.currentImage {
                    guard SubscriptionManager.shared.hasActiveSubscription else {
                        self.showSubsHandler?()
                        self.dismissOverlay()
                        return
                    }
                    activityItems.append(image)
                } else if let textCell = self as? AIGFTextChatCell, let text = textCell.messageLabelText {
                    activityItems.append(text)
                }

                if !activityItems.isEmpty, let vc = self.vc {
                    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.messageContainerView
                    vc.present(activityViewController, animated: true, completion: nil)
                }
                self.dismissOverlay()
            }),
            ("Delete", "trash", true, { [weak self] in
                guard let self = self else { return }
                AIGirlfriendMessagesManager().deleteMessage(id: self.messageID)
                self.reloadDataHandler?()
                self.dismissOverlay()
            })
        ]

        for (index, data) in actionsData.enumerated() {
            let button = createActionButton(title: data.title, imageName: data.image, destructive: data.destructive) { data.handler() }
            actionsStack.addArrangedSubview(button)
            if index < actionsData.count - 1 {
                let separator = UIView()
                separator.backgroundColor = BasePalitColors.separator.withAlphaComponent(0.6)
                separator.snp.makeConstraints { $0.height.equalTo(0.5) }
                actionsStack.addArrangedSubview(separator)
            }
        }

        actionsContainer.addSubview(actionsStack)
        actionsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }

        reactionsContainer.snp.makeConstraints { make in
            make.centerX.equalTo(overlay.snp.leading).offset(targetCenterX)
            make.width.equalTo(reactionsWidth)
            make.height.equalTo(60)
            make.bottom.equalTo(snapshot.snp.top).offset(-16).priority(.high)
            make.top.greaterThanOrEqualTo(overlay.snp.top).offset(topPadding).priority(.required)
        }

        actionsContainer.snp.makeConstraints { make in
            make.centerX.equalTo(overlay.snp.leading).offset(targetCenterX)
            make.width.equalTo(menuWidth)
            make.top.equalTo(snapshot.snp.bottom).offset(16).priority(.high)
            make.bottom.lessThanOrEqualTo(overlay.snp.bottom).offset(-bottomPadding).priority(.required)
        }

        window.addSubview(overlay)
        self.overlayView = overlay

        let startTransform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        reactionsContainer.transform = startTransform
        actionsContainer.transform = startTransform
        reactionsContainer.alpha = 0
        actionsContainer.alpha = 0

        UIView.animate(withDuration: 0.25) {
            blurView.alpha = 1.0
        }

        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.0, options: .curveEaseOut) {
            reactionsContainer.transform = .identity
            actionsContainer.transform = .identity
            reactionsContainer.alpha = 1.0
            actionsContainer.alpha = 1.0
            snapshot.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }
    }

    @objc private func dismissOverlay(_ gesture: UITapGestureRecognizer? = nil) {
        overlayView?.removeFromSuperview()
        overlayView = nil
        (self as? AIGFTextChatCell)?.disableTextSelection()
    }

    @objc private func selectReaction(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0 && index < reactions.count else { return }
        let selected = reactions[index]

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        AIGirlfriendMessagesManager().updateReaction(id: messageID, reaction: selected.id)
        reloadDataHandler?()
        dismissOverlay()

        if index == 0 || index == 1 || index == 3 {
            if RequestReviewManager.shared.needShowRateUsAfterTappedReactions() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
        }
    }

    private func createActionButton(title: String, imageName: String, destructive: Bool = false, handler: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = destructive ? BasePalitColors.accentRed : BasePalitColors.textPrimary
        button.setTitleColor(destructive ? BasePalitColors.accentRed : BasePalitColors.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }

    func iPadCheck() {
        guard isIPad() else { return }
        messageContainerView.layer.cornerRadius = 28
        avatarView.layer.cornerRadius = 26
    }
}
