import UIKit

class AbstractChatCell: UITableViewCell {
    static let identifier = "AbstractChatCell"

    let emogis = ChatMessageReaction.allCases

    let emogisView: UIView = {
        let node = UIView()
        node.isHidden = true
        return node
    }()

    let emogisLabel: UILabel = {
        let textHolder = UILabel()
        textHolder.font = .systemFont(ofSize: 13)
        return textHolder
    }()

    let bobleView = UIView()
    let authorImageView = UIImageView()

    private var screenDimmerLayer: UIView?
    var currentMessageID = ""

    weak var vc: UIViewController?
    var needReloadTableHandler: (() -> Void)?
    var avatarTappedHandler: (() -> Void)?
    var hideKeyboardHandler: (() -> Void)?
    var openPaywallHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configurePrimaryCellStructure()
        setupSubviews()
        iPadCheck()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {}

    private func configurePrimaryCellStructure() {
        backgroundColor = .clear
        selectionStyle = .none

        bobleView.layer.cornerRadius = 18
        bobleView.layer.masksToBounds = false
        bobleView.layer.shadowColor = BasePalitColors.background.cgColor
        bobleView.layer.shadowOpacity = 0.1
        bobleView.layer.shadowOffset = CGSize(width: 0, height: 1)
        bobleView.layer.shadowRadius = 2
        contentView.addSubview(bobleView)

        authorImageView.contentMode = .scaleAspectFill
        authorImageView.backgroundColor = BasePalitColors.avatarBackground
        authorImageView.layer.cornerRadius = 18
        authorImageView.clipsToBounds = true
        authorImageView.isUserInteractionEnabled = true
        authorImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTriggerAvatarTap)))
        contentView.addSubview(authorImageView)

        contentView.addSubview(emogisView)
        emogisView.addSubview(emogisLabel)
        emogisLabel.snp.makeConstraints { layoutRef in
            layoutRef.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
        initializeInteractionGestures()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        emogisLabel.text = ""
        emogisView.isHidden = true
        authorImageView.image = nil
        authorImageView.isHidden = false
    }

    func updateBaseUI(isUserMessage: Bool, reaction: String?) {
        authorImageView.isHidden = isUserMessage
        bobleView.layer.maskedCorners = isUserMessage
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        if !isUserMessage {
            authorImageView.image = CellInteractionManager.shared.resolveAvatarImage(isUser: isUserMessage)
        }

        if let matchingTag = reaction,
           let reactionItem = ChatMessageReaction(rawValue: matchingTag) {
            emogisView.isHidden = false
            emogisLabel.text = reactionItem.symbol

            emogisView.snp.remakeConstraints { alignRef in
                alignRef.bottom.equalTo(bobleView.snp.bottom).offset(6)
                if isUserMessage {
                    alignRef.trailing.equalTo(bobleView.snp.trailing).offset(-8)
                } else {
                    alignRef.leading.equalTo(bobleView.snp.leading).offset(8)
                }
                alignRef.height.equalTo(22)
            }
        } else {
            emogisView.isHidden = true
        }
    }

    @objc private func didTriggerAvatarTap() {
        avatarTappedHandler?()
    }

    private func initializeInteractionGestures() {
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleCellInteraction(_:)))
        holdGesture.minimumPressDuration = 0.5
        bobleView.isUserInteractionEnabled = true
        bobleView.addGestureRecognizer(holdGesture)
    }

    @objc private func handleCellInteraction(_ pressRecognizer: UILongPressGestureRecognizer) {
        guard pressRecognizer.state == .began,
              let activeWindow = window,
              let frozenView = bobleView.snapshotView(afterScreenUpdates: true)
        else { return }

        hideKeyboardHandler?()

        let baseOverlay = UIView(frame: activeWindow.bounds)
        baseOverlay.backgroundColor = .clear

        let visualBlur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurContainer = UIVisualEffectView(effect: visualBlur)
        blurContainer.frame = baseOverlay.bounds
        blurContainer.alpha = 0
        baseOverlay.addSubview(blurContainer)

        let closeTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissActiveViewContext(_:)))
        baseOverlay.addGestureRecognizer(closeTapRecognizer)

        let targetBounds = bobleView.convert(bobleView.bounds, to: activeWindow)

        frozenView.frame = targetBounds
        frozenView.layer.cornerRadius = bobleView.layer.cornerRadius
        frozenView.clipsToBounds = true
        frozenView.layer.shadowColor = BasePalitColors.background.cgColor
        frozenView.layer.shadowOpacity = 0.2
        frozenView.layer.shadowOffset = CGSize(width: 0, height: 2)
        frozenView.layer.shadowRadius = 6
        baseOverlay.addSubview(frozenView)

        let totalWidth = activeWindow.bounds.width
        let edgeInsetVal: CGFloat = 24
        let bottomOffsetVal: CGFloat = 40
        let topOffsetVal: CGFloat = 60
        let calculatedMenuWidth: CGFloat = totalWidth * 0.52

        var centerXPosition = targetBounds.midX
        if centerXPosition - (calculatedMenuWidth / 2) < edgeInsetVal {
            centerXPosition = edgeInsetVal + (calculatedMenuWidth / 2)
        }
        if centerXPosition + (calculatedMenuWidth / 2) > totalWidth - edgeInsetVal {
            centerXPosition = totalWidth - edgeInsetVal - (calculatedMenuWidth / 2)
        }

        let calculatedReactionsWidth = CGFloat(emogis.count) * 40 + 80
        var finalReactionsWidth = max(calculatedReactionsWidth, calculatedMenuWidth * 0.9)
        finalReactionsWidth = min(finalReactionsWidth, totalWidth - edgeInsetVal * 2)

        let emoticonsWrapper = UIView()
        emoticonsWrapper.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.96)
        emoticonsWrapper.layer.cornerRadius = 28
        baseOverlay.addSubview(emoticonsWrapper)

        let horizontalEmoticonGroup = UIStackView()
        horizontalEmoticonGroup.axis = .horizontal
        horizontalEmoticonGroup.spacing = 20
        horizontalEmoticonGroup.distribution = .fillProportionally
        horizontalEmoticonGroup.alignment = .center

        for (itemIndex, emoteObject) in emogis.enumerated() {
            let actionBtn = UIButton(type: .system)
            actionBtn.setTitle(emoteObject.symbol, for: .normal)
            actionBtn.titleLabel?.font = .systemFont(ofSize: 20)
            actionBtn.titleLabel?.adjustsFontSizeToFitWidth = true
            actionBtn.titleLabel?.minimumScaleFactor = 0.7
            actionBtn.tag = itemIndex
            actionBtn.addTarget(self, action: #selector(didSelectReactionItem(_:)), for: .touchUpInside)
            horizontalEmoticonGroup.addArrangedSubview(actionBtn)
        }

        emoticonsWrapper.addSubview(horizontalEmoticonGroup)
        horizontalEmoticonGroup.snp.makeConstraints { makeRef in
            makeRef.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24))
        }

        let optionListContainer = UIView()
        optionListContainer.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.96)
        optionListContainer.layer.cornerRadius = 18
        optionListContainer.clipsToBounds = true
        baseOverlay.addSubview(optionListContainer)

        let verticalOptionGroup = UIStackView()
        verticalOptionGroup.axis = .vertical
        verticalOptionGroup.spacing = 0

        let menuConfiguration: [(title: String, image: String, destructive: Bool, handler: () -> Void)] = [
            ("Copy", "doc.on.doc", false, { [weak self] in
                guard let self = self else { return }
                if let stringContentCell = self as? TextChatCell {
                    UIPasteboard.general.string = stringContentCell.messageLabelText
                }
                self.dismissActiveViewContext()
            }),
            ("Select Text", "text.cursor", false, { [weak self] in
                guard let self = self else { return }
                if let stringContentCell = self as? TextChatCell {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        stringContentCell.enableTextSelection()
                    }
                }
                self.dismissActiveViewContext()
            }),
            ("Delete", "trash", true, { [weak self] in
                guard let self = self else { return }
                CellInteractionManager.shared.deleteChatMessage(id: self.currentMessageID) { [weak self] in
                    self?.needReloadTableHandler?()
                }
                self.dismissActiveViewContext()
            })
        ]

        for (pos, configItem) in menuConfiguration.enumerated() {
            let rowBtn = buildContextOptionButton(label: configItem.title, systemIcon: configItem.image, isDestructive: configItem.destructive) { configItem.handler() }
            verticalOptionGroup.addArrangedSubview(rowBtn)
            if pos < menuConfiguration.count - 1 {
                let dividerLine = UIView()
                dividerLine.backgroundColor = BasePalitColors.separator.withAlphaComponent(0.6)
                dividerLine.snp.makeConstraints { $0.height.equalTo(0.5) }
                verticalOptionGroup.addArrangedSubview(dividerLine)
            }
        }

        optionListContainer.addSubview(verticalOptionGroup)
        verticalOptionGroup.snp.makeConstraints { makeRef in
            makeRef.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }

        emoticonsWrapper.snp.makeConstraints { makeRef in
            makeRef.centerX.equalTo(baseOverlay.snp.leading).offset(centerXPosition)
            makeRef.width.equalTo(finalReactionsWidth)
            makeRef.height.equalTo(60)
            makeRef.bottom.equalTo(frozenView.snp.top).offset(-16).priority(.high)
            makeRef.top.greaterThanOrEqualTo(baseOverlay.snp.top).offset(topOffsetVal).priority(.required)
        }

        optionListContainer.snp.makeConstraints { makeRef in
            makeRef.centerX.equalTo(baseOverlay.snp.leading).offset(centerXPosition)
            makeRef.width.equalTo(calculatedMenuWidth)
            makeRef.top.equalTo(frozenView.snp.bottom).offset(16).priority(.high)
            makeRef.bottom.lessThanOrEqualTo(baseOverlay.snp.bottom).offset(-bottomOffsetVal).priority(.required)
        }

        activeWindow.addSubview(baseOverlay)
        self.screenDimmerLayer = baseOverlay

        let initialTransformScale = CGAffineTransform(scaleX: 0.85, y: 0.85)
        emoticonsWrapper.transform = initialTransformScale
        optionListContainer.transform = initialTransformScale
        emoticonsWrapper.alpha = 0
        optionListContainer.alpha = 0

        UIView.animate(withDuration: 0.25) {
            blurContainer.alpha = 1.0
        }

        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.0, options: .curveEaseOut) {
            emoticonsWrapper.transform = .identity
            optionListContainer.transform = .identity
            emoticonsWrapper.alpha = 1.0
            optionListContainer.alpha = 1.0
            frozenView.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        }
    }

    @objc private func dismissActiveViewContext(_ clickRecognizer: UITapGestureRecognizer? = nil) {
        screenDimmerLayer?.removeFromSuperview()
        screenDimmerLayer = nil
        (self as? TextChatCell)?.disableTextSelection()
    }

    @objc private func didSelectReactionItem(_ triggerSource: UIButton) {
        let indexPos = triggerSource.tag
        guard indexPos >= 0 && indexPos < emogis.count else { return }
        let selectedItem = emogis[indexPos]

        CellInteractionManager.shared.applyReactionSelection(messageID: currentMessageID, reaction: selectedItem) { [weak self] in
            self?.needReloadTableHandler?()
            self?.dismissActiveViewContext()
        }
    }

    private func buildContextOptionButton(label: String, systemIcon: String, isDestructive: Bool = false, handler: @escaping () -> Void) -> UIButton {
        let optionButton = UIButton(type: .system)
        optionButton.setTitle(label, for: .normal)
        optionButton.setImage(UIImage(systemName: systemIcon), for: .normal)
        optionButton.tintColor = isDestructive ? BasePalitColors.accentRed : BasePalitColors.textPrimary
        optionButton.setTitleColor(isDestructive ? BasePalitColors.accentRed : BasePalitColors.textPrimary, for: .normal)
        optionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        optionButton.contentHorizontalAlignment = .left
        optionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        optionButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        optionButton.addAction(UIAction { _ in handler() }, for: .touchUpInside)
        optionButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return optionButton
    }

    func iPadCheck() {
        guard isIPad() else { return }
        bobleView.layer.cornerRadius = 28
        authorImageView.layer.cornerRadius = 26
    }
}
