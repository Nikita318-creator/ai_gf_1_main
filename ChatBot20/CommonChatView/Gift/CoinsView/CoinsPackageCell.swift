import UIKit
import SnapKit

// MARK: - CoinPackage Model
struct CoinPackage {
    let id: String
    let amount: Int
    var price: String
    let imageName: String
}

// MARK: - CoinsPackageCell
class CoinsPackageCell: UICollectionViewCell {
    static let reuseIdentifier = "CoinsPackageCell"

    private let imageView = UIImageView()
    private let amountLabel = UILabel()
    private let priceButton = UIButton()
    
    private var coinID = ""
    private var amount: Int = 0
    
    var loadingIAPHandler: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        layer.cornerRadius = 15
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .secondarySystemBackground
        clipsToBounds = true
        
        // Amount Label (Сверху по центру)
        amountLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .center
        
        amountLabel.layer.shadowColor = UIColor.black.cgColor
        amountLabel.layer.shadowOpacity = 0.8
        amountLabel.layer.shadowRadius = 2.0
        amountLabel.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        amountLabel.layer.masksToBounds = false
        
        contentView.addSubview(amountLabel)

        // Image View (Не сплющиваем, центрируем по вертикали между текстом и кнопкой)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        // Price Button (На всю ширину ячейки)
        priceButton.layer.cornerRadius = 10
        priceButton.backgroundColor = .systemGreen
        priceButton.setTitleColor(.white, for: .normal)
        priceButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        priceButton.addTarget(self, action: #selector(priceButtonDown), for: .touchDown)
        priceButton.addTarget(self, action: #selector(priceButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        contentView.addSubview(priceButton)
        
        // Setup Constraints
        amountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(22)
        }
        
        priceButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(42)
            make.bottom.equalToSuperview().inset(10)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(8)
            make.bottom.equalTo(priceButton.snp.top).offset(-8)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }
    }

    func configure(with package: CoinPackage) {
        coinID = package.id
        amount = package.amount
        imageView.image = UIImage(named: package.imageName)
        amountLabel.text = "\(package.amount) \("Coins".localize())"
        priceButton.setTitle("\("Buy.for".localize()) \(package.price)", for: .normal)
    }
    
    // MARK: - Button Animations
    
    @objc private func priceButtonDown() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.priceButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func priceButtonUp() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            self.priceButton.transform = .identity
        } completion: { [weak self] _ in
            self?.priceButtonTapped()
        }
    }
    
    func priceButtonTapped() {
        AnalyticService.shared.logEvent(name: "CoinsPackageCell priceButtonTapped", properties: ["":""])

        loadingIAPHandler?(true)
        
        SubscriptionManager.shared.purchase(productId: coinID) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .failed:
                    self.loadingIAPHandler?(false)
                case .purchased, .restored:
                    TGReportsManager.shared.sendErrorReport(messageText: "COINS PURCHASED!!! \(self.coinID) for user: \(TGReportsManager.shared.randomID) + \(Locale.preferredLanguages.first ?? "en-US")")

                    AnalyticService.shared.logEvent(name: "Coins purchased!!!", properties: ["":"with id: \(self.coinID)"])
                    CoinsService.shared.addCoins(self.amount)
                    self.loadingIAPHandler?(false)
                }
            }
        }
    }
}
