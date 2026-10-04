import UIKit
import SnapKit

class DayCell: UICollectionViewCell {
    static let identifier = "DayCell"
    
    private let container: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        return v
    }()
    
    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = MyColors.textPrimary
        return l
    }()
    
    private let giftIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "gift.fill"))
        iv.tintColor = MyColors.gold
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(container)
        container.addSubview(label)
        container.addSubview(giftIcon)
        
        // Контейнер всегда квадратный и по центру ячейки: у всех дней одна линия по вертикали
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(container.snp.width)
        }
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        giftIcon.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(6)
            make.size.equalTo(14)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(day: Int, isCurrent: Bool, isPast: Bool) {
        label.text = "\(day)"
        giftIcon.isHidden = (day != 7)
        
        if isCurrent {
            // Сегодня: залитый акцент + светлое кольцо
            container.backgroundColor = MyColors.primary
            container.layer.borderWidth = 2
            container.layer.borderColor = MyColors.textPrimary.withAlphaComponent(0.9).cgColor
            container.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            label.textColor = MyColors.textPrimary
            label.font = .systemFont(ofSize: 17, weight: .bold)
        } else if isPast {
            // Прошедшие: мягкий тинт акцента, цифра в цвет акцента
            container.backgroundColor = MyColors.primary.withAlphaComponent(0.18)
            container.layer.borderWidth = 0
            container.transform = .identity
            label.textColor = MyColors.primary
            label.font = .systemFont(ofSize: 17, weight: .semibold)
        } else {
            // Будущие: «вдавленная» плитка; седьмой день подсвечен золотой рамкой
            container.backgroundColor = MyColors.background
            container.layer.borderWidth = 1
            container.layer.borderColor = (day == 7
                ? MyColors.gold.withAlphaComponent(0.6)
                : MyColors.separator).cgColor
            container.transform = .identity
            label.textColor = MyColors.textSecondary
            label.font = .systemFont(ofSize: 17, weight: .medium)
        }
    }
}
