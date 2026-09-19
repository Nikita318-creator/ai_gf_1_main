//
//  SectionHeaderView.swift
//  ChatBot20
//
//  Created by Mikita on 14/06/2026.
//

import UIKit
import SnapKit

// MARK: - SectionHeaderView
class SectionHeaderView: UICollectionReusableView {
    
    struct Colors {
        static let primary          = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background       = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground   = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let textPrimary      = UIColor.white
        static let textSecondary    = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator        = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    static let identifier = "SectionHeaderView"

    private let stepBadge = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        stepBadge.font            = .systemFont(ofSize: 11, weight: .bold)
        stepBadge.textColor       = Colors.primary
        stepBadge.backgroundColor = Colors.primary.withAlphaComponent(0.12)
        stepBadge.layer.cornerRadius = 8
        stepBadge.clipsToBounds   = true
        stepBadge.textAlignment   = .center

        titleLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = Colors.textPrimary

        let stack = UIStackView(arrangedSubviews: [stepBadge, titleLabel])
        stack.axis      = .horizontal
        stack.spacing   = 10
        stack.alignment = .center
        addSubview(stack)

        stepBadge.snp.makeConstraints { make in
            make.width.equalTo(26)
            make.height.equalTo(22)
        }

        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, step: Int) {
        titleLabel.text = title
        stepBadge.text  = "\(step)"
    }
}
