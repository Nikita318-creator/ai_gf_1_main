import UIKit
import SnapKit

struct ChatModel {
    let id: String
    let assistantName: String
    let lastMessage: String
    let lastMessageTime: String
    let assistantAvatar: String
    let isPremium: Bool
}

class ChatListItemCell: UITableViewCell {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
        static let unreadBadge = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
    }

    static let identifier = "ChatListItemCell"

    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let lastMessageLabel = UILabel()
    private let timeLabel = UILabel()
    private let separatorView = UIView()
    
    // Новые элементы для значка непрочитанных сообщений
    private let unreadBadgeView = UIView()
    private let unreadCountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPremium() {
        timeLabel.text = "premiumAssistant.Label".localize()
    }

    func setMilf() {
        timeLabel.text = "Milf 🍷"
    }
    
    func setVoice() {
        timeLabel.text = "voiceAssistant.Label".localize()
    }

    func setEx() {
        timeLabel.text = "exAssistant.Label".localize()
    }
    
    func setRole(_ role: String) {
        timeLabel.text = role + " ❤️"
    }
    
    /// Обновляет значок непрочитанных сообщений в ячейке.
    /// - Parameter count: Количество непрочитанных сообщений.
    func setUnread(count: Int = 1) {
        if count > 0 {
            unreadBadgeView.isHidden = false
            unreadCountLabel.isHidden = false
            unreadCountLabel.text = "\(count)"
        }
    }

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        let containerView = UIView()
        containerView.backgroundColor = TelegramColors.cardBackground
        containerView.layer.cornerRadius = 10
        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 25 // Половина ширины/высоты для круга
        avatarImageView.clipsToBounds = true
        containerView.addSubview(avatarImageView)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = TelegramColors.textPrimary
        containerView.addSubview(titleLabel)

        lastMessageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        lastMessageLabel.textColor = TelegramColors.textSecondary
        lastMessageLabel.numberOfLines = 1 // Одна строка для последнего сообщения
        containerView.addSubview(lastMessageLabel)

        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        timeLabel.textColor = TelegramColors.textSecondary
        containerView.addSubview(timeLabel)
        
        // --- Настройка значка непрочитанных сообщений ---
        unreadBadgeView.backgroundColor = TelegramColors.unreadBadge
        unreadBadgeView.layer.cornerRadius = 10 // Половина высоты для круглого значка
        containerView.addSubview(unreadBadgeView)

        unreadCountLabel.textColor = .white
        unreadCountLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        unreadCountLabel.textAlignment = .center
        unreadBadgeView.addSubview(unreadCountLabel)
        // ------------------------------------------------

        separatorView.isHidden = true
        separatorView.backgroundColor = TelegramColors.separator
        containerView.addSubview(separatorView)

        // Constraints
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.top).offset(4)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalTo(timeLabel.snp.leading).offset(-8)
        }

        lastMessageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-4)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top)
            make.trailing.equalToSuperview().inset(16)
        }

        // --- Constraints для значка непрочитанных сообщений ---
        unreadBadgeView.snp.makeConstraints { make in
            make.centerY.equalTo(lastMessageLabel.snp.centerY)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
            // Ширина будет зависеть от содержимого, но мы зададим минимальную
            make.width.greaterThanOrEqualTo(20)
        }

        unreadCountLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }
        // -------------------------------------------------------

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func configure(with chat: ChatModel) { // Предполагаем, что у тебя есть ChatModel
        titleLabel.text = chat.assistantName
        lastMessageLabel.text = chat.lastMessage
        timeLabel.text = chat.lastMessageTime // Нужно будет отформатировать время - не юзаю это вообще
        avatarImageView.backgroundColor = TelegramColors.primary // Заглушка, если нет аватаров
        
        if MainHelper.shared.isMode {
            if chat.assistantAvatar.contains("ind1") {
                avatarImageView.image = UIImage(named: "ind5")
            } else if chat.assistantAvatar.contains("latina16") {
                avatarImageView.image = UIImage(named: "latina11")
            } else if chat.assistantAvatar == "1" {
                avatarImageView.image = UIImage(named: "pic109")
            } else if chat.assistantAvatar == "5" {
                avatarImageView.image = UIImage(named: "photo113")
            } else if chat.assistantAvatar == "6" {
                avatarImageView.image = UIImage(named: "photo57")
            } else {
                avatarImageView.image = UIImage(named: chat.assistantAvatar)
            }
        } else {
            avatarImageView.image = UIImage(named: chat.assistantAvatar)
        }
        
        unreadBadgeView.isHidden = true
        unreadCountLabel.isHidden = true
    }
}

extension ChatListItemCell {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }
        
        titleLabel.font = UIFont.systemFont(ofSize: 27, weight: .semibold)
        lastMessageLabel.font = UIFont.systemFont(ofSize: 25, weight: .regular)
        timeLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        unreadCountLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)

        avatarImageView.layer.cornerRadius = 40
        unreadBadgeView.layer.cornerRadius = 15
        
        avatarImageView.snp.updateConstraints { make in
            make.width.height.equalTo(80)
        }
        
        unreadBadgeView.snp.updateConstraints { make in
            make.height.equalTo(30)
            // Ширина будет зависеть от содержимого, но мы зададим минимальную
            make.width.greaterThanOrEqualTo(30)
        }
    }
    
    func configureForAd(title: String, message: String, avatarName: String) {
        titleLabel.text = title
        lastMessageLabel.text = message
        timeLabel.text = "18+"
        
        if let adImage = UIImage(named: avatarName) {
            avatarImageView.image = adImage
        } else {
            avatarImageView.image = nil
            avatarImageView.backgroundColor = TelegramColors.primary
        }
        
        unreadBadgeView.isHidden = true
        unreadCountLabel.isHidden = true
    }
}
