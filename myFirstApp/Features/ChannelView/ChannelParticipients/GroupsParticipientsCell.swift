import UIKit
import SnapKit

class GroupsParticipientsCell: UITableViewCell {
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellUI() {
        backgroundColor = .clear
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        selectedBackgroundView = selectedView
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        nameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)
        
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = MyColors.primary
        contentView.addSubview(statusLabel)
        
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(10)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.leading)
            make.trailing.equalTo(nameLabel.snp.trailing)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
    }
    
    func configure(name: String, avatarName: String?, status: String, isUser: Bool) {
        nameLabel.text = name
        statusLabel.text = status
        
        if isUser {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .lightGray
            avatarImageView.backgroundColor = .clear
            statusLabel.textColor = MyColors.textSecondary
        } else {
            statusLabel.textColor = MyColors.primary
            if let avatar = avatarName, !avatar.isEmpty {
                let finalAvatarImage = (UIImage(named: APIManager.shared.isRemotePhoto ? (avatar + "_") : avatar)) ?? UIImage(named: avatar)
                avatarImageView.image = finalAvatarImage
            } else {
                avatarImageView.image = UIImage(named: "1")
            }
        }
    }
}
