import UIKit
import SnapKit

class RoshamboViewController: MiniGameAbstractVC {
    
    enum Choice: String, CaseIterable {
        case rock = "👊"
        case paper = "✋"
        case scissors = "✌️"
        
        static func random() -> Choice {
            return Choice.allCases.randomElement()!
        }
        
        func beats(_ other: Choice) -> Bool? {
            if self == other { return nil }
            switch self {
            case .rock: return other == .scissors
            case .paper: return other == .rock
            case .scissors: return other == .paper
            }
        }
    }
    
    // MARK: - State
    private var userChoice: Choice = .rock
    private var isCounting = false
    private var countdownTimer: Timer?
    private var currentCount = 0
    private let countdownKeys = ["Roshambo1", "Roshambo2", "Roshambo3", "Roshambo4"]
    
    // MARK: - UI Elements
    private let arenaStackView = UIStackView()
    private let waifuChoiceCard = UIView()
    private let userChoiceCard = UIView()
    private let waifuChoiceLabel = UILabel()
    private let userChoiceLabel = UILabel()
    private let vsContainerView = UIView()
    private let vsLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private var choiceButtons: [Choice: UIButton] = [:]
    
    override var gameRules: String {
        "Roshambo.INSTRUCTIONS".localize()
    }
    
    override func didResetProgress() {
        resetToIdle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameUI()
        loadProgress()
        resetToIdle()
    }
    
    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)

        let imageName: String
        switch userScore {
        case 0: imageName = "CAvatarForGeme0"
        case 1: imageName = "CAvatarForGeme1"
        case 2: imageName = "CAvatarForGeme2"
        case 3: imageName = "CAvatarForGeme3"
        case 4: imageName = "CAvatarForGeme4"
        case 5: imageName = "CAvatarForGeme5"
        case 6: imageName = "CAvatarForGeme6"
        case 7: imageName = "CAvatarForGeme7"
        case 8: imageName = "CAvatarForGeme8"
        case 9: imageName = "CAvatarForGeme9"
        case 10...:
            let suffix = (userScore % 2 == 0) ? "8" : "9"
            imageName = "CAvatarForGeme\(suffix)"
        default:
            imageName = "AAvatarForGeme8"
        }
            
        UIView.animate(withDuration: 1) {
            self.waifuImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: imageName)
        }
    }
    
    // MARK: - UI Setup
    private func setupGameUI() {
        // --- Arena Layout (Центральный боевой блок) ---
        arenaStackView.axis = .horizontal
        arenaStackView.alignment = .center
        arenaStackView.distribution = .equalSpacing
        arenaStackView.spacing = 12
        gameContainerView.addSubview(arenaStackView)
        
        // --- VS Badge ---
        vsContainerView.backgroundColor = MyColors.cardBackground
        vsContainerView.layer.cornerRadius = 22
        vsContainerView.layer.borderWidth = 2
        vsContainerView.layer.borderColor = MyColors.separator.cgColor
        vsContainerView.layer.shadowColor = MyColors.pureBlack.cgColor
        vsContainerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        vsContainerView.layer.shadowOpacity = 0.3
        vsContainerView.layer.shadowRadius = 6
        
        vsLabel.text = "VS"
        vsLabel.font = .systemFont(ofSize: 20, weight: .black)
        vsLabel.textColor = MyColors.gold
        vsLabel.textAlignment = .center
        vsContainerView.addSubview(vsLabel)
        
        vsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        vsContainerView.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
        
        // --- Cards Styling ---
        [userChoiceCard, waifuChoiceCard].forEach { card in
            card.backgroundColor = MyColors.tile2
            card.layer.cornerRadius = 28
            card.layer.borderWidth = 2.5
            card.layer.borderColor = MyColors.separator.cgColor
            card.layer.shadowColor = MyColors.pureBlack.cgColor
            card.layer.shadowOffset = CGSize(width: 0, height: 6)
            card.layer.shadowOpacity = 0.35
            card.layer.shadowRadius = 10
        }
        
        userChoiceLabel.font = .systemFont(ofSize: 56)
        userChoiceLabel.textAlignment = .center
        userChoiceLabel.text = "👊"
        userChoiceCard.addSubview(userChoiceLabel)
        
        waifuChoiceLabel.font = .systemFont(ofSize: 56)
        waifuChoiceLabel.textAlignment = .center
        waifuChoiceLabel.text = "❓"
        waifuChoiceCard.addSubview(waifuChoiceLabel)
        
        userChoiceLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        waifuChoiceLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        arenaStackView.addArrangedSubview(userChoiceCard)
        arenaStackView.addArrangedSubview(vsContainerView)
        arenaStackView.addArrangedSubview(waifuChoiceCard)
        
        // --- Controls Stack ---
        let controlsStack = UIStackView()
        controlsStack.axis = .horizontal
        controlsStack.distribution = .fillEqually
        controlsStack.spacing = 20
        gameContainerView.addSubview(controlsStack)
        
        // --- Play Button ---
        playButton.setTitle("GameStartBtn".localize(), for: .normal)
        playButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        playButton.backgroundColor = MyColors.primary
        playButton.tintColor = MyColors.pureWhite
        playButton.layer.cornerRadius = 26
        playButton.layer.shadowColor = MyColors.primary.cgColor
        playButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        playButton.layer.shadowOpacity = 0.4
        playButton.layer.shadowRadius = 8
        playButton.addTarget(self, action: #selector(startRound), for: .touchUpInside)
        gameContainerView.addSubview(playButton)

        // --- CONSTRAINTS ---

        controlsStack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(320)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(72)
        }

        playButton.snp.makeConstraints { make in
            make.bottom.equalTo(controlsStack.snp.top).offset(-24)
            make.centerX.equalToSuperview()
            make.width.equalTo(230)
            make.height.equalTo(54)
        }

        arenaStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(playButton.snp.top).offset(-35)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        userChoiceCard.snp.makeConstraints { make in
            make.width.height.equalTo(115)
        }

        waifuChoiceCard.snp.makeConstraints { make in
            make.width.height.equalTo(115)
        }

        // --- Choice Buttons (Arcade Style) ---
        for choice in Choice.allCases {
            let btn = UIButton()
            btn.setTitle(choice.rawValue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 36)
            btn.backgroundColor = MyColors.cardBackground
            btn.layer.cornerRadius = 36 // Круглые кнопки
            btn.layer.borderWidth = 2
            btn.layer.borderColor = MyColors.separator.cgColor
            btn.layer.shadowColor = MyColors.pureBlack.cgColor
            btn.layer.shadowOffset = CGSize(width: 0, height: 4)
            btn.layer.shadowOpacity = 0.25
            btn.layer.shadowRadius = 6
            btn.addTarget(self, action: #selector(choiceTapped(_:)), for: .touchUpInside)
            
            choiceButtons[choice] = btn
            controlsStack.addArrangedSubview(btn)
        }
    }
    
    @objc private func choiceTapped(_ sender: UIButton) {
        // Логика: выбор работает только когда идет отсчет
        guard isCounting,
              let choiceStr = sender.title(for: .normal),
              let choice = Choice.allCases.first(where: { $0.rawValue == choiceStr }) else { return }
        
        userChoice = choice
        updateChoiceSelection()
        userChoiceLabel.text = choice.rawValue
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    @objc private func startRound() {
        guard !isCounting else { return }
        
        isCounting = true
        currentCount = 0
        
        // Визуальное состояние кнопок при старте
        playButton.isEnabled = false
        UIView.animate(withDuration: 0.2) {
            self.playButton.alpha = 0.4
        }
        
        // Сброс рамок карточек к стандартному состоянию
        userChoiceCard.layer.borderColor = MyColors.primary.cgColor
        waifuChoiceCard.layer.borderColor = MyColors.separator.cgColor
        
        // Разблокируем выбор для пользователя
        choiceButtons.values.forEach {
            $0.isEnabled = true
            $0.alpha = 1.0
        }
        
        waifuChoiceLabel.text = "❓"
        userChoice = .rock
        updateChoiceSelection()
        userChoiceLabel.text = userChoice.rawValue
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] timer in
            self?.handleTimerTick()
        }
    }
    
    private func handleTimerTick() {
        if currentCount < countdownKeys.count {
            setWaifuMessage(countdownKeys[currentCount].localize())
            currentCount += 1
            animateShake()
        } else {
            finishRound()
        }
    }
    
    private func finishRound() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCounting = false
        
        // Блокируем выбор обратно - раунд окончен
        choiceButtons.values.forEach { btn in
            btn.isEnabled = false
            UIView.animate(withDuration: 0.2) {
                btn.alpha = 0.5
            }
        }
        
        let waifuChoice = Choice.random()
        waifuChoiceLabel.text = waifuChoice.rawValue
        
        // Эффектная Spring-анимация появления выбора Waifu
        waifuChoiceLabel.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            self.waifuChoiceLabel.transform = .identity
        })
        
        if let userWins = userChoice.beats(waifuChoice) {
            if userWins {
                userScore += 1
                setWaifuMessage("GameWinRPS".localize())
                highlightWinner(userCardWins: true)
            } else {
                waifuScore += 1
                setWaifuMessage("GameLoseRPS".localize())
                highlightWinner(userCardWins: false)
            }
            updateScore(waifu: waifuScore, user: userScore)
        } else {
            setWaifuMessage("GameDrawRPS".localize())
            highlightDraw()
        }
        
        playButton.isEnabled = true
        UIView.animate(withDuration: 0.2) {
            self.playButton.alpha = 1.0
        }
        playButton.setTitle("GameAgainBtn".localize(), for: .normal)
    }
    
    private func updateChoiceSelection() {
        choiceButtons.forEach { choice, btn in
            let isSelected = (choice == userChoice)
            UIView.animate(withDuration: 0.2) {
                if isSelected {
                    btn.backgroundColor = MyColors.selectedOption
                    btn.layer.borderColor = MyColors.primary.cgColor
                    btn.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
                } else {
                    btn.backgroundColor = MyColors.cardBackground
                    btn.layer.borderColor = MyColors.separator.cgColor
                    btn.transform = .identity
                }
            }
        }
    }
    
    private func resetToIdle() {
        userChoice = .rock
        updateChoiceSelection()
        
        userChoiceCard.layer.borderColor = MyColors.separator.cgColor
        waifuChoiceCard.layer.borderColor = MyColors.separator.cgColor
        
        // Кнопки заблокированы до нажатия PLAY
        choiceButtons.values.forEach {
            $0.isEnabled = false
            $0.alpha = 0.5
        }
    }
    
    private func animateShake() {
        // Трясем карточки целиком с добавлением эффекта наклона (rotation)
        [userChoiceCard, waifuChoiceCard].forEach { card in
            let anim = CAKeyframeAnimation(keyPath: "transform")
            let leftTilt = CATransform3DMakeRotation(-0.08, 0, 0, 1)
            let rightTilt = CATransform3DMakeRotation(0.08, 0, 0, 1)
            
            anim.values = [
                NSValue(caTransform3D: leftTilt),
                NSValue(caTransform3D: rightTilt),
                NSValue(caTransform3D: CATransform3DIdentity)
            ]
            anim.duration = 0.12
            anim.repeatCount = 2
            card.layer.add(anim, forKey: "shake")
        }
    }
    
    // MARK: - Custom Visual Effects
    
    private func highlightWinner(userCardWins: Bool) {
        let winnerCard = userCardWins ? userChoiceCard : waifuChoiceCard
        let loserCard = userCardWins ? waifuChoiceCard : userChoiceCard
        let winnerColor = userCardWins ? MyColors.gold : MyColors.accentRed
        
        UIView.animate(withDuration: 0.3) {
            winnerCard.layer.borderColor = winnerColor.cgColor
            winnerCard.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            loserCard.layer.borderColor = MyColors.separator.cgColor
            loserCard.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                winnerCard.transform = .identity
                loserCard.transform = .identity
            }
        }
    }
    
    private func highlightDraw() {
        UIView.animate(withDuration: 0.3) {
            self.userChoiceCard.layer.borderColor = MyColors.textPrimary.cgColor
            self.waifuChoiceCard.layer.borderColor = MyColors.textPrimary.cgColor
        }
    }
}
