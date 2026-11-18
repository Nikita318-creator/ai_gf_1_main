import UIKit
import SnapKit

final class Game3VC: UIViewController {

    // MARK: - State
    enum Player: String {
        case user   // "X"
        case ai     // "O"
    }

    enum Difficulty: Int, CaseIterable {
        case easy = 0
        case medium = 1
        case hard = 2

        var title: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
    }

    private var board: [Player?] = Array(repeating: nil, count: 9)
    private var buttons: [UIButton] = []
    private var isGameOver = false
    private var userStartsNextGame = true
    private var isUserTurn = true
    private var currentDifficulty: Difficulty = .medium

    private var userScore = 0
    private var aiScore = 0

    // MARK: - UI Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let scoreLabel = UILabel()
    
    private let difficultySegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Easy", "Medium", "Hard"])
        sc.selectedSegmentIndex = 1
        sc.selectedSegmentTintColor = BasePalitColors.primary
        sc.backgroundColor = BasePalitColors.cardBackground
        
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: BasePalitColors.textSecondary, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .semibold)]
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: BasePalitColors.pureWhite, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .bold)]
        
        sc.setTitleTextAttributes(normalTextAttributes, for: .normal)
        sc.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        return sc
    }()

    private let turnBadgeLabel = UILabel()
    private let gridContainerView = UIView()
    private let restartButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomNavigationBar()
        setupBaseUI()
        setupGameGrid()
        
        difficultySegmentedControl.addTarget(self, action: #selector(difficultyChanged(_:)), for: .valueChanged)
        
        isUserTurn = userStartsNextGame
        updateTurnBadge()
        if !isUserTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.aiMove()
            }
        }
    }

    // MARK: - UI Setup
    private func setupCustomNavigationBar() {
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
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: backConfig)
        
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = BasePalitColors.textPrimary
        backButton.backgroundColor = BasePalitColors.cardBackground
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(dismissGame), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        scoreLabel.text = "You: 0  |  AI: 0"
        scoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        scoreLabel.textColor = BasePalitColors.textPrimary
        scoreLabel.textAlignment = .center
        customNavBar.addSubview(scoreLabel)
        
        scoreLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupBaseUI() {
        view.backgroundColor = BasePalitColors.background
        
        // Добавляем на view СЦЕНЫ, а не навбара, и привязываем к safeAreaLayoutGuide или customNavBar.snp.bottom через view
        view.addSubview(difficultySegmentedControl)
        difficultySegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }
        
        // Turn Badge
        turnBadgeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        turnBadgeLabel.textColor = BasePalitColors.gold
        turnBadgeLabel.textAlignment = .center
        turnBadgeLabel.backgroundColor = BasePalitColors.cardBackground
        turnBadgeLabel.layer.cornerRadius = 14
        turnBadgeLabel.layer.borderWidth = 1
        turnBadgeLabel.layer.borderColor = BasePalitColors.separator.cgColor
        turnBadgeLabel.clipsToBounds = true
        view.addSubview(turnBadgeLabel)
        
        turnBadgeLabel.snp.makeConstraints { make in
            make.top.equalTo(difficultySegmentedControl.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(160)
        }
        
        // Grid Container
        gridContainerView.backgroundColor = .clear
        view.addSubview(gridContainerView)
        
        gridContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(min(view.frame.width - 60, 320))
        }
        
        // Restart Button
        restartButton.setTitle("Play Again", for: .normal)
        restartButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        restartButton.tintColor = BasePalitColors.pureWhite
        restartButton.backgroundColor = BasePalitColors.primary
        restartButton.layer.cornerRadius = 24
        restartButton.layer.shadowColor = BasePalitColors.primary.cgColor
        restartButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        restartButton.layer.shadowOpacity = 0.4
        restartButton.layer.shadowRadius = 8
        restartButton.alpha = 0
        restartButton.isHidden = true
        restartButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        
        view.addSubview(restartButton)
        restartButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(30)
            make.width.equalTo(220)
            make.height.equalTo(52)
        }
    }

    private func setupGameGrid() {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fillEqually
        mainStackView.spacing = 12
        gridContainerView.addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 12
            mainStackView.addArrangedSubview(rowStack)
            
            for col in 0..<3 {
                let index = row * 3 + col
                let button = UIButton(type: .custom)
                button.backgroundColor = BasePalitColors.cardBackground
                button.layer.cornerRadius = 18
                button.layer.borderWidth = 2
                button.layer.borderColor = BasePalitColors.separator.cgColor
                button.layer.shadowColor = BasePalitColors.pureBlack.cgColor
                button.layer.shadowOffset = CGSize(width: 0, height: 4)
                button.layer.shadowOpacity = 0.25
                button.layer.shadowRadius = 6
                button.titleLabel?.font = .systemFont(ofSize: 44, weight: .bold)
                button.tag = index
                button.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                rowStack.addArrangedSubview(button)
                buttons.append(button)
            }
        }
    }

    // MARK: - Game Logic
    @objc private func cellTapped(_ sender: UIButton) {
        let index = sender.tag
        
        guard board[index] == nil, !isGameOver, isUserTurn else { return }
        
        isUserTurn = false
        makeMove(at: index, for: .user)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if !checkWinner() {
            updateTurnBadge()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.aiMove()
            }
        }
    }
    
    private func makeMove(at index: Int, for player: Player) {
        board[index] = player
        let symbol = (player == .user) ? "❌" : "⭕️"
        
        let button = buttons[index]
        button.setTitle(symbol, for: .normal)
        
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            button.transform = .identity
        })
    }
    
    private func aiMove() {
        guard !isGameOver else { return }
        
        let bestMove = findBestMove()
        makeMove(at: bestMove, for: .ai)
        
        if !checkWinner() {
            isUserTurn = true
            updateTurnBadge()
        }
    }
    
    private func findBestMove() -> Int {
        let emptyIndices = board.enumerated().compactMap { $1 == nil ? $0 : nil }
        
        switch currentDifficulty {
        case .easy:
            return emptyIndices.randomElement() ?? 0
            
        case .medium:
            if let winningOrBlockingMove = findStrategicMove() {
                return winningOrBlockingMove
            }
            return emptyIndices.randomElement() ?? 0
            
        case .hard:
            if let strategicMove = findStrategicMove() {
                return strategicMove
            }
            if board[4] == nil { return 4 }
            return emptyIndices.randomElement() ?? 0
        }
    }
    
    private func findStrategicMove() -> Int? {
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        
        for p in winPatterns {
            let vals = p.map { board[$0] }
            if vals.filter({ $0 == .ai }).count == 2 && vals.filter({ $0 == nil }).count == 1 {
                return p[vals.firstIndex(of: nil)!]
            }
        }
        
        for p in winPatterns {
            let vals = p.map { board[$0] }
            if vals.filter({ $0 == .user }).count == 2 && vals.filter({ $0 == nil }).count == 1 {
                return p[vals.firstIndex(of: nil)!]
            }
        }
        
        return nil
    }
    
    private func checkWinner() -> Bool {
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        
        for p in winPatterns {
            if let p0 = board[p[0]], p0 == board[p[1]], p0 == board[p[2]] {
                declareWinner(p0, winningPattern: p)
                return true
            }
        }
        
        if !board.contains(nil) {
            declareWinner(nil, winningPattern: nil)
            return true
        }
        
        return false
    }
    
    private func declareWinner(_ winner: Player?, winningPattern: [Int]?) {
        isGameOver = true
        
        if let winner = winner {
            if winner == .user {
                userScore += 1
            } else {
                aiScore += 1
            }
            updateScoreDisplay()
            highlightWinningCombination(pattern: winningPattern, winner: winner)
        } else {
            highlightDraw()
        }
        
        turnBadgeLabel.text = " Game Over "
        showRestartButton()
    }
    
    private func updateScoreDisplay() {
        scoreLabel.text = "You: \(userScore)  |  AI: \(aiScore)"
    }
    
    private func updateTurnBadge() {
        let text = isUserTurn ? "Your Turn (❌)" : "AI Turn (⭕️)"
        UIView.transition(with: turnBadgeLabel, duration: 0.25, options: .transitionCrossDissolve) {
            self.turnBadgeLabel.text = "  \(text)  "
        }
    }
    
    // MARK: - Actions & Effects
    @objc private func difficultyChanged(_ sender: UISegmentedControl) {
        if let newDiff = Difficulty(rawValue: sender.selectedSegmentIndex) {
            currentDifficulty = newDiff
            resetGame()
        }
    }
    
    private func highlightWinningCombination(pattern: [Int]?, winner: Player) {
        guard let pattern = pattern else { return }
        let strokeColor = (winner == .user) ? BasePalitColors.gold : BasePalitColors.accentRed
        
        for (idx, btn) in buttons.enumerated() {
            if pattern.contains(idx) {
                UIView.animate(withDuration: 0.4, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
                    btn.layer.borderColor = strokeColor.cgColor
                    btn.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    btn.alpha = 0.35
                }
            }
        }
    }
    
    private func highlightDraw() {
        buttons.forEach { btn in
            UIView.animate(withDuration: 0.3) {
                btn.alpha = 0.5
            }
        }
    }
    
    private func showRestartButton() {
        restartButton.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.restartButton.alpha = 1.0
        }
    }
    
    @objc private func resetGame() {
        board = Array(repeating: nil, count: 9)
        buttons.forEach { btn in
            btn.layer.removeAllAnimations()
            btn.setTitle(nil, for: .normal)
            btn.transform = .identity
            btn.alpha = 1.0
            btn.layer.borderColor = BasePalitColors.separator.cgColor
        }
        
        isGameOver = false
        
        UIView.animate(withDuration: 0.2) {
            self.restartButton.alpha = 0
        } completion: { _ in
            self.restartButton.isHidden = true
        }
        
        userStartsNextGame.toggle()
        isUserTurn = userStartsNextGame
        updateTurnBadge()
        
        if !isUserTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.aiMove()
            }
        }
    }
    
    @objc private func dismissGame() {
        dismiss(animated: true)
    }
}
