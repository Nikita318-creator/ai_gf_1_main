import UIKit
import SnapKit

class RewardDayCell: UICollectionViewCell {
    static let identifier = "RewardDayCell"
    
    private let container: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = MyColors.textSecondary
        l.textAlignment = .center
        return l
    }()
    
    private let coinImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "bitcoinsign.circle.fill") // или твой кастомный коин
        iv.tintColor = MyColors.gold
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .bold)
        l.textColor = MyColors.textPrimary
        l.textAlignment = .center
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(container)
        [titleLabel, coinImageView, countLabel].forEach { container.addSubview($0) }
        
        container.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview().inset(4)
        }
        
        coinImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(26)
        }
        
        countLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.left.right.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(day: Int, coins: Int, isCurrent: Bool, isPast: Bool) {
        titleLabel.text = "\("Day".localize()) \(day)"
        countLabel.text = "+\(coins)"
        
        if isCurrent {
            container.backgroundColor = MyColors.primary
            container.layer.borderWidth = 2
            container.layer.borderColor = MyColors.textPrimary.withAlphaComponent(0.9).cgColor
            container.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            titleLabel.textColor = MyColors.textPrimary.withAlphaComponent(0.85)
            countLabel.textColor = MyColors.textPrimary
            coinImageView.alpha = 1
        } else if isPast {
            container.backgroundColor = MyColors.primary.withAlphaComponent(0.18)
            container.layer.borderWidth = 0
            container.transform = .identity
            titleLabel.textColor = MyColors.textSecondary
            countLabel.textColor = MyColors.primary
            coinImageView.alpha = 0.55
        } else {
            container.backgroundColor = MyColors.background
            container.layer.borderWidth = 1
            container.layer.borderColor = MyColors.separator.cgColor
            container.transform = .identity
            titleLabel.textColor = MyColors.textSecondary
            countLabel.textColor = MyColors.textPrimary
            coinImageView.alpha = 1
        }
    }
}
