import UIKit
import SnapKit

class SubscriptionPlanView: UIView {
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let weeklyPriceLabel = UILabel()
    private let saveLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    private let selectionBorder = CALayer()
    
    var isOnboarding = false
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateTextForIPadIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        // Container View
        containerView.backgroundColor = UIColor(hex: "#2A2A2A")
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Title Label
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(hex: "#E0E0E0")
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        // Price Label
        priceLabel.textAlignment = .center
        priceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        priceLabel.textColor = UIColor(hex: "#3390EC")
        containerView.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        // Weekly Price Label
        weeklyPriceLabel.textAlignment = .center
        weeklyPriceLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium) // 1px smaller than priceLabel
        weeklyPriceLabel.textColor = UIColor(hex: "#80A0C0") // Subtle color to complement style
        weeklyPriceLabel.isHidden = true // Hidden by default
        containerView.addSubview(weeklyPriceLabel)
        weeklyPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        // Save Label
        saveLabel.textAlignment = .center
        saveLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        saveLabel.textColor = UIColor(hex: "#34C759")
        saveLabel.isHidden = true
        containerView.addSubview(saveLabel)
        saveLabel.snp.makeConstraints { make in
            make.top.equalTo(weeklyPriceLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        // Checkmark Image View
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = UIColor(hex: "#3390EC")
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.alpha = 0
        containerView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.width.height.equalTo(20)
        }
        
        // Selection Border
        selectionBorder.borderWidth = 2
        selectionBorder.borderColor = UIColor(hex: "#3390EC").cgColor
        selectionBorder.cornerRadius = 16
        layer.insertSublayer(selectionBorder, at: 0)
        selectionBorder.opacity = 0
    }
    
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }

        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        priceLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        weeklyPriceLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        saveLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        
        checkmarkImageView.snp.updateConstraints { make in
            make.width.height.equalTo(30)
        }
    }
    
    // MARK: - Public Methods
    func setTitle(_ title: String, isTrial: Bool = false) {
        titleLabel.text = title
        
//        guard !isTrial else {
//            if let product = IAPService.shared.products.first(where: { $0.productId == SubsIDs.yearlyOld }) {
//                priceLabel.text = product.skProduct?.localizedPrice() ?? ""
//                
//                if let priceString = product.skProduct?.localizedPrice(),
//                   let (price, currencySymbol) = extractPrice(from: priceString) {
//                    let weeklyPrice = price / 52
//                    weeklyPriceLabel.text = String(format: "%@%.2f \("Subs.perWeek".localize())", currencySymbol, weeklyPrice)
//                    weeklyPriceLabel.isHidden = false
//                } else {
//                    weeklyPriceLabel.text = ""
//                    weeklyPriceLabel.isHidden = true
//                }
//            } else {
//                weeklyPriceLabel.text = ""
//                weeklyPriceLabel.isHidden = true
//            }
//            saveLabel.text = ""
//            saveLabel.isHidden = true
//            return
//        }
        
        switch title {
        case "Subs.week".localize():
            let currentProductId: String
            if ConfigService.shared.isUSHaveDifferentPrice {
                currentProductId = SubsIDs.weekly2025last
            } else {
                currentProductId = (ConfigService.shared.isProSubs && isOnboarding) || ConfigService.shared.needAlwaysProSubs ? SubsIDs.weeklyPRO : SubsIDs.weeklySpecial
            }
            
            if let product = IAPService.shared.products.first(where: { $0.productId == currentProductId }) {
                priceLabel.text = product.skProduct?.localizedPrice() ?? ""
            }
            weeklyPriceLabel.text = ""
            weeklyPriceLabel.isHidden = true
            saveLabel.text = ""
            saveLabel.isHidden = true
        case "Subs.month".localize():
            let currentProductId: String
            if ConfigService.shared.isUSHaveDifferentPrice {
                currentProductId = SubsIDs.monthly2025last
            } else {
                currentProductId = (ConfigService.shared.isProSubs && isOnboarding) || ConfigService.shared.needAlwaysProSubs ? SubsIDs.monthlyPRO : SubsIDs.monthlySpecial
            }
            
            if let product = IAPService.shared.products.first(where: { $0.productId == currentProductId }) {
                priceLabel.text = product.skProduct?.localizedPrice() ?? ""
                
                if let priceString = product.skProduct?.localizedPrice(),
                   let (price, currencySymbol) = extractPrice(from: priceString) {
                    let weeklyPrice = price / 4.33
                    weeklyPriceLabel.text = String(format: "%@%.2f \("Subs.perWeek".localize())", currencySymbol, weeklyPrice)
                    weeklyPriceLabel.isHidden = false
                } else {
                    weeklyPriceLabel.text = ""
                    weeklyPriceLabel.isHidden = true
                }
            } else {
                weeklyPriceLabel.text = ""
                weeklyPriceLabel.isHidden = true
            }
            saveLabel.text = ""
            saveLabel.isHidden = true
        default:
            priceLabel.text = ""
            weeklyPriceLabel.text = ""
            weeklyPriceLabel.isHidden = true
        }
    }
    
    // Helper to extract numeric price from localized price string (e.g., "$29,99" -> 29.99)
    private func extractPrice(from priceString: String) -> (price: Double, currencySymbol: String)? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = NSLocale.current
        if let number = formatter.number(from: priceString) {
            let currencySymbol = formatter.currencySymbol ?? ""
            return (number.doubleValue, currencySymbol)
        }
        
        let cleanedStringPrice = priceString
            .components(separatedBy: CharacterSet(charactersIn: "0123456789,.").inverted)
            .joined()
            .replacingOccurrences(of: ",", with: ".")
        
        guard let price = Double(cleanedStringPrice) else {
            return nil
        }
        
        let currencySymbol = priceString
            .trimmingCharacters(in: CharacterSet(charactersIn: "0123456789,."))
            .trimmingCharacters(in: .whitespaces)
        
        return (price, currencySymbol.isEmpty ? "" : currencySymbol)
    }
    
    func setSelected(_ selected: Bool) {
        if selected {
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 0.2
            pulseAnimation.fromValue = 1.0
            pulseAnimation.toValue = 1.02
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = 1
            layer.add(pulseAnimation, forKey: "pulseAnimation")
            
            let borderAnimation = CABasicAnimation(keyPath: "opacity")
            borderAnimation.duration = 0.2
            borderAnimation.fromValue = 0.0
            borderAnimation.toValue = 1.0
            selectionBorder.add(borderAnimation, forKey: "opacityAnimation")
            selectionBorder.opacity = 1.0
            
            containerView.backgroundColor = UIColor(hex: "#333333")
            checkmarkImageView.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.checkmarkImageView.alpha = 1.0
            }
            
            priceLabel.textColor = UIColor(hex: "#2A80D8")
            weeklyPriceLabel.textColor = UIColor(hex: "#80A0C0") // Maintain same color when selected
            titleLabel.textColor = UIColor(hex: "#E0E0E0")
        } else {
            selectionBorder.opacity = 0.0
            containerView.backgroundColor = UIColor(hex: "#2A2A2A")
            UIView.animate(withDuration: 0.2) {
                self.checkmarkImageView.alpha = 0.0
            } completion: { _ in
                self.checkmarkImageView.isHidden = true
            }
            
            priceLabel.textColor = UIColor(hex: "#3390EC")
            weeklyPriceLabel.textColor = UIColor(hex: "#80A0C0")
            titleLabel.textColor = UIColor(hex: "#E0E0E0")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBorder.frame = bounds
    }
}
