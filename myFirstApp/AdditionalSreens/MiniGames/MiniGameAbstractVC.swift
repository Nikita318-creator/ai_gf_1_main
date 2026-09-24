import UIKit
import SnapKit

class MiniGameAbstractVC: UIViewController {
    
    // MARK: - UI Colors
    // Styling now sources exclusively from the shared `MyColors` design-system
    // palette (defined once app-wide) instead of a locally hardcoded struct.
    
    // MARK: - Properties
    var waifuScore = 0
    var userScore = 0
    
    var gameSaveKey: String {
        return String(describing: type(of: self)) + "_progress"
    }
    
    var boardSaveKey: String {
        return gameSaveKey + "_board_state"
    }
    
    // Custom Navigation Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let scorePillView = UIView()
    private let scoreLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    
    let waifuImageView = UIImageView()
    private let waifuCardShadowView = UIView()
    private let chatBubbleView = UIView()
    private let bubbleLabel = UILabel()
    private let headerSeparator = UIView()
    
    let gameContainerView = UIView()
    var gameRules: String { "Rules for this game will be added soon." }

    func didResetProgress() {
        // Будет переопределено в дочерних классах (Reversi, Checkers и т.д.)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        setupBaseUI()
        setupCustomNavigationBar()
        updateUIForIPadIfNeeded()
        
        setWaifuMessage("mini.game.aigf.texts.challenge.ready".localize())
        
        print("\(self)")
        AmplitudeManager.shared.logEvent(name: "game opened", properties: ["type":"\(self)"])
    }
    
    func loadProgress() {
        if let stats = UserDefaults.standard.dictionary(forKey: gameSaveKey) as? [String: Int] {
            self.waifuScore = stats["waifu"] ?? 0
            self.userScore = stats["user"] ?? 0
            updateScore(waifu: waifuScore, user: userScore)
        } else {
            self.waifuScore = 0
            self.userScore = 0
            updateScore(waifu: waifuScore, user: userScore)
        }
    }
        
    func updateScore(waifu: Int, user: Int) {
        AmplitudeManager.shared.logEvent(name: "game updatedScore", properties: ["type":"\(self)", "waifu":"\(waifu)", "user":"\(user)"])

        self.waifuScore = waifu
        self.userScore = user
        scoreLabel.text = "\("waifu".localize()) \(waifuScore) : \(userScore) \("you".localize())"
        
        saveProgress()
    }
    
    func setWaifuMessage(_ text: String) {
        bubbleLabel.text = text
    }

    // MARK: - Private Setup
    
    private func saveProgress() {
        let stats = ["waifu": waifuScore, "user": userScore]
        UserDefaults.standard.set(stats, forKey: gameSaveKey)
    }
    
