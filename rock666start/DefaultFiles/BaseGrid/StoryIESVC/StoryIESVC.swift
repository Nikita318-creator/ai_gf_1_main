import UIKit
import SnapKit

// Протокол для унифицированного доступа к коллбеку завершения игры
protocol GameCompletionProtocol: AnyObject {
    var onGameCompleted: (() -> Void)? { get set }
}

final class StoryIESVC: UIViewController {

    // MARK: - Constants & State
    private let totalLevels = 20 // 100 слайдов делим на пачки по 5
    private let slidesPerLevel = 5
    
    private var currentLevel: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: "story_current_level")
            return saved == 0 ? 1 : saved
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "story_current_level")
        }
    }
    
    private var currentSlideIndex = 0
    private var activeSlideImages: [UIImage?] = []
    
    // Сюжетные реплики для комикса (про мальчика и злого колдуна)
    private let allLevelNarratives: [[String]] = [
        // Уровень 1: Прибытие к башне
        [
            "Darkness falls upon the valley as the Evil Sorcerer claims the ancient crystal tower.",
            "A brave young boy steps forward, refusing to bow to the tyrant's wicked spell.",
            "'I challenge you, Sorcerer!' cries out the boy, gripping his wooden training sword.",
            "The Sorcerer laughs coldly: 'Prove your intellect through trials, or be trapped forever!'",
            "The first gate glows with magic. Solve the puzzle to breach the outer wall!"
        ],
        // Уровень 2: Внутренний двор
        [
            "The boy steps past the shattered outer gate into the Sorcerer's dark courtyard.",
            "Mechanical gargoyles awaken, blocking the path to the inner keep.",
            "'You cannot outsmart my guardians!' echoes the Sorcerer's voice from above.",
            "The boy spots a weak link in their defensive runes.",
            "Decode the mechanism and smash past the mechanical beasts!"
        ],
        // Уровень 3: Подземелье
        [
            "Descending into the murky dungeons, the air grows cold and damp.",
            "Trapped spirits whisper warnings of the dark magic ahead.",
            "A massive iron door bars the exit, sealed with ancient runic glyphs.",
            "'Only the sharpest minds escape my labyrinth!' mocks the unseen tyrant.",
            "Align the glowing runes to unlock the dungeon gate!"
        ],
        // Уровень 4: Зал зеркальных иллюзий
        [
            "Emerging into the Hall of Mirrors, deceptive reflections twist reality.",
            "The boy sees multiple illusions of the Sorcerer laughing at him.",
            "'Which one is real? Choose poorly and be lost in the glass maze!'",
            "He closes his eyes, relying on logic rather than sight.",
            "Find the true path through the maze of reflections!"
        ],
        // Уровень 5: Винтовая лестница
        [
            "Climbing the endless spiral staircase toward the tower's peak.",
            "Magical gravity shifts, making every step treacherous and heavy.",
            "'You are tiring, boy! Give up while you still can!' shouts the Sorcerer.",
            "With sheer willpower, he adjusts his balance to the shifting forces.",
            "Solve the gravity puzzle to reach the upper observatory!"
        ],
        // Уровень 6: Библиотека запретных заклинаний
        [
            "Entering the vast library filled with floating, whispering grimoires.",
            "Ancient spells swirl around like a fierce academic tempest.",
            "'Knowledge is my power, and you know nothing!' taunts the mage.",
            "The boy grabs a key tome that holds the counter-spell.",
            "Arrange the ancient formulas to dispel the magical storm!"
        ],
        // Уровень 7: Алхимическая лаборатория
        [
            "Bubbling cauldrons and toxic fumes fill the high alchemical chamber.",
            "A robotic golem blocks the bridge over a pit of boiling potion.",
            "'Can you mix logic faster than my brew boils?' challenges the Sorcerer.",
            "The boy analyzes the chemical symbols inscribed on the golem's chest.",
            "Match the elements correctly to disable the guardian!"
        ],
        // Уровень 8: Обсерватория звезд
        [
            "Stepping out onto the open, windswept observatory under a stormy sky.",
            "Constellations shift unnaturally, locking the path to the sanctum.",
            "'Even the stars obey my commands!' roars the tyrant.",
            "The boy reads the celestial pattern and spots the anomaly.",
            "Connect the cosmic alignment to open the final bridge!"
        ],
        // Уровень 9: Преддверие тронного зала
        [
            "Reaching the heavy golden doors of the Sorcerer's personal throne room.",
            "A massive magical shield crackles with pure destructive energy.",
            "'This is where your journey ends, foolish hero!' warns the Sorcerer.",
            "The boy channels the energy of all his previous victories.",
            "Break the ultimate shield code to enter the final battle!"
        ],
        // Уровень 10: Финальная битва
        [
            "Standing face-to-face with the Evil Sorcerer in his glowing sanctum.",
            "The crystal core pulses with stolen light, threatening to consume the valley.",
            "'It is time to settle this once and for all!' declares the boy bravely.",
            "The Sorcerer unleashes his ultimate mind-trap.",
            "Outsmart the final mastermind trial and save the world!"
        ]
    ]

    // MARK: - UI Components
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let darkOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.background.withAlphaComponent(0.65)
        return view
    }()

    private let comicPanelCard: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.separator.cgColor
        return view
    }()

    private let levelBadgeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .bold)
        lbl.textColor = BasePalitColors.primary
        lbl.textAlignment = .left
        return lbl
    }()

    private let narrativeTextView: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = BasePalitColors.textPrimary
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        return lbl
    }()

    private lazy var actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("NEXT DIALOGUE", for: .normal)
        btn.setTitleColor(BasePalitColors.pureWhite, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = BasePalitColors.primaryButtonBackground
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
        return btn
    }()

    private let progressIndicatorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        return stack
    }()

    // MARK: - Lifecycle
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BasePalitColors.background
        setupLayout()
        loadCurrentLevelContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Layout Setup
    private func setupLayout() {
        view.addSubview(backgroundImageView)
        view.addSubview(darkOverlayView)
        view.addSubview(comicPanelCard)

        comicPanelCard.addSubview(levelBadgeLabel)
        comicPanelCard.addSubview(narrativeTextView)
        comicPanelCard.addSubview(progressIndicatorStack)
        comicPanelCard.addSubview(actionButton)

        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        darkOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        comicPanelCard.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        levelBadgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        narrativeTextView.snp.makeConstraints { make in
            make.top.equalTo(levelBadgeLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        progressIndicatorStack.snp.makeConstraints { make in
            make.top.equalTo(narrativeTextView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }

        actionButton.snp.makeConstraints { make in
            make.top.equalTo(progressIndicatorStack.snp.bottom).offset(18)
            make.leading.trailing.bottom.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
    }

    // MARK: - Content Loading
    private func loadCurrentLevelContent() {
        currentSlideIndex = 0
        activeSlideImages.removeAll()

        // Пачка из 5 картинок для текущего уровня
        for i in 0..<slidesPerLevel {
            let imgName = "story\(i+1)"
            activeSlideImages.append(UIImage(named: imgName))
        }

        updateSlideUI()
    }

    private func updateSlideUI() {
        levelBadgeLabel.text = "CHAPTER \(currentLevel) • SCENE \(currentSlideIndex + 1)/\(slidesPerLevel)"
        
        // Безопасно получаем массив фраз для текущего уровня (с защитой через modulo)
        let levelIndex = (currentLevel - 1) % allLevelNarratives.count
        let currentNarratives = allLevelNarratives[levelIndex]
        
        if currentSlideIndex < currentNarratives.count {
            narrativeTextView.text = currentNarratives[currentSlideIndex]
        } else {
            narrativeTextView.text = "The trial begins now. Defeat the challenge!"
        }
        
        if let currentImage = activeSlideImages[currentSlideIndex] {
            backgroundImageView.image = currentImage
        } else {
            backgroundImageView.image = UIImage.gradientImage(colors: [BasePalitColors.gradientStart, BasePalitColors.gradientEnd])
        }
        
        if currentSlideIndex == slidesPerLevel - 1 {
            actionButton.setTitle("START TRIAL CHALLENGE", for: .normal)
        } else {
            actionButton.setTitle("NEXT DIALOGUE", for: .normal)
        }
        
        updateProgressIndicators()
    }

    private func updateProgressIndicators() {
        progressIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 0..<slidesPerLevel {
            let segment = UIView()
            segment.layer.cornerRadius = 2
            segment.backgroundColor = i <= currentSlideIndex ? BasePalitColors.primary : BasePalitColors.progressBackground
            progressIndicatorStack.addArrangedSubview(segment)
        }
    }

    // MARK: - Actions & Navigation
    @objc private func handleActionTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if currentSlideIndex < slidesPerLevel - 1 {
            currentSlideIndex += 1
            UIView.transition(with: narrativeTextView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.updateSlideUI()
            })
        } else {
            // Комикс закончился — запускаем рандомную игру
            launchRandomGameController()
        }
    }

    private func launchRandomGameController() {
        let gameVC: UIViewController
        
        switch currentLevel {
        case 1: gameVC = Game3VC()
        case 2: gameVC = Game7VC()
        case 3: gameVC = Game10VC()
        case 4: gameVC = Game9VC()
        case 5: gameVC = Game6VC()
        case 6: gameVC = Game8VC()
        case 7: gameVC = Game5VC()
        case 8: gameVC = Game4VC()
        case 9: gameVC = Game2VC()
        default: gameVC = Game1VC()
        }

        // КЛЮЧЕВОЙ МОМЕНТ: перехватываем коллбек завершения игры
        // Проверяем, поддерживает ли контроллер протокол завершения, либо кастим напрямую.
        if let completionGame = gameVC as? GameCompletionProtocol {
            completionGame.onGameCompleted = { [weak self, weak gameVC] in
                // Когда игра прислала сигнал победы/завершения, закрываем её и двигаем сюжет
                gameVC?.dismiss(animated: true) {
                    self?.advanceChapterAfterSuccessfulGame()
                }
            }
        } else {
            // Запасной вариант на случай, если в самом классе игры еще не прописан протокол,
            // но мы можем установить свойство через KVC или напрямую, если в GameVC объявлен `var onGameCompleted` / `onGameComplited`.
            // Рекомендуется в твоих Game1VC - Game11VC добавить конформность к `GameCompletionProtocol`.
        }

        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }

    private func advanceChapterAfterSuccessfulGame() {
        // Увеличиваем уровень и сохраняем в UserDefaults только ПОСЛЕ победы в игре!
        currentLevel += 1
        if currentLevel > totalLevels {
            currentLevel = 1 // Зацикливание или финал по желанию
        }
        loadCurrentLevelContent()
    }
}
