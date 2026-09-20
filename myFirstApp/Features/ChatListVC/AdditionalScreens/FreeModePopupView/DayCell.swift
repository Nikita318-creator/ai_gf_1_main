import UIKit
import SnapKit

class DayCell: UICollectionViewCell {
    static let identifier = "DayCell"
    
    private let container: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14 // Слегка увеличили скругление для современного вида
        return v
    }()
    
    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold) // Сделали аккуратнее вместо 18 Bold
        l.textColor = .white
        return l
    }()
    
    private let giftIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "gift.fill"))
        iv.tintColor = .systemYellow
        iv.isHidden = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(container)
        container.addSubview(label)
        container.addSubview(giftIcon)
        
        container.snp.makeConstraints { $0.edges.equalToSuperview() }
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        giftIcon.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(6)
            make.size.equalTo(14) // Уменьшили иконку, чтобы не лезла на цифру 7
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(day: Int, isCurrent: Bool, isPast: Bool) {
        label.text = "\(day)"
        giftIcon.isHidden = (day != 7)
        
        if isCurrent {
            container.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
            container.layer.borderWidth = 1.5 // Аккуратная тонкая обводка вместо жирной 2
            container.layer.borderColor = UIColor.white.cgColor
            container.transform = CGAffineTransform(scaleX: 1.05, y: 1.05) // Легкий элегантный скейл вместо 1.1
            label.font = .systemFont(ofSize: 16, weight: .bold)
        } else if isPast {
            container.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 0.25)
            container.layer.borderWidth = 0
            container.transform = .identity
            label.font = .systemFont(ofSize: 16, weight: .medium)
        } else {
            container.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // Telegram card background
            container.layer.borderWidth = 0
            container.transform = .identity
            label.font = .systemFont(ofSize: 16, weight: .medium)
        }
    }
}
