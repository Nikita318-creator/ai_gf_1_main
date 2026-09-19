//
//  SelectableTagCell.swift
//  ChatBot20
//
//  Created by Mikita on 14/06/2026.
//

import UIKit
import SnapKit

// MARK: - SelectableTagCell
class SelectableTagCell: UICollectionViewCell {
    
    struct Colors {
        static let primary          = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background       = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground   = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let textPrimary      = UIColor.white
        static let textSecondary    = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator        = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    static let identifier = "SelectableTagCell"
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth  = 1

        contentView.addSubview(titleLabel)
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String, isSelected: Bool) {
        titleLabel.text = text
        if isSelected {
            titleLabel.textColor           = .white
            contentView.backgroundColor    = Colors.primary
            contentView.layer.borderColor  = Colors.primary.cgColor
        } else {
            titleLabel.textColor           = Colors.textSecondary
            contentView.backgroundColor    = Colors.cardBackground
            contentView.layer.borderColor  = Colors.separator.cgColor
        }
    }
}
