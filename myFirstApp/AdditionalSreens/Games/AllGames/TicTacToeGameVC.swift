import UIKit
import SnapKit

class TicTacToeGameVC: BaseGameViewController {
    
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

    // Дополнительные ключи для UserDefaults на базе базового boardSaveKey
    private var boardStateKey: String { return boardSaveKey + "_grid" }
    private var isUserTurnKey: String { return boardSaveKey + "_turn" }
    private var nextGameStartKey: String { return boardSaveKey + "_next_start" }

    override var gameRules: String {
        "NOUGHTS&CROSSES.INSTRUCTIONS".localize()
    }

    override func didResetProgress() {
        // Принудительно чистим весь кэш игры
        clearSavedBoardState()
        resetGame(sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameGrid()
        loadProgress()
        
        // Попытка загрузить неоконченную игру
        if loadBoardState() {
            // Если игра успешно восстановлена
            if isGameOver {
                showRestartButton()
            } else if !isUserTurn {
                // Если мы вышли в момент, когда должна была ходить вайфу — даем ей сходить
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.waifuMove()
                }
            }
        } else {
            // Если это абсолютно новый раунд
            isUserTurn = userStartsNextGame
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
        let gridContainer = UIView()
        gameContainerView.addSubview(gridContainer)
        
        gridContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(min(view.frame.width - 60, 300))
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        gridContainer.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 10
            stackView.addArrangedSubview(rowStack)
            
            for col in 0..<3 {
                let index = row * 3 + col
                let button = UIButton()
                button.backgroundColor = TelegramColors.cardBackground
                button.layer.cornerRadius = 12
                button.titleLabel?.font = .systemFont(ofSize: 40, weight: .bold)
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
        saveCurrentBoardState() // Сохраняем ход юзера
        
        if !checkWinner() {
            setWaifuMessage("mini.game.aigf.texts1".localize())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.waifuMove()
            }
        }
    }
    
    private func makeMove(at index: Int, for player: Player) {
        board[index] = player
        let symbol = (player == .user) ? "X" : "O"
        let color = (player == .user) ? .white : TelegramColors.primary
        
        buttons[index].setTitle(symbol, for: .normal)
        buttons[index].setTitleColor(color, for: .normal)
        
        buttons[index].transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.2) {
            self.buttons[index].transform = .identity
        }
    }
    
    private func waifuMove() {
        guard !isGameOver else { return }
        
        let bestMove = findBestMove()
        makeMove(at: bestMove, for: .waifu)
        
        if !checkWinner() {
            isUserTurn = true
            setWaifuMessage("mini.game.aigf.texts2".localize())
            saveCurrentBoardState() // Сохраняем ход вайфу и передачу хода юзеру
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
                declareWinner(p0)
                return true
            }
        }
        
        if !board.contains(nil) {
            declareWinner(nil)
            return true
        }
        
        return false
    }
    
    private func declareWinner(_ winner: Player?) {
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
        } else {
            setWaifuMessage("mini.game.aigf.texts5".localize())
        }
        
        // Матч окончен -> Кэш текущего раунда больше не нужен
        clearSavedBoardState()
        showRestartButton()
    }
    
    private func showRestartButton() {
        // Защита от дублирования кнопок при перезаходе на экран завершенного матча
        if view.subviews.contains(where: { ($0 as? UIButton)?.titleLabel?.text == "mini.game.aigf.texts6".localize() }) {
            return
        }
        
        let btn = UIButton(type: .system)
        btn.setTitle("mini.game.aigf.texts6".localize(), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.tintColor = .white
        btn.backgroundColor = TelegramColors.primary
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        
        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    @objc private func resetGame(sender: UIButton?) {
        board = Array(repeating: nil, count: 9)
        buttons.forEach {
            $0.setTitle(nil, for: .normal)
            $0.transform = .identity
        }
        isGameOver = false
        sender?.removeFromSuperview()
        
        userStartsNextGame.toggle()
        isUserTurn = userStartsNextGame
        
        // Фиксируем переменные нового раунда
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
        // Конвертируем [Player?] в [String], потому что UserDefaults не жрет кастомные Енумы напрямую
        let rawBoard = board.map { $0?.rawValue ?? "nil" }
        UserDefaults.standard.set(rawBoard, forKey: boardStateKey)
        UserDefaults.standard.set(isUserTurn, forKey: isUserTurnKey)
        UserDefaults.standard.set(userStartsNextGame, forKey: nextGameStartKey)
    }
    
    private func loadBoardState() -> Bool {
        guard let rawBoard = UserDefaults.standard.array(forKey: boardStateKey) as? [String],
              rawBoard.count == 9 else { return false }
        
        // Разворачиваем строки обратно в массив Player?
        self.board = rawBoard.map { Player(rawValue: $0) }
        self.isUserTurn = UserDefaults.standard.bool(forKey: isUserTurnKey)
        self.userStartsNextGame = UserDefaults.standard.bool(forKey: nextGameStartKey)
        
        // Отрисовываем восстановленные символы на кнопках
        for (index, player) in board.enumerated() {
            if let player = player {
                let symbol = (player == .user) ? "X" : "O"
                let color = (player == .user) ? .white : TelegramColors.primary
                buttons[index].setTitle(symbol, for: .normal)
                buttons[index].setTitleColor(color, for: .normal)
            } else {
                buttons[index].setTitle(nil, for: .normal)
            }
        }
        
        // Проверяем, не была ли игра завершена на момент выхода
        let winPatterns: [[Int]] = [
            [0,1,2], [3,4,5], [6,7,8],
            [0,3,6], [1,4,7], [2,5,8],
            [0,4,8], [2,4,6]
        ]
        let hasWinner = winPatterns.contains { pattern in
            if let p0 = board[pattern[0]], p0 == board[pattern[1]], p0 == board[pattern[2]] { return true }
            return false
        }
        let isDraw = !board.contains(nil)
        
        if hasWinner || isDraw {
            self.isGameOver = true
        }
        
        return true
    }
    
    private func clearSavedBoardState() {
        UserDefaults.standard.removeObject(forKey: boardStateKey)
        UserDefaults.standard.removeObject(forKey: isUserTurnKey)
        UserDefaults.standard.removeObject(forKey: nextGameStartKey)
    }
}
