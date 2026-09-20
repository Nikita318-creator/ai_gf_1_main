import UIKit
import SnapKit

class FreeModePopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let currentDay: Int
    private var didAnimateIn = false
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(DayCell.self, forCellWithReuseIdentifier: DayCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return cv
    }()
    
    // Кольцо вокруг аватарки (зазор между кольцом и картинкой, как у сторис)
    private let iconRingView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.cornerRadius = 44
        v.layer.borderWidth = 2
        v.layer.borderColor = MyColors.primary.cgColor
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: APIManager.shared.isRemotePhoto ? "firstFoto_" : "firstFoto"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 39
        iv.backgroundColor = MyColors.background
        return iv
    }()
    
    private let infoLabel: UILabel = {
        let l = UILabel()
        l.textColor = MyColors.textPrimary
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(MyColors.textPrimary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = MyColors.primary
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
        backgroundColor = MyColors.background.withAlphaComponent(0.8)
        addSubview(containerView)
        containerView.addSubview(iconRingView)
        iconRingView.addSubview(iconImageView)
        [collectionView, infoLabel, closeButton].forEach { containerView.addSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.92).priority(.high)
            make.width.lessThanOrEqualTo(480) // на iPad карточка не растягивается на весь экран
        }
        
        iconRingView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(88)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(78)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(iconRingView.snp.bottom).offset(22)
            make.left.right.equalToSuperview()
            make.height.equalTo(72)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(24)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(24)
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        closeButton.setTitle("Streak.GotIt".localize(), for: .normal)
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        
        infoLabel.text = currentDay == 7 ? "FreeMode.MessageOnDay7".localize() : "FreeMode.Message".localize()
    }
    
    // Одно мягкое появление карточки. Сам попап (alpha) анимируется снаружи, его не трогаем
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil, !didAnimateIn else { return }
        didAnimateIn = true
        
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4, options: .curveEaseOut) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
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
        // Высота у всех 64 (плитка внутри ячейки центрируется), день 7 шире
        return day == 7 ? CGSize(width: 64, height: 64) : CGSize(width: 54, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }
    
    @objc private func dismiss() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
