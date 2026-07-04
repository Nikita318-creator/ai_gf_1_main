//
//  AvatarTemplateCell.swift
//  ChatBot20
//
//  Created by Mikita on 29.07.25.
//

import UIKit
import SnapKit

class AvatarTemplateCell: UICollectionViewCell {
    static let identifier = "AvatarTemplateCell"
    
    private let avatarImageView = UIImageView()
    private let overlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 35
        contentView.addSubview(avatarImageView)
        
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        overlayView.layer.cornerRadius = 35
        overlayView.clipsToBounds = true
        overlayView.isHidden = true
        contentView.addSubview(overlayView)
        
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with imageName: String, isAvailable: Bool) {
        avatarImageView.image = UIImage(named: imageName)
        overlayView.isHidden = isAvailable
    }
}
