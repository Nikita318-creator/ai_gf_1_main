//
//  RewardDayCell.swift
//  ChatBot20
//
//  Created by Mikita on 06/07/2026.
//

import UIKit
import SnapKit

class RewardDayCell: UICollectionViewCell {
    static let identifier = "RewardDayCell"
    
    private let container: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = UIColor(white: 1.0, alpha: 0.6)
        l.textAlignment = .center
        return l
    }()
    
    private let coinImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "bitcoinsign.circle.fill") // или твой кастомный коин
        iv.tintColor = .systemYellow
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(container)
        [titleLabel, coinImageView, countLabel].forEach { container.addSubview($0) }
        
        container.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.left.right.equalToSuperview().inset(4)
        }
        
        coinImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        
        countLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.left.right.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(day: Int, coins: Int, isCurrent: Bool, isPast: Bool) {
        titleLabel.text = "\("Day".localize()) \(day)"
        countLabel.text = "+\(coins)"
        
        if isCurrent {
            container.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
            container.layer.borderWidth = 2
            container.layer.borderColor = UIColor.white.cgColor
            container.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            titleLabel.textColor = .white
        } else if isPast {
            container.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.25)
            container.layer.borderWidth = 0
            container.transform = .identity
            titleLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        } else {
            container.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0)
            container.layer.borderWidth = 0
            container.transform = .identity
            titleLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        }
    }
}
