//
//  SplashScreenView.swift
//  ChatBot20
//
//  Created by Mikita on 17.06.25.
//

import UIKit
import SnapKit

class SplashScreenView: UIView {

    // MARK: - Subviews
    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "7"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        // Настройка рамочки (border)
        // Используется предполагаемый инициализатор UIColor(hex:)
        imageView.layer.borderColor = UIColor(hex: "#8A2BE2").cgColor
        imageView.layer.borderWidth = 3

        // Настройка скругленных углов (cornerRadius)
        imageView.layer.cornerRadius = 20
        
        return imageView
    }()

    private let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear

        // Настройка тени для контейнера
        // Используется предполагаемый инициализатор UIColor(hex:)
        view.layer.shadowColor = UIColor(hex: "#8A2BE2").cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 15
        view.layer.shadowOpacity = 0.7
        
        return view
    }()

    private let appNameLabel: UILabel = {
        let label = UILabel()
        if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            label.text = displayName
        } else if let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            label.text = bundleName
        } else {
            label.text = "GF"
        }
        
        label.numberOfLines = 0
        label.textColor = .white
        
        // Настройки шрифта и тени (СВЕЧЕНИЕ)
        label.font = UIFont.systemFont(ofSize: 36, weight: .heavy)
        label.textAlignment = .center

        // Используется предполагаемый инициализатор UIColor(hex:)
        label.layer.shadowColor = UIColor(hex: "#8A2BE2").cgColor
        label.layer.shadowRadius = 8.0
        label.layer.shadowOpacity = 1.0
        label.layer.shadowOffset = CGSize.zero
        label.layer.masksToBounds = false
        
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = UIColor(hex: "#2A2A2A")

        // 1. Добавляем контейнер для тени
        addSubview(imageContainerView)
        // 2. Добавляем картинку ВНУТРЬ контейнера
        imageContainerView.addSubview(imageView)
        
        // 3. Добавляем название приложения
        addSubview(appNameLabel)
        
        // 4. Устанавливаем ограничения с помощью SnapKit
        
        // Контейнер для картинки
        imageContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
            make.width.height.equalTo(120)
        }

        // Картинка внутри контейнера
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Название приложения
        appNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageContainerView.snp.bottom).offset(30)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
    }
}


//class SplashScreenView: UIView {
//    private let animationView: LottieAnimationView
//    
//    // MARK: - Initializer
//    override init(frame: CGRect) {
//        animationView = LottieAnimationView(name: "splash-anime")
//        super.init(frame: frame)
//        setupView()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Setup
//    private func setupView() {
//        backgroundColor = UIColor(hex: "#2A2A2A")
//        
//        animationView.contentMode = .scaleAspectFit
//        animationView.loopMode = .loop
//        animationView.animationSpeed = 1.0
//        animationView.play { _ in }
//        
//        addSubview(animationView)
//        
//        animationView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//    }
//}
