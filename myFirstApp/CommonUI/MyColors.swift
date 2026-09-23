import UIKit

struct MyColors {
    static let pureWhite = UIColor.white // #FFFFFF
    static let pureBlack = UIColor.black // #000000
    
    // #3390DC -> #3092DE
    static let primary = UIColor(red: 0.19, green: 0.64, blue: 0.87, alpha: 1.0)
    
    // #1C1C1E -> #1B1B1D
    static let background = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
    
    // #2C2C2E -> #2D2D2F
    static let cardBackground = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1.0)
    
    // #38383A -> #373739
    static let messageBackground = UIColor(red: 0.21, green: 0.21, blue: 0.23, alpha: 1.0)
    
    static let userMessageBackground = UIColor(red: 0.19, green: 0.64, blue: 0.87, alpha: 1.0)
    
    // Чистый белый не трогаем или делаем чуть мягче (#FAFAFA)
    static let textPrimary = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    
    // #A4A4A8 -> #A2A2A6
    static let textSecondary = UIColor(red: 0.63, green: 0.63, blue: 0.65, alpha: 1.0)
    
    // #48484A -> #474749
    static let separator = UIColor(red: 0.27, green: 0.27, blue: 0.28, alpha: 1.0)
    
    static let unreadBadge = UIColor(red: 0.19, green: 0.64, blue: 0.87, alpha: 1.0)
    
    static let gradientStart = UIColor(red: 0.14, green: 0.14, blue: 0.15, alpha: 1.0)
    static let gradientEnd = UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)
    static let primaryGradientEnd = UIColor(red: 0.19, green: 0.64, blue: 0.87, alpha: 1.0)
    
    static let assistantMessageBackground = UIColor(red: 0.21, green: 0.21, blue: 0.23, alpha: 1.0)
    static let avatarBackground = UIColor(red: 0.29, green: 0.70, blue: 0.30, alpha: 1.0)
    static let link = UIColor(red: 0.24, green: 0.78, blue: 0.99, alpha: 1.0)
    static let bubbleBackground = UIColor(red: 0.21, green: 0.21, blue: 0.23, alpha: 1.0)
    static let accentRed = UIColor(red: 0.91, green: 0.29, blue: 0.29, alpha: 1.0)
    
    static let selectedOption = UIColor(red: 0.19, green: 0.64, blue: 0.87, alpha: 0.3)
    static let unselectedOption = UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1.0)
    static let inputBackground = UIColor(red: 0.21, green: 0.21, blue: 0.23, alpha: 1.0)
    
    static let progressBackground = UIColor.white.withAlphaComponent(0.18)
    static let progressForeground = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    static let primaryButtonBackground = UIColor(red: 0.19, green: 0.64, blue: 0.87, alpha: 1.0)
    static let gold = UIColor(red: 0.98, green: 0.78, blue: 0.20, alpha: 1.0)
}

//  розовый градиент:
//        UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
//        // Градиентный фон под цвет акцента
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = [
//            UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0).cgColor,
//            UIColor(red: 0.75, green: 0.15, blue: 0.40, alpha: 1.0).cgColor
//        ]
