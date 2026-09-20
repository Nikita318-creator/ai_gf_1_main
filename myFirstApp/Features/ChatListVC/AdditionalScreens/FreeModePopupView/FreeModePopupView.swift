import UIKit
import SnapKit

class FreeModePopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let currentDay: Int
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // Идеальный Telegram Card BG
        view.layer.cornerRadius = 24
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8 // Сделали зазоры чуть плотнее для компактности
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(DayCell.self, forCellWithReuseIdentifier: DayCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return cv
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "1"))
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        return iv
    }()
    
    private let infoLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 17, weight: .regular) // Оптимальный читаемый размер вместо огромного 22 Medium
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold) // Стильный системный размер вместо огромного 24
        btn.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        btn.layer.cornerRadius = 14
        return btn
    }()

    init(currentDay: Int) {
        self.currentDay = currentDay
        super.init(frame: .zero)
        setupUI()
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: max(0, currentDay - 1), section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.75) // Чуть-чуть углубили блёр задника
        addSubview(containerView)
        [iconImageView, collectionView, infoLabel, closeButton].forEach { containerView.addSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.92) // Сделали чуть шире экрана, чтобы коллекции было свободнее
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(64) // Сделали 64 вместо 70 для аккуратности
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(72) // Скорректировали высоту под уменьшенные ячейки
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(24) // Больше воздуха по бокам для красивого переноса строк
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(24)
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(48) // Стандартная аккуратная высота кнопки вместо 50
        }
        
        closeButton.setTitle("Streak.GotIt".localize(), for: .normal)
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        infoLabel.text = currentDay == 7 ? "FreeMode.MessageOnDay7".localize() : "FreeMode.Message".localize()
    }
    
    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.identifier, for: indexPath) as! DayCell
        let day = indexPath.item + 1
        cell.configure(day: day, isCurrent: day == currentDay, isPast: day < currentDay)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let day = indexPath.item + 1
        // Уменьшили размеры (54х54 для обычных и 64х64 для праздничного), теперь смотрится органично
        return day == 7 ? CGSize(width: 64, height: 64) : CGSize(width: 54, height: 54)
    }
    
    @objc private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
