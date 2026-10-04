import UIKit

struct MyColors {
    // MARK: - Base
    static let pureWhite = UIColor.white // #FFFFFF
    static let pureBlack = UIColor.black // #000000
    
    // MARK: - Primary & Accent (Pink Theme)
    // Основной розовый акцент (#F2408C) вместо старого голубого #3092DE
    static let primary = UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0)
    
    // Вспомогательный тёмно-розовый / малиновый для градиентов (#C02666)
    static let primaryGradientEnd = UIColor(red: 0.75, green: 0.15, blue: 0.40, alpha: 1.0)
    
    // Розовый ссылки / интерактива (#FF529A)
    static let link = UIColor(red: 1.00, green: 0.32, blue: 0.60, alpha: 1.0)
    
    // Выбранный элемент / плашка с альфой
    static let selectedOption = UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 0.25)
    
    // MARK: - Dark Backgrounds (Telegram-Dark Style)
    // Глубокий тёмный фон приложения (#0F0F12) вместо старого #1B1B1D
    static let background = UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)
    
    // Карточки / плашки (#17171C)
    static let cardBackground = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1.0)
    
    // Бабблы сообщений / входящие (#202026)
    static let messageBackground = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    static let assistantMessageBackground = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    static let bubbleBackground = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    static let inputBackground = UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
    static let unselectedOption = UIColor(red: 0.17, green: 0.17, blue: 0.20, alpha: 1.0)
    
    // Исходящие сообщения юзера / акцентные кнопки (яркий розовый акцент)
    static let userMessageBackground = UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0)
    static let primaryButtonBackground = UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0)
    static let unreadBadge = UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0)
    
    // MARK: - Typography & Separators
    static let textPrimary = UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0) // #FAFAFC
    static let textSecondary = UIColor(red: 0.55, green: 0.55, blue: 0.59, alpha: 1.0) // #8C8C96
    static let separator = UIColor(red: 0.20, green: 0.20, blue: 0.24, alpha: 1.0) // #33333D
    
    // MARK: - Gradients
    static let gradientStart = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1.0) // #17171C
    static let gradientEnd = UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)   // #0F0F12
    
    // MARK: - Additional Accents
    static let avatarBackground = UIColor(red: 0.22, green: 0.65, blue: 0.42, alpha: 1.0) // Мягкий изумрудный (#38A66B)
    static let accentRed = UIColor(red: 0.95, green: 0.30, blue: 0.35, alpha: 1.0)       // #F24D59
    static let gold = UIColor(red: 1.00, green: 0.75, blue: 0.20, alpha: 1.0)            // #FFBF33
    
    // MARK: - Progress & Tiles
    static let progressBackground = UIColor.white.withAlphaComponent(0.12)
    static let progressForeground = UIColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0)
    static let tile2 = UIColor(red: 0.22, green: 0.22, blue: 0.26, alpha: 1.0) // #383842
    static let tile4 = UIColor(red: 0.29, green: 0.29, blue: 0.34, alpha: 1.0) // #4A4A57
}
