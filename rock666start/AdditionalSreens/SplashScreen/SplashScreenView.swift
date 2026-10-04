import UIKit
import SnapKit

final class SplashScreenView: UIView {

    // MARK: - Subviews
    
    private let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = MyColors.primary.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.5
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "splashPhoto"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderColor = MyColors.primary.cgColor
        imageView.layer.borderWidth = 2
        imageView.layer.cornerRadius = 60 // Круглый аватар
        return imageView
    }()

    private let appNameLabel: UILabel = {
        let label = UILabel()
        if let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            label.text = displayName
        } else if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            label.text = bundleName
        } else {
            label.text = "Emma: AI GF"
        }
        
        label.numberOfLines = 1
        label.textColor = MyColors.textPrimary
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center

        // Мягкое благородное свечение
        label.layer.shadowColor = MyColors.primary.cgColor
        label.layer.shadowRadius = 12.0
        label.layer.shadowOpacity = 0.6
        label.layer.shadowOffset = .zero
        label.layer.masksToBounds = false
        
        return label
    }()
    
    // Бейдж-субтитр (для визуального усложнения верстки)
    private let subtitleBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = MyColors.primary.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "YOUR AI COMPANION".localize()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = MyColors.primary
        label.textAlignment = .center
        return label
    }()
    
    // Индикатор загрузки
    private let loaderView: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(style: .medium)
        loader.color = MyColors.primary
        loader.startAnimating()
        return loader
    }()

    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = MyColors.background

        addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        addSubview(appNameLabel)
        
        addSubview(subtitleBadgeView)
        subtitleBadgeView.addSubview(subtitleLabel)
        
        addSubview(loaderView)
    }
    
    private func setupConstraints() {
        imageContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.size.equalTo(120)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        appNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageContainerView.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        subtitleBadgeView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(12)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14))
        }
        
        loaderView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-40)
        }
    }
}

// MARK: - iPad Adaptation

extension SplashScreenView {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }

        appNameLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)

        imageView.layer.cornerRadius = 90
        subtitleBadgeView.layer.cornerRadius = 16

        imageContainerView.snp.updateConstraints { make in
            make.size.equalTo(180)
        }

        subtitleLabel.snp.updateConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))
        }

        loaderView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    }
}
