//
//  MemberCell.swift
//  ChatBot20
//
//  Created by Mikita on 09/06/2026.
//

import UIKit
import SnapKit

// MARK: - Кастомная ячейка участника
class MemberCell: UITableViewCell {
    
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
        selectionStyle = .none
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)
        
        statusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = GroupMembersViewController.Colors.accent // Светится голубым в стиле ТГ
        contentView.addSubview(statusLabel)
        
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(8)
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
            statusLabel.textColor = GroupMembersViewController.Colors.textSecondary
        } else {
            statusLabel.textColor = GroupMembersViewController.Colors.accent
            if let avatar = avatarName, !avatar.isEmpty {
                let finalAvatarImage = (UIImage(named: ConfigService.shared.isRemotePhoto ? (avatar + "_") : avatar)) ?? UIImage(named: avatar)
                avatarImageView.image = finalAvatarImage
            } else {
                avatarImageView.image = UIImage(named: "1")
            }
        }
    }
}