    private func setupCustomNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = MyColors.background
        
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Тонкий разделитель под навбаром — отделяет шапку от контента
        navSeparator.backgroundColor = MyColors.separator
        customNavBar.addSubview(navSeparator)
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // Кнопка Назад — шеврон в аккуратном круге в стиле карточек приложения
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: backConfig)
        
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = MyColors.textPrimary
        backButton.backgroundColor = MyColors.cardBackground
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(dismissGame), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // Кнопка Инфо — тот же круглый стиль, акцентный цвет из палитры
        let infoConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let infoImage = UIImage(systemName: "info.circle", withConfiguration: infoConfig)
        
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = MyColors.primary
        infoButton.backgroundColor = MyColors.cardBackground
        infoButton.layer.cornerRadius = 20
        infoButton.addTarget(self, action: #selector(showRules), for: .touchUpInside)
        customNavBar.addSubview(infoButton)
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // Счёт — теперь оформлен как компактный "пилл" с бейджами игроков
        scorePillView.backgroundColor = MyColors.cardBackground
        scorePillView.layer.cornerRadius = 18
        scorePillView.layer.borderWidth = 1
        scorePillView.layer.borderColor = MyColors.separator.cgColor
        customNavBar.addSubview(scorePillView)
        
        scorePillView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(36)
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(infoButton.snp.leading).offset(-8)
        }
        
        scoreLabel.text = "\("waifu".localize()) \(waifuScore) : \(userScore) \("you".localize())"
        scoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        scoreLabel.textColor = MyColors.textPrimary
        scoreLabel.textAlignment = .center
        scorePillView.addSubview(scoreLabel)
        
        scoreLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
        
        scorePillView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(scoreLabelTapped))
        scorePillView.addGestureRecognizer(tap)
    }
    
    private func setupBaseUI() {
        view.backgroundColor = MyColors.background
        
        // Мягкая карточная тень под аватаром — отдельная view позади,
        // так как у waifuImageView clipsToBounds = true и тень напрямую не сработает
        waifuCardShadowView.backgroundColor = MyColors.cardBackground
        waifuCardShadowView.layer.cornerRadius = 32
        waifuCardShadowView.layer.shadowColor = MyColors.pureBlack.cgColor
        waifuCardShadowView.layer.shadowOffset = CGSize(width: 0, height: 6)
        waifuCardShadowView.layer.shadowOpacity = 0.35
        waifuCardShadowView.layer.shadowRadius = 12
        view.addSubview(waifuCardShadowView)
        
        waifuImageView.contentMode = .scaleAspectFill
        waifuImageView.layer.cornerRadius = 32
        waifuImageView.clipsToBounds = true
        waifuImageView.backgroundColor = MyColors.cardBackground
        waifuImageView.layer.borderWidth = 2
        waifuImageView.layer.borderColor = MyColors.separator.cgColor
        waifuImageView.isUserInteractionEnabled = true
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(waifuImageTapped))
        waifuImageView.addGestureRecognizer(imageTap)
        view.addSubview(waifuImageView)
        
        chatBubbleView.backgroundColor = MyColors.bubbleBackground
        chatBubbleView.layer.cornerRadius = 18
        chatBubbleView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
        chatBubbleView.layer.borderWidth = 1
        chatBubbleView.layer.borderColor = MyColors.separator.cgColor
        chatBubbleView.layer.shadowColor = MyColors.pureBlack.cgColor
        chatBubbleView.layer.shadowOffset = CGSize(width: 0, height: 3)
        chatBubbleView.layer.shadowOpacity = 0.2
        chatBubbleView.layer.shadowRadius = 6
        view.addSubview(chatBubbleView)
        
        bubbleLabel.textColor = MyColors.textPrimary
        bubbleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        bubbleLabel.numberOfLines = 0
        chatBubbleView.addSubview(bubbleLabel)
        
        // Тонкая горизонтальная линия отделяет "шапку" (аватар/реплика) от игрового поля
        headerSeparator.backgroundColor = MyColors.separator
        view.addSubview(headerSeparator)
        
        gameContainerView.backgroundColor = .clear
        view.addSubview(gameContainerView)
        
        // MARK: - Constraints
        waifuImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(64) // Под кастомным баром
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(UIScreen.main.bounds.width / 2)
            make.height.equalTo(UIScreen.main.bounds.height / 3)
        }
        
        waifuCardShadowView.snp.makeConstraints { make in
            make.edges.equalTo(waifuImageView)
        }
        
        chatBubbleView.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.top)
            make.leading.equalTo(waifuImageView.snp.trailing).offset(-25)
            make.trailing.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualTo(waifuImageView.snp.bottom).offset(10)
        }
        
        bubbleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        
        headerSeparator.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
        
        gameContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerSeparator.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func resetGameProgress() {
        UserDefaults.standard.removeObject(forKey: gameSaveKey)
        
        waifuScore = 0
        userScore = 0
        updateScore(waifu: 0, user: 0)
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        didResetProgress()
    }
    
    @objc private func scoreLabelTapped() {
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        
        let alert = UIAlertController(
            title: "mini.game.aigf.texts.reset.title".localize(),
            message: "mini.game.aigf.texts.reset.message".localize(),
            preferredStyle: .alert
        )
        
        let resetAction = UIAlertAction(title: "Reset".localize(), style: .destructive) { [weak self] _ in
            self?.resetGameProgress()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .cancel)
        
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func dismissGame() {
        dismiss(animated: true)
    }
    
    @objc private func showRules() {
        let alert = UIAlertController(title: "mini.game.aigf.texts.Rules".localize(), message: gameRules, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mini.game.aigf.texts.Understood".localize(), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func waifuImageTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let fullScreenView = PreviewImageView(image: waifuImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
}

// MARK: - iPad Layout Adaptation
extension MiniGameAbstractVC {
    func updateUIForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        
        // 1. Навбар и его кнопки
        customNavBar.snp.updateConstraints { make in
            make.height.equalTo(80)
        }
        
        let buttonSize: CGFloat = 52
        let backConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        let infoConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        
        backButton.setImage(UIImage(systemName: "chevron.backward", withConfiguration: backConfig), for: .normal)
        backButton.layer.cornerRadius = buttonSize / 2
        backButton.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.width.height.equalTo(buttonSize)
        }
        
        infoButton.setImage(UIImage(systemName: "info.circle", withConfiguration: infoConfig), for: .normal)
        infoButton.layer.cornerRadius = buttonSize / 2
        infoButton.snp.updateConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.width.height.equalTo(buttonSize)
        }
        
        // 2. Пилл счёта
        let pillHeight: CGFloat = 48
        scorePillView.layer.cornerRadius = pillHeight / 2
        scorePillView.snp.updateConstraints { make in
            make.height.equalTo(pillHeight)
        }
        
        scoreLabel.font = .systemFont(ofSize: 22, weight: .bold)
        scoreLabel.snp.updateConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24))
        }
        
        // 3. Аватар и Баббл
        waifuImageView.layer.cornerRadius = 48
        waifuCardShadowView.layer.cornerRadius = 48
        chatBubbleView.layer.cornerRadius = 28
        bubbleLabel.font = .systemFont(ofSize: 24, weight: .medium)
        
        waifuImageView.snp.updateConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(84)
            make.leading.equalToSuperview().offset(24)
        }
        
        chatBubbleView.snp.updateConstraints { make in
            make.leading.equalTo(waifuImageView.snp.trailing).offset(-35)
            make.trailing.equalToSuperview().inset(16)
        }
        
        bubbleLabel.snp.updateConstraints { make in
            make.edges.equalToSuperview().inset(22)
        }
        
        headerSeparator.snp.updateConstraints { make in
            make.leading.trailing.equalToSuperview().inset(28)
        }
        
        gameContainerView.snp.updateConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
}
