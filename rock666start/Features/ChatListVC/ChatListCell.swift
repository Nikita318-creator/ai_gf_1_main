import UIKit
import SnapKit

struct ChatModel {
    let id: String
    let assistantName: String
    let lastMessage: String
    let lastMessageTime: String
    let assistantAvatar: String
}

class ChatListCell: UITableViewCell {
    static let identifier = "ChatListCell"

    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let separatorView = UIView()
    
    private let unreadBadgeView = UIView()
    private let unreadCountLabel = UILabel()
    
    /// Активен только когда виден бейдж, чтобы текст превью не заезжал под него
    private var messageToBadgeConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        iPadCheck()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUnread(count: Int = 1) {
        if count > 0 {
            unreadBadgeView.isHidden = false
            unreadCountLabel.isHidden = false
            unreadCountLabel.text = "\(count)"
            messageToBadgeConstraint?.activate()
        }
    }
    
    // MARK: - Press highlight (как в Telegram: строка мягко подсвечивается при нажатии)
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let color = highlighted ? BasePalitColors.cardBackground : BasePalitColors.background
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.containerView.backgroundColor = color
            }
        } else {
            containerView.backgroundColor = color
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.backgroundColor = BasePalitColors.background
    }

    private func setupViews() {
        timeLabel.isHidden = true
        
        // Ячейка непрозрачная, чтобы свайп-действие не просвечивало
        backgroundColor = BasePalitColors.background
        selectionStyle = .none

        containerView.backgroundColor = BasePalitColors.background
        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 27
        avatarImageView.clipsToBounds = true
        containerView.addSubview(avatarImageView)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = BasePalitColors.textPrimary
        containerView.addSubview(titleLabel)

        lastMessageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        lastMessageLabel.textColor = BasePalitColors.textSecondary
        lastMessageLabel.numberOfLines = 1
        containerView.addSubview(lastMessageLabel)

        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = BasePalitColors.textSecondary
        containerView.addSubview(timeLabel)
        
        unreadBadgeView.backgroundColor = BasePalitColors.unreadBadge
        unreadBadgeView.layer.cornerRadius = 11
        containerView.addSubview(unreadBadgeView)

        unreadCountLabel.textColor = BasePalitColors.textPrimary
        unreadCountLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        unreadCountLabel.textAlignment = .center
        unreadBadgeView.addSubview(unreadCountLabel)

        // Тонкий разделитель, начинается от текста (а не от края экрана)
        separatorView.isHidden = false
        separatorView.backgroundColor = BasePalitColors.separator.withAlphaComponent(0.6)
        containerView.addSubview(separatorView)

        // Constraints
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(54)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.top).offset(3)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-3)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            messageToBadgeConstraint = make.trailing.lessThanOrEqualTo(unreadBadgeView.snp.leading).offset(-8).constraint
        }
        messageToBadgeConstraint?.deactivate()

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top)
            make.trailing.equalToSuperview().inset(16)
        }

        unreadBadgeView.snp.makeConstraints { make in
            make.centerY.equalTo(lastMessageLabel.snp.centerY)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(22)
        }

        unreadCountLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 7, bottom: 2, right: 7))
        }

        separatorView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func configure(with chat: ChatModel) {
        titleLabel.text = chat.assistantName
        lastMessageLabel.text = chat.lastMessage
        timeLabel.text = chat.lastMessageTime
        avatarImageView.backgroundColor = BasePalitColors.primary
        avatarImageView.image = (UIImage(named: !BackendService.shared.currentData.aiText.isEmpty ? (chat.assistantAvatar + "_") : chat.assistantAvatar)) ?? UIImage(named: chat.assistantAvatar)

        unreadBadgeView.isHidden = true
        unreadCountLabel.isHidden = true
        messageToBadgeConstraint?.deactivate()
    }
}

extension ChatListCell {
    func iPadCheck() {
        guard isIPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 27, weight: .semibold)
        lastMessageLabel.font = UIFont.systemFont(ofSize: 25, weight: .regular)
        timeLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        unreadCountLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)

        avatarImageView.layer.cornerRadius = 44
        unreadBadgeView.layer.cornerRadius = 15
        
        avatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(88)
        }
        
        unreadBadgeView.snp.updateConstraints { make in
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(30)
        }
    }
}
