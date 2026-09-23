import UIKit
import SnapKit

class NOUGHTSCROSSESViewController: MiniGameAbstractVC {
    
    // MARK: - State
    enum Player: String {
        case user   // "X"
        case waifu  // "O"
    }
    
    private var board: [Player?] = Array(repeating: nil, count: 9)
    private var buttons: [UIButton] = []
    private var isGameOver = false
    
    private var userStartsNextGame = true
    private var isUserTurn = true

    // Дополнительные ключи для UserDefaults
    private var boardStateKey: String { return boardSaveKey + "_grid" }
    private var isUserTurnKey: String { return boardSaveKey + "_turn" }
    private var nextGameStartKey: String { return boardSaveKey + "_next_start" }

    // MARK: - UI Elements
    private let gridContainerView = UIView()
    private let turnBadgeLabel = UILabel()
    private let restartButton = UIButton(type: .system)

    override var gameRules: String {
        "NOUGHTS&CROSSES.INSTRUCTIONS".localize()
    }

    override func didResetProgress() {
        clearSavedBoardState()
        resetGame(sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameGrid()
        loadProgress()
        
        // Попытка загрузить неоконченную игру
        if loadBoardState() {
            if isGameOver {
                showRestartButton()
                turnBadgeLabel.text = "GameFinished".localize()
            } else if !isUserTurn {
                updateTurnBadge()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.waifuMove()
                }
            } else {
                updateTurnBadge()
            }
        } else {
            // Новый раунд
            isUserTurn = userStartsNextGame
            updateTurnBadge()
            if !isUserTurn {
                setWaifuMessage("mini.game.aigf.texts8".localize())
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.waifuMove()
                }
            }
        }
    }
    
    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)

        let imageName: String
        switch userScore {
        case 0: imageName = "AAvatarForGeme1"
        case 1: imageName = "AAvatarForGeme2"
        case 2: imageName = "AAvatarForGeme3"
        case 3: imageName = "AAvatarForGeme4"
        case 4: imageName = "AAvatarForGeme5"
        case 5: imageName = "AAvatarForGeme6"
        case 6: imageName = "AAvatarForGeme7"
        case 7: imageName = "AAvatarForGeme8"
        case 8: imageName = "AAvatarForGeme9"
        case 9...:
            let suffix = (userScore % 2 == 0) ? "7" : "9"
            imageName = "AAvatarForGeme\(suffix)"
        default:
            imageName = "AAvatarForGeme8"
        }
        
        UIView.animate(withDuration: 1) {
            self.waifuImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: imageName)
        }
    }
    
    // MARK: - UI Setup
    private func setupGameGrid() {
        // --- Turn Badge Label ---
        turnBadgeLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        turnBadgeLabel.textColor = MyColors.gold
        turnBadgeLabel.textAlignment = .center
        turnBadgeLabel.backgroundColor = MyColors.cardBackground
        turnBadgeLabel.layer.cornerRadius = 14
        turnBadgeLabel.layer.borderWidth = 1
        turnBadgeLabel.layer.borderColor = MyColors.separator.cgColor
        turnBadgeLabel.clipsToBounds = true
        gameContainerView.addSubview(turnBadgeLabel)
        
        turnBadgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(140)
        }
        
        // --- Grid Container ---
        gridContainerView.backgroundColor = .clear
        gameContainerView.addSubview(gridContainerView)
        
        gridContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(min(view.frame.width - 60, 300))
        }
        
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fillEqually
        mainStackView.spacing = 12
        gridContainerView.addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // --- Grid Buttons ---
        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 12
            mainStackView.addArrangedSubview(rowStack)
            
            for col in 0..<3 {
                let index = row * 3 + col
                let button = UIButton(type: .custom)
                button.backgroundColor = MyColors.cardBackground
                button.layer.cornerRadius = 18
                button.layer.borderWidth = 2
                button.layer.borderColor = MyColors.separator.cgColor
                button.layer.shadowColor = MyColors.pureBlack.cgColor
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
        
        // --- Restart Button Setup ---
        restartButton.setTitle("mini.game.aigf.texts6".localize(), for: .normal)
        restartButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        restartButton.tintColor = MyColors.pureWhite
        restartButton.backgroundColor = MyColors.primary
        restartButton.layer.cornerRadius = 24
        restartButton.layer.shadowColor = MyColors.primary.cgColor
        restartButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        restartButton.layer.shadowOpacity = 0.4
        restartButton.layer.shadowRadius = 8
        restartButton.alpha = 0
        restartButton.isHidden = true
        restartButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        
        view.addSubview(restartButton)
        restartButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.equalTo(220)
            make.height.equalTo(52)
        }
    }

    // MARK: - Game Logic
    @objc private func cellTapped(_ sender: UIButton) {
        let index = sender.tag
        
        guard board[index] == nil, !isGameOver, isUserTurn else { return }
        
        isUserTurn = false
        makeMove(at: index, for: .user)
        saveCurrentBoardState()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        if !checkWinner() {
            updateTurnBadge()
            setWaifuMessage("mini.game.aigf.texts1".localize())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.waifuMove()
            }
        }
    }
    
    private func makeMove(at index: Int, for player: Player) {
        board[index] = player
        let symbol = (player == .user) ? "❌" : "⭕️"
        
        let button = buttons[index]
        button.setTitle(symbol, for: .normal)
        
        // Spring анимация добавления символа
        button.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            button.transform = .identity
        })
    }
    
    private func waifuMove() {
        guard !isGameOver else { return }
        
        let bestMove = findBestMove()
        makeMove(at: bestMove, for: .waifu)
        
        if !checkWinner() {
            isUserTurn = true
            updateTurnBadge()
            setWaifuMessage("mini.game.aigf.texts2".localize())
            saveCurrentBoardState()
        }
    }
    
    private func findBestMove() -> Int {
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        
        for p in winPatterns {
            let vals = p.map { board[$0] }
            if vals.filter({ $0 == .waifu }).count == 2 && vals.filter({ $0 == nil }).count == 1 {
                return p[vals.firstIndex(of: nil)!]
            }
        }
        
        for p in winPatterns {
            let vals = p.map { board[$0] }
            if vals.filter({ $0 == .user }).count == 2 && vals.filter({ $0 == nil }).count == 1 {
                return p[vals.firstIndex(of: nil)!]
            }
        }
        
        if board[4] == nil { return 4 }
        
        let emptyIndices = board.enumerated().compactMap { $1 == nil ? $0 : nil }
        return emptyIndices.randomElement() ?? 0
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
                setWaifuMessage("mini.game.aigf.texts3".localize())
            } else {
                waifuScore += 1
                setWaifuMessage("mini.game.aigf.texts4".localize())
            }
            updateScore(waifu: waifuScore, user: userScore)
            highlightWinningCombination(pattern: winningPattern, winner: winner)
        } else {
            setWaifuMessage("mini.game.aigf.texts5".localize())
            highlightDraw()
        }
        
        turnBadgeLabel.text = "GameFinished".localize()
        clearSavedBoardState()
        showRestartButton()
    }
    
    private func updateTurnBadge() {
        let text = isUserTurn ? "YourTurn".localize() + " (❌)" : "WaifuTurn".localize() + " (⭕️)"
        UIView.transition(with: turnBadgeLabel, duration: 0.25, options: .transitionCrossDissolve) {
            self.turnBadgeLabel.text = "  \(text)  "
        }
    }
    
    // MARK: - Visual Effects
    private func highlightWinningCombination(pattern: [Int]?, winner: Player) {
        guard let pattern = pattern else { return }
        let strokeColor = (winner == .user) ? MyColors.gold : MyColors.accentRed
        
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
    
    @objc private func resetGame(sender: UIButton?) {
        board = Array(repeating: nil, count: 9)
        buttons.forEach { btn in
            btn.layer.removeAllAnimations()
            btn.setTitle(nil, for: .normal)
            btn.transform = .identity
            btn.alpha = 1.0
            btn.layer.borderColor = MyColors.separator.cgColor
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
        
        saveCurrentBoardState()
        
        if isUserTurn {
            setWaifuMessage("mini.game.aigf.texts7".localize())
        } else {
            setWaifuMessage("mini.game.aigf.texts8".localize())
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.waifuMove()
            }
        }
    }
    
    // MARK: - Save/Load State Logic
    private func saveCurrentBoardState() {
        let rawBoard = board.map { $0?.rawValue ?? "nil" }
        UserDefaults.standard.set(rawBoard, forKey: boardStateKey)
        UserDefaults.standard.set(isUserTurn, forKey: isUserTurnKey)
        UserDefaults.standard.set(userStartsNextGame, forKey: nextGameStartKey)
    }
    
    private func loadBoardState() -> Bool {
        guard let rawBoard = UserDefaults.standard.array(forKey: boardStateKey) as? [String],
              rawBoard.count == 9 else { return false }
        
        self.board = rawBoard.map { Player(rawValue: $0) }
        self.isUserTurn = UserDefaults.standard.bool(forKey: isUserTurnKey)
        self.userStartsNextGame = UserDefaults.standard.bool(forKey: nextGameStartKey)
        
        for (index, player) in board.enumerated() {
            if let player = player {
                let symbol = (player == .user) ? "❌" : "⭕️"
                buttons[index].setTitle(symbol, for: .normal)
            } else {
                buttons[index].setTitle(nil, for: .normal)
            }
        }
        
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        
        var winningPattern: [Int]?
        var winner: Player?
        
        for p in winPatterns {
            if let p0 = board[p[0]], p0 == board[p[1]], p0 == board[p[2]] {
                winningPattern = p
                winner = p0
                break
            }
        }
        
        let isDraw = !board.contains(nil)
        
        if winningPattern != nil || isDraw {
            self.isGameOver = true
            if let winner = winner {
                highlightWinningCombination(pattern: winningPattern, winner: winner)
            } else {
                highlightDraw()
            }
        }
        
        return true
    }
    
    private func clearSavedBoardState() {
        UserDefaults.standard.removeObject(forKey: boardStateKey)
        UserDefaults.standard.removeObject(forKey: isUserTurnKey)
        UserDefaults.standard.removeObject(forKey: nextGameStartKey)
    }
}
