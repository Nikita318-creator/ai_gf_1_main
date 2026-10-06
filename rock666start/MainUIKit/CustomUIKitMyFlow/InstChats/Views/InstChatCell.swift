import UIKit
import SnapKit

struct InstChatDataModel {
    let id: String
    let assistantName: String
    let lastMessage: String
    let lastMessageTime: String
    let assistantAvatar: String
}

class InstChatCell: UITableViewCell {
    static let identifier = "InstChatCell"

    private let mainWrapperView = UIView()
    private let profileImageView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let previewMessageLabel = UILabel()
    private let timestampLabel = UILabel()
    private let bottomDividerView = UIView()
    
    private let pendingBadgeContainer = UIView()
    private let pendingCountTextLabel = UILabel()
    
    private var badgeSpacingConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initializeComponentLayout()
        iPadCheck()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUnread(count: Int = 1) {
        if count > 0 {
            pendingBadgeContainer.isHidden = false
            pendingCountTextLabel.isHidden = false
            pendingCountTextLabel.text = "\(count)"
            badgeSpacingConstraint?.activate()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let targetBgColor = highlighted ? BasePalitColors.cardBackground : BasePalitColors.background
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.mainWrapperView.backgroundColor = targetBgColor
            }
        } else {
            mainWrapperView.backgroundColor = targetBgColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mainWrapperView.backgroundColor = BasePalitColors.background
    }

    private func initializeComponentLayout() {
        timestampLabel.isHidden = true
        
        backgroundColor = BasePalitColors.background
        selectionStyle = .none

        mainWrapperView.backgroundColor = BasePalitColors.background
        contentView.addSubview(mainWrapperView)

        mainWrapperView.snp.makeConstraints { layoutMaker in
            layoutMaker.top.bottom.equalToSuperview()
            layoutMaker.leading.trailing.equalToSuperview()
        }

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 27
        profileImageView.clipsToBounds = true
        mainWrapperView.addSubview(profileImageView)

        headerTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        headerTitleLabel.textColor = BasePalitColors.textPrimary
        mainWrapperView.addSubview(headerTitleLabel)

        previewMessageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        previewMessageLabel.textColor = BasePalitColors.textSecondary
        previewMessageLabel.numberOfLines = 1
        mainWrapperView.addSubview(previewMessageLabel)

        timestampLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timestampLabel.textColor = BasePalitColors.textSecondary
        mainWrapperView.addSubview(timestampLabel)
        
        pendingBadgeContainer.backgroundColor = BasePalitColors.unreadBadge
        pendingBadgeContainer.layer.cornerRadius = 11
        mainWrapperView.addSubview(pendingBadgeContainer)

        pendingCountTextLabel.textColor = BasePalitColors.textPrimary
        pendingCountTextLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        pendingCountTextLabel.textAlignment = .center
        pendingBadgeContainer.addSubview(pendingCountTextLabel)

        bottomDividerView.isHidden = false
        bottomDividerView.backgroundColor = BasePalitColors.separator.withAlphaComponent(0.6)
        mainWrapperView.addSubview(bottomDividerView)

        profileImageView.snp.makeConstraints { layoutMaker in
            layoutMaker.leading.equalToSuperview().inset(16)
            layoutMaker.centerY.equalToSuperview()
            layoutMaker.width.height.equalTo(54)
        }

        headerTitleLabel.snp.makeConstraints { layoutMaker in
            layoutMaker.top.equalTo(profileImageView.snp.top).offset(3)
            layoutMaker.leading.equalTo(profileImageView.snp.trailing).offset(12)
            layoutMaker.trailing.equalTo(timestampLabel.snp.leading).offset(-8)
        }

        previewMessageLabel.snp.makeConstraints { layoutMaker in
            layoutMaker.bottom.equalTo(profileImageView.snp.bottom).offset(-3)
            layoutMaker.leading.equalTo(profileImageView.snp.trailing).offset(12)
            layoutMaker.trailing.lessThanOrEqualToSuperview().inset(16)
            badgeSpacingConstraint = layoutMaker.trailing.lessThanOrEqualTo(pendingBadgeContainer.snp.leading).offset(-8).constraint
        }
        badgeSpacingConstraint?.deactivate()

        timestampLabel.snp.makeConstraints { layoutMaker in
            layoutMaker.top.equalTo(headerTitleLabel.snp.top)
            layoutMaker.trailing.equalToSuperview().inset(16)
        }

        pendingBadgeContainer.snp.makeConstraints { layoutMaker in
            layoutMaker.centerY.equalTo(previewMessageLabel.snp.centerY)
            layoutMaker.trailing.equalToSuperview().inset(16)
            layoutMaker.height.equalTo(22)
            layoutMaker.width.greaterThanOrEqualTo(22)
        }

        pendingCountTextLabel.snp.makeConstraints { layoutMaker in
            layoutMaker.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7))
        }

        bottomDividerView.snp.makeConstraints { layoutMaker in
            layoutMaker.leading.equalTo(headerTitleLabel.snp.leading)
            layoutMaker.trailing.bottom.equalToSuperview()
            layoutMaker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func configure(with chat: InstChatDataModel) {
        headerTitleLabel.text = chat.assistantName
        previewMessageLabel.text = chat.lastMessage
        timestampLabel.text = chat.lastMessageTime
        profileImageView.backgroundColor = BasePalitColors.primary
        profileImageView.image = UIImage(named: chat.assistantAvatar)

        pendingBadgeContainer.isHidden = true
        pendingCountTextLabel.isHidden = true
        badgeSpacingConstraint?.deactivate()
    }
}

extension InstChatCell {
    func iPadCheck() {
        guard isIPad() else { return }
        
        headerTitleLabel.font = UIFont.systemFont(ofSize: 27, weight: .semibold)
        previewMessageLabel.font = UIFont.systemFont(ofSize: 25, weight: .regular)
        timestampLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        pendingCountTextLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)

        profileImageView.layer.cornerRadius = 44
        pendingBadgeContainer.layer.cornerRadius = 15
        
        profileImageView.snp.updateConstraints { layoutMaker in
            layoutMaker.width.height.equalTo(88)
        }
        
        pendingBadgeContainer.snp.updateConstraints { layoutMaker in
            layoutMaker.height.equalTo(30)
            layoutMaker.width.greaterThanOrEqualTo(30)
        }
    }
}
