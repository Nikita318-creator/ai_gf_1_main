import UIKit
import SnapKit

final class Game8VC: UIViewController, GameCompletionProtocol {
    var onGameCompleted: (() -> Void)? 
    
    // MARK: - State & Types
    enum Direction {
        case up, down, left, right
    }
    
    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var timeInterval: TimeInterval {
            switch self {
            case .easy: return 0.25
            case .medium: return 0.17
            case .hard: return 0.10
            }
        }
    }
    
    private let gridSize = 16 // сетка 16x16
    private var snake: [(row: Int, col: Int)] = []
    private var food: (row: Int, col: Int) = (0, 0)
    private var currentDirection: Direction = .right
    private var nextDirection: Direction = .right
    private var gameTimer: Timer?
    private var isGameOver = false
    
    private var currentDifficulty: Difficulty = .medium {
        didSet {
            UserDefaults.standard.set(currentDifficulty.rawValue, forKey: difficultySaveKey)
            restartGameTimer()
        }
    }
    
    private var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: highscoreSaveKey)
                highScoreLabel.text = "Best: \(highScore)"
            }
        }
    }
    private var highScore = 0
    
    // Storage Keys
    private let gameSaveKey = "Game7VC_progress"
    private var highscoreSaveKey: String { gameSaveKey + "_highscore" }
    private var difficultySaveKey: String { gameSaveKey + "_difficulty" }
    
    // MARK: - UI Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let difficultyButton = UIButton(type: .system)
    
    private let scoreContainer = UIView()
    private let scoreLabel = UILabel()
    private let highScoreLabel = UILabel()
    
    private let boardContainer = UIView()
    private var cellViews: [[UIView]] = []
    
    private let controlsContainer = UIView()
    private let upButton = UIButton(type: .system)
    private let downButton = UIButton(type: .system)
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    
    private var restartButton: UIButton?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        loadSavedData()
        setupUI()
        setupSwipeGestures()
        startNewGame()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameTimer?.invalidate()
    }
    
    private func loadSavedData() {
        highScore = UserDefaults.standard.integer(forKey: highscoreSaveKey)
        if let savedDiff = UserDefaults.standard.string(forKey: difficultySaveKey),
           let diff = Difficulty(rawValue: savedDiff) {
            currentDifficulty = diff
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        // Navigation Bar
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = BasePalitColors.background
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        navSeparator.backgroundColor = BasePalitColors.separator
        customNavBar.addSubview(navSeparator)
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.backward", withConfiguration: backConfig), for: .normal)
        backButton.tintColor = BasePalitColors.textPrimary
        backButton.backgroundColor = BasePalitColors.cardBackground
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        titleLabel.text = "Snake"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = BasePalitColors.textPrimary
        titleLabel.textAlignment = .center
        customNavBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        difficultyButton.setTitle(currentDifficulty.rawValue, for: .normal)
        difficultyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        difficultyButton.tintColor = BasePalitColors.primary
        difficultyButton.backgroundColor = BasePalitColors.cardBackground
        difficultyButton.layer.cornerRadius = 16
        difficultyButton.addTarget(self, action: #selector(changeDifficultyTapped), for: .touchUpInside)
        customNavBar.addSubview(difficultyButton)
        difficultyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.equalTo(90)
        }
        
        // Score Container
        view.addSubview(scoreContainer)
        scoreContainer.backgroundColor = BasePalitColors.cardBackground
        scoreContainer.layer.cornerRadius = 16
        scoreContainer.layer.borderWidth = 1
        scoreContainer.layer.borderColor = BasePalitColors.separator.cgColor
        scoreContainer.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        scoreLabel.text = "Score: 0"
        scoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        scoreLabel.textColor = BasePalitColors.textPrimary
        scoreContainer.addSubview(scoreLabel)
        scoreLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        highScoreLabel.text = "Best: \(highScore)"
        highScoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        highScoreLabel.textColor = BasePalitColors.primary
        scoreContainer.addSubview(highScoreLabel)
        highScoreLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        // Board Container
        view.addSubview(boardContainer)
        boardContainer.backgroundColor = BasePalitColors.cardBackground
        boardContainer.layer.cornerRadius = 16
        boardContainer.layer.borderWidth = 1
        boardContainer.layer.borderColor = BasePalitColors.separator.cgColor
        boardContainer.clipsToBounds = true
        boardContainer.snp.makeConstraints { make in
            make.top.equalTo(scoreContainer.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            let boardSize = min(view.frame.width - 32, 380)
            make.width.height.equalTo(boardSize)
        }
        
        setupBoardGrid()
        setupControls()
    }
    
    private func setupBoardGrid() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 1
        boardContainer.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        for r in 0..<gridSize {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 1
            mainStack.addArrangedSubview(rowStack)
            
            var rowCells: [UIView] = []
            for c in 0..<gridSize {
                let cellView = UIView()
                cellView.backgroundColor = BasePalitColors.background
                cellView.layer.cornerRadius = 2
                rowStack.addArrangedSubview(cellView)
                rowCells.append(cellView)
            }
            cellViews.append(rowCells)
        }
    }
    
    private func setupControls() {
        view.addSubview(controlsContainer)
        controlsContainer.snp.makeConstraints { make in
            make.top.equalTo(boardContainer.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(140)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(10)
        }
        
        configureControlButton(upButton, icon: "chevron.up", action: #selector(upTapped))
        configureControlButton(downButton, icon: "chevron.down", action: #selector(downTapped))
        configureControlButton(leftButton, icon: "chevron.left", action: #selector(leftTapped))
        configureControlButton(rightButton, icon: "chevron.right", action: #selector(rightTapped))
        
        controlsContainer.addSubview(upButton)
        controlsContainer.addSubview(downButton)
        controlsContainer.addSubview(leftButton)
        controlsContainer.addSubview(rightButton)
        
        upButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(44)
        }
        downButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(44)
        }
        leftButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        rightButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
    }
    
    private func configureControlButton(_ button: UIButton, icon: String, action: Selector) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = BasePalitColors.textPrimary
        button.backgroundColor = BasePalitColors.cardBackground
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = BasePalitColors.separator.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func setupSwipeGestures() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    // MARK: - Game Logic
    private func startNewGame() {
        gameTimer?.invalidate()
        isGameOver = false
        score = 0
        currentDirection = .right
        nextDirection = .right
        
        // Начальная змейка из трех блоков в центре
        snake = [
            (row: gridSize / 2, col: gridSize / 2),
            (row: gridSize / 2, col: gridSize / 2 - 1),
            (row: gridSize / 2, col: gridSize / 2 - 2)
        ]
        
        spawnFood()
        restartButton?.removeFromSuperview()
        restartButton = nil
        
        redrawBoard()
        restartGameTimer()
    }
    
    private func restartGameTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(timeInterval: currentDifficulty.timeInterval, target: self, selector: #selector(gameTick), userInfo: nil, repeats: true)
    }
    
    @objc private func gameTick() {
        guard !isGameOver else { return }
        currentDirection = nextDirection
        
        var head = snake[0]
        switch currentDirection {
        case .up: head.row -= 1
        case .down: head.row += 1
        case .left: head.col -= 1
        case .right: head.col += 1
        }
        
        // Проверка столкновения со стенами или собой
        if head.row < 0 || head.row >= gridSize || head.col < 0 || head.col >= gridSize || snake.contains(where: { $0.row == head.row && $0.col == head.col }) {
            endGame()
            return
        }
        
        snake.insert(head, at: 0)
        
        // Проверка поедания еды
        if head.row == food.row && head.col == food.col {
            score += 1
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            spawnFood()
        } else {
            snake.removeLast()
        }
        
        redrawBoard()
    }
    
    private func spawnFood() {
        repeat {
            food = (row: Int.random(in: 0..<gridSize), col: Int.random(in: 0..<gridSize))
        } while snake.contains(where: { $0.row == food.row && $0.col == food.col })
    }
    
    private func redrawBoard() {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                cellViews[r][c].backgroundColor = BasePalitColors.background
                cellViews[r][c].layer.cornerRadius = 2
            }
        }
        
        // Отрисовка еды
        cellViews[food.row][food.col].backgroundColor = BasePalitColors.accentRed
        cellViews[food.row][food.col].layer.cornerRadius = 6
        
        // Отрисовка змейки
        for (index, segment) in snake.enumerated() {
            let cell = cellViews[segment.row][segment.col]
            cell.backgroundColor = (index == 0) ? BasePalitColors.primary : BasePalitColors.primary.withAlphaComponent(0.7)
            cell.layer.cornerRadius = 4
        }
    }
    
    private func endGame() {
        if let onGameCompleted {
            onGameCompleted()
            return
        }
        
        isGameOver = true
        gameTimer?.invalidate()
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        showRestartButton()
    }
    
    private func showRestartButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("Play Again", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.tintColor = BasePalitColors.pureWhite
        btn.backgroundColor = BasePalitColors.primary
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
        
        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(boardContainer)
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
        restartButton = btn
    }
    
    @objc private func restartTapped() {
        startNewGame()
    }
    
    // MARK: - Controls & Handlers
    @objc private func upTapped() {
        if currentDirection != .down { nextDirection = .up }
    }
    @objc private func downTapped() {
        if currentDirection != .up { nextDirection = .down }
    }
    @objc private func leftTapped() {
        if currentDirection != .right { nextDirection = .left }
    }
    @objc private func rightTapped() {
        if currentDirection != .left { nextDirection = .right }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up: if currentDirection != .down { nextDirection = .up }
        case .down: if currentDirection != .up { nextDirection = .down }
        case .left: if currentDirection != .right { nextDirection = .left }
        case .right: if currentDirection != .left { nextDirection = .right }
        default: break
        }
    }
    
    @objc private func changeDifficultyTapped() {
        let alert = UIAlertController(title: "Select Difficulty", message: nil, preferredStyle: .actionSheet)
        
        for level in Difficulty.allCases {
            let action = UIAlertAction(title: level.rawValue, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.currentDifficulty = level
                self.difficultyButton.setTitle(level.rawValue, for: .normal)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.startNewGame()
            }
            if level == currentDifficulty {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = difficultyButton
            popover.sourceRect = difficultyButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}
