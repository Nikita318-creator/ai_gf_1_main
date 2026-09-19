import UIKit
import SnapKit

class GroupChatListItemCell: UITableViewCell {

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
        backgroundColor = MyColors.background
        
        // Настраиваем красивое нативное выделение при нажатии (как в ТГ)
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        selectedBackgroundView = selectedView

        // 1. Аватарка без всяких подложек и рамок
        avatarImageView.contentMode = .scaleAspectFill
        let avatarSize: CGFloat = isCurrentDeviceiPad() ? 76 : 54
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)

        // 2. Название чата
        titleLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 24 : 17, weight: .semibold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.numberOfLines = 3
        contentView.addSubview(titleLabel)

        // 3. Последнее сообщение
        lastMessageLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 20 : 15, weight: .regular)
        lastMessageLabel.textColor = MyColors.textSecondary
        lastMessageLabel.numberOfLines = 2
        contentView.addSubview(lastMessageLabel)

        // 4. Время сообщения
        timeLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 16 : 13, weight: .regular)
        timeLabel.textColor = MyColors.textSecondary
        contentView.addSubview(timeLabel)

        // 5. Точка непрочитанного сообщения
        unreadIndicator.backgroundColor = MyColors.primary
        unreadIndicator.layer.cornerRadius = 4.5
        unreadIndicator.isHidden = true
        contentView.addSubview(unreadIndicator)

        // 6. Аккуратный ТГ-сепаратор
        separatorView.backgroundColor = MyColors.separator
        contentView.addSubview(separatorView)

        // MARK: - Constraints
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(40) // Оставляем место под бадж справа
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }
        
        unreadIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(lastMessageLabel)
            make.width.height.equalTo(9)
        }

        separatorView.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.leading) // Сепаратор начинается ровно под текстом
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
