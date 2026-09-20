import UIKit
import SnapKit

class PremiumRewardPopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
    // Иконка в мягком золотом круге
    private let iconBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = MyColors.gold.withAlphaComponent(0.15)
        v.layer.cornerRadius = 44
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "sparkles"))
        iv.tintColor = MyColors.gold
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let infoLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = MyColors.textPrimary
        l.font = .systemFont(ofSize: 19, weight: .semibold)
        return l
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(RewardDayCell.self, forCellWithReuseIdentifier: RewardDayCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return cv
    }()
    
    private let claimButton: UIButton = {
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
    
    static func getCoins(for day: Int) -> Int {
        if day == 7 { return 70 }
        return day * 5
    }
    
    private func setupUI() {
        backgroundColor = MyColors.background.withAlphaComponent(0.8)
        addSubview(containerView)
        containerView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        [infoLabel, collectionView, claimButton].forEach { containerView.addSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.92).priority(.high)
            make.width.lessThanOrEqualTo(480) // на iPad карточка не растягивается на весь экран
        }
        
        iconBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(88)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(44)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(18)
            make.left.right.equalToSuperview().inset(24)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(85)
        }
        
        claimButton.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(24)
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        let todayCoins = PremiumRewardPopupView.getCoins(for: currentDay)
        infoLabel.text = "".localize(attribut: "PremiumDailyReward", arguments: "\(todayCoins)")
        claimButton.setTitle("".localize(attribut: "Claim", arguments: "\(todayCoins)"), for: .normal)
        claimButton.addTarget(self, action: #selector(claimButtonTapped), for: .touchUpInside)
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RewardDayCell.identifier, for: indexPath) as! RewardDayCell
        let day = indexPath.item + 1
        let coins = PremiumRewardPopupView.getCoins(for: day)
        cell.configure(day: day, coins: coins, isCurrent: day == currentDay, isPast: day < currentDay)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 64, height: 75)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    @objc private func claimButtonTapped() {
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
