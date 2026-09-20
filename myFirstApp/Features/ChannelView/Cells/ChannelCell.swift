import UIKit
import SnapKit

class ChannelCell: UITableViewCell {

    static let identifier = "ChatListItemCell"
    
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadIndicator = UIView()
    private let separatorView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTelegramStyle()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupTelegramStyle() {
        backgroundColor = .clear
        
        let selectedView = UIView()
        selectedView.backgroundColor = MyColors.selectedOption
        selectedBackgroundView = selectedView

        // 1. Аватарка
        avatarImageView.contentMode = .scaleAspectFill
        let avatarSize: CGFloat = isCurrentDeviceiPad() ? 76 : 54
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)

        // 2. Название чата
        titleLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 20 : 17, weight: .semibold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)

        // 3. Последнее сообщение
        lastMessageLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 17 : 15, weight: .regular)
        lastMessageLabel.textColor = MyColors.textSecondary
        lastMessageLabel.numberOfLines = 2
        contentView.addSubview(lastMessageLabel)

        // 4. Время сообщения
        timeLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 15 : 13, weight: .regular)
        timeLabel.textColor = MyColors.textSecondary
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)

        // 5. Точка непрочитанного сообщения
        unreadIndicator.backgroundColor = MyColors.unreadBadge
        unreadIndicator.layer.cornerRadius = 4.5
        unreadIndicator.isHidden = true
        contentView.addSubview(unreadIndicator)

        // 6. Сепаратор (четко по линии текста, как в ТГ)
        separatorView.backgroundColor = MyColors.separator.withAlphaComponent(0.6)
        contentView.addSubview(separatorView)

        // MARK: - Constraints
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.top).offset(2)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top).offset(2)
            make.trailing.equalToSuperview().inset(16)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(40)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }
        
        unreadIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(timeLabel.snp.bottom).offset(6)
            make.width.height.equalTo(9)
        }

        separatorView.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.leading)
            make.height.equalTo(0.5)
        }
    }

    func configure(with chat: ChatModel) {
        titleLabel.text = chat.assistantName
        lastMessageLabel.text = chat.lastMessage
        timeLabel.text = chat.lastMessageTime
        avatarImageView.image = UIImage(named: chat.assistantAvatar)
    }
    
    func setUnread(_ isUnread: Bool) {
        unreadIndicator.isHidden = !isUnread
    }
}
