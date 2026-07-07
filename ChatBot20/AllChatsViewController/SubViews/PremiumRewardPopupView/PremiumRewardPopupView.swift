//
//  PremiumRewardPopupView.swift
//  ChatBot20
//
//  Created by Mikita on 06/07/2026.
//

import UIKit
import SnapKit

class PremiumRewardPopupView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let currentDay: Int
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        view.layer.cornerRadius = 24
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "sparkles"))
        iv.tintColor = .systemYellow
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let infoLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = .white
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        return l
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
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
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        btn.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        btn.layer.cornerRadius = 16
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
        backgroundColor = UIColor.black.withAlphaComponent(0.75)
        addSubview(containerView)
        [iconImageView, infoLabel, collectionView, claimButton].forEach { containerView.addSubview($0) }
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.92)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(64)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(85)
        }
        
        claimButton.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(24)
            make.left.right.bottom.equalToSuperview().inset(20)
            make.height.equalTo(54)
        }
        
        let todayCoins = PremiumRewardPopupView.getCoins(for: currentDay)
        infoLabel.text = "".localize(attribut: "PremiumDailyReward", arguments: "\(todayCoins)")
        claimButton.setTitle("".localize(attribut: "Claim", arguments: "\(todayCoins)"), for: .normal)
        claimButton.addTarget(self, action: #selector(claimButtonTapped), for: .touchUpInside)
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
    
    @objc private func claimButtonTapped() {        
        UIView.animate(withDuration: 0.2, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
