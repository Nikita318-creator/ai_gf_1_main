import UIKit
import SnapKit

class FreeModePopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let currentDay: Int
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(DayCell.self, forCellWithReuseIdentifier: DayCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return cv
    }()
    
    // Остальные UI элементы (iconImageView, infoLabel, closeButton) оставляем как в прошлом примере...
    private let iconImageView = UIImageView(image: UIImage(named: "1"))
    private let infoLabel = UILabel() // Настрой текст как в прошлом примере
    private let closeButton = UIButton(type: .system)

    init(currentDay: Int) {
        self.currentDay = currentDay
        super.init(frame: .zero)
        setupUI()
        
        // Авто-скролл к текущему дню после отрисовки
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: max(0, currentDay - 1), section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        addSubview(containerView)
        [iconImageView, collectionView, infoLabel, closeButton].forEach { containerView.addSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.9)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(25)
            make.centerX.equalToSuperview()
            make.size.equalTo(70)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(80) // Фиксированная высота для ячеек
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(25)
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        closeButton.setTitle("Streak.GotIt".localize(), for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        closeButton.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        closeButton.layer.cornerRadius = 15
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        infoLabel.text = currentDay == 7 ? "FreeMode.MessageOnDay7".localize() : "FreeMode.Message".localize()
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .white
        infoLabel.font = .systemFont(ofSize: 22, weight: .medium)
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
        return day == 7 ? CGSize(width: 75, height: 75) : CGSize(width: 60, height: 60)
    }
    
    @objc private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
