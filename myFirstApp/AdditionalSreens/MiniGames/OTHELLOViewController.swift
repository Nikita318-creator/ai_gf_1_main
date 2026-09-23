import UIKit
import SnapKit

class OTHELLOViewController: MiniGameAbstractVC {
    
    // MARK: - State
    enum Piece: Int {
        case user = 1    // White / Player
        case waifu = 2   // Blue / Accent
    }
    
    private let gridSize = 8
    private var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private var cells: [[UIButton]] = []
    private var isGameOver = false
    private var isUserTurn = true
    
    // AI Difficulty Settings
    private var aiDepth = 1
    
    // UI Elements
    private let scoreHeaderStack = UIStackView()
    private let userScoreCard = UIView()
    private let waifuScoreCard = UIView()
    private let userScoreLabel = UILabel()
    private let waifuScoreLabel = UILabel()
    private let turnIndicatorLabel = UILabel()
    
    private let boardContainer = UIView()
    private var restartButton: UIButton?
    
    // Ключ для сохранения флага: чей сейчас ход
    private var turnSaveKey: String {
        return gameSaveKey + "_turn_state"
    }
    
    // Матрица весов
    private let positionWeights: [[Int]] = [
        [100, -20, 10,  5,  5, 10, -20, 100],
        [-20, -50, -2, -2, -2, -2, -50, -20],
        [ 10,  -2,  5,  1,  1,  5,  -2,  10],
        [  5,  -2,  1,  5,  5,  1,  -2,   5],
        [  5,  -2,  1,  5,  5,  1,  -2,   5],
        [ 10,  -2,  5,  1,  1,  5,  -2,  10],
        [-20, -50, -2, -2, -2, -2, -50, -20],
        [100, -20, 10,  5,  5, 10, -20, 100]
    ]

    override var gameRules: String {
        "OTHELLO.INSTRUCTIONS".localize()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGameUI()
        loadProgress()
        updateDifficultyBasedOnScore()
        
        if !restoreGameState() {
            startNewGame(isFirstGame: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Гарантируем идеальный радиус круглых фишек после layout pass
        updateChipsCornerRadius()
    }
    
    // MARK: - Restore User Score Logic
    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)
        updateDifficultyBasedOnScore()

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
    
    override func didResetProgress() {
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
        UserDefaults.standard.removeObject(forKey: turnSaveKey)
        updateDifficultyBasedOnScore()
        startNewGame(isFirstGame: false)
    }
    
    private func updateDifficultyBasedOnScore() {
        switch userScore {
        case 0: aiDepth = 1
        case 1: aiDepth = 1
        case 2: aiDepth = 2
        case 3: aiDepth = 3
        default: aiDepth = 4
        }
    }

    // MARK: - UI Setup
    private func setupGameUI() {
        // --- Score Header Panel ---
        scoreHeaderStack.axis = .horizontal
        scoreHeaderStack.distribution = .equalSpacing
        scoreHeaderStack.alignment = .center
        gameContainerView.addSubview(scoreHeaderStack)
        
        scoreHeaderStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        
        setupScoreCard(userScoreCard, label: userScoreLabel, title: "⚪️ " + ("reversi.score.you".localize().isEmpty ? "YOU" : "reversi.score.you".localize()))
        setupScoreCard(waifuScoreCard, label: waifuScoreLabel, title: "🔵 " + ("reversi.score.waifu".localize().isEmpty ? "WAIFU" : "reversi.score.waifu".localize()))
        
        turnIndicatorLabel.font = .systemFont(ofSize: 14, weight: .black)
        turnIndicatorLabel.textColor = MyColors.gold
        turnIndicatorLabel.textAlignment = .center
        
        scoreHeaderStack.addArrangedSubview(userScoreCard)
        scoreHeaderStack.addArrangedSubview(turnIndicatorLabel)
        scoreHeaderStack.addArrangedSubview(waifuScoreCard)
        
        userScoreCard.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
        
        waifuScoreCard.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
        
        // --- Board Container ---
        boardContainer.backgroundColor = MyColors.tile2
        boardContainer.layer.cornerRadius = 24
        boardContainer.layer.borderWidth = 2.5
        boardContainer.layer.borderColor = MyColors.separator.cgColor
        boardContainer.layer.shadowColor = MyColors.pureBlack.cgColor
        boardContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        boardContainer.layer.shadowOpacity = 0.4
        boardContainer.layer.shadowRadius = 12
        boardContainer.clipsToBounds = true
        gameContainerView.addSubview(boardContainer)
        
        let boardWidth = min(view.frame.width - 32, 360)
        boardContainer.snp.makeConstraints { make in
            make.top.equalTo(scoreHeaderStack.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(boardWidth)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 3
        mainStack.backgroundColor = MyColors.separator.withAlphaComponent(0.6)
        boardContainer.addSubview(mainStack)
        
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        for r in 0..<gridSize {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 3
            mainStack.addArrangedSubview(rowStack)
            
            var rowButtons: [UIButton] = []
            for c in 0..<gridSize {
                let btn = UIButton()
                btn.backgroundColor = MyColors.cardBackground
                btn.layer.cornerRadius = 4
                btn.tag = r * 10 + c
                btn.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                // ИДЕАЛЬНО КРУГЛАЯ СТРОГО КВАДРАТНАЯ ФИШКА
                let chip = UIView()
                chip.isUserInteractionEnabled = false
                chip.layer.shadowColor = MyColors.pureBlack.cgColor
                chip.layer.shadowOffset = CGSize(width: 0, height: 2)
                chip.layer.shadowOpacity = 0.3
                chip.layer.shadowRadius = 2
                chip.tag = 999
                chip.alpha = 0
                btn.addSubview(chip)
                
                chip.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    // Делаем ширину и высоту строго одинаковой (78% от размера ячейки)
                    make.width.height.equalToSuperview().multipliedBy(0.78)
                }
                
                // Подсказка потенциального хода
                let hint = UIView()
                hint.isUserInteractionEnabled = false
                hint.backgroundColor = MyColors.primary
                hint.layer.cornerRadius = 5
                hint.layer.shadowColor = MyColors.primary.cgColor
                hint.layer.shadowOffset = .zero
                hint.layer.shadowOpacity = 0.8
                hint.layer.shadowRadius = 4
                hint.tag = 888
                hint.isHidden = true
                btn.addSubview(hint)
                
                hint.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(10)
                }
                
                rowStack.addArrangedSubview(btn)
                rowButtons.append(btn)
            }
            cells.append(rowButtons)
        }
    }
    
    private func updateChipsCornerRadius() {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let chip = cells[r][c].viewWithTag(999) {
                    chip.layoutIfNeeded()
                    // Так как width == height, cornerRadius = height / 2 дает идеологически чистый круг
                    chip.layer.cornerRadius = chip.bounds.height / 2
                }
            }
        }
    }
    
    private func setupScoreCard(_ card: UIView, label: UILabel, title: String) {
        card.backgroundColor = MyColors.cardBackground
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1.5
        card.layer.borderColor = MyColors.separator.cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .bold)
        titleLabel.textColor = MyColors.textSecondary
        titleLabel.textAlignment = .center
        
        label.font = .systemFont(ofSize: 18, weight: .black)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.text = "0"
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, label])
        stack.axis = .vertical
        stack.spacing = 1
        stack.alignment = .center
        
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func startNewGame(isFirstGame: Bool) {
        restartButton?.removeFromSuperview()
        restartButton = nil
        
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        isGameOver = false
        isUserTurn = true
        
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let cell = cells[r][c]
                cell.viewWithTag(999)?.alpha = 0
                cell.viewWithTag(999)?.transform = .identity
                cell.viewWithTag(888)?.isHidden = true
            }
        }
        
        setInitialPiece(row: 3, col: 3, piece: .waifu)
        setInitialPiece(row: 3, col: 4, piece: .user)
        setInitialPiece(row: 4, col: 3, piece: .user)
        setInitialPiece(row: 4, col: 4, piece: .waifu)
        
        if !isFirstGame {
            setWaifuMessage("reversi.start".localize())
        }
        
        saveGameState()
        updateUI()
        
        view.setNeedsLayout()
    }

    private func setInitialPiece(row: Int, col: Int, piece: Piece) {
        board[row][col] = piece
        if let chip = cells[row][col].viewWithTag(999) {
            chip.alpha = 1
            applyChipStyle(chip, piece: piece)
        }
    }

    @objc private func cellTapped(_ sender: UIButton) {
        guard isUserTurn, !isGameOver else { return }
        let r = sender.tag / 10
        let c = sender.tag % 10
        
        if canPlace(board: board, row: r, col: c, piece: .user) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            hideAllHints()
            applyMove(row: r, col: c, piece: .user)
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            setWaifuMessage("reversi.invalidMove".localize())
        }
    }

    private func applyMove(row: Int, col: Int, piece: Piece) {
        board[row][col] = piece
        animateNewPiece(row: row, col: col, piece: piece)
        
        let toFlip = getFlippablePieces(board: board, row: row, col: col, piece: piece)
        
        for (index, pos) in toFlip.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                self.board[pos.0][pos.1] = piece
                self.flipAnimation(row: pos.0, col: pos.1, newPiece: piece)
            }
        }
        
        let totalDelay = Double(toFlip.count) * 0.05 + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            self.finalizeTurn(after: piece)
        }
    }

    private func finalizeTurn(after currentPiece: Piece) {
        guard !isGameOver else { return }
        
        let userHasMoves = hasMoves(for: .user, on: board)
        let waifuHasMoves = hasMoves(for: .waifu, on: board)
        
        // Ни у кого нет ходов -> Гарантированное завершение игры и расчет очков
        if !userHasMoves && !waifuHasMoves {
            checkEndGame()
            return
        }
        
        let nextPlayer: Piece = (currentPiece == .user) ? .waifu : .user
        let nextPlayerHasMoves = (nextPlayer == .user) ? userHasMoves : waifuHasMoves
        
        if nextPlayerHasMoves {
            isUserTurn = (nextPlayer == .user)
            saveGameState()
            updateUI()
            
            if !isUserTurn {
                setWaifuMessage("reversi.waifuThinking".localize())
                runAI()
            } else {
                setWaifuMessage("reversi.yourTurn".localize())
            }
        } else {
            // У следующего игрока нет ходов -> Ход передается обратно текущему
            setWaifuMessage("reversi.noMoves".localize())
            isUserTurn = (currentPiece == .user)
            saveGameState()
            updateUI()
            
            if !isUserTurn {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.runAI()
                }
            }
        }
    }
    
    private func runAI() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateDifficultyBasedOnScore()
            let bestMove = self.getBestMoveMinimax()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let move = bestMove {
                    self.applyMove(row: move.0, col: move.1, piece: .waifu)
                } else {
                    self.finalizeTurn(after: .waifu)
                }
            }
        }
    }

    // MARK: - Smart AI (Minimax)
    private func getBestMoveMinimax() -> (Int, Int)? {
        let validMoves = getAllValidMoves(for: .waifu, on: board)
        if validMoves.isEmpty { return nil }
        
        switch userScore {
        case 0:
            return validMoves.randomElement()
            
        case 1:
            var bestM = validMoves[0]
            var maxFlips = -1
            for move in validMoves {
                let flips = getFlippablePieces(board: board, row: move.0, col: move.1, piece: .waifu).count
                if flips > maxFlips {
                    maxFlips = flips
                    bestM = move
                }
            }
            return bestM
            
        default:
            var bestScore = Int.min
            var bestMove = validMoves[0]
            let alpha = Int.min
            let beta = Int.max
            
            let sortedMoves = validMoves.sorted {
                positionWeights[$0.0][$0.1] > positionWeights[$1.0][$1.1]
            }
            
            for move in sortedMoves {
                var tempBoard = board
                tempBoard[move.0][move.1] = .waifu
                let flippable = getFlippablePieces(board: tempBoard, row: move.0, col: move.1, piece: .waifu)
                for pos in flippable { tempBoard[pos.0][pos.1] = .waifu }
                
                let score = minimax(board: tempBoard, depth: aiDepth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }
            return bestMove
        }
    }
    
    private func minimax(board: [[Piece?]], depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool) -> Int {
        if depth == 0 { return evaluateBoard(board) }
        
        var currentAlpha = alpha
        var currentBeta = beta
        
        if maximizingPlayer {
            let moves = getAllValidMoves(for: .waifu, on: board)
            if moves.isEmpty {
                return minimax(board: board, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
            }
            var maxEval = Int.min
            for move in moves {
                var tempBoard = board
                tempBoard[move.0][move.1] = .waifu
                let toFlip = getFlippablePieces(board: tempBoard, row: move.0, col: move.1, piece: .waifu)
                for pos in toFlip { tempBoard[pos.0][pos.1] = .waifu }
                
                let eval = minimax(board: tempBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, maximizingPlayer: false)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                if currentBeta <= currentAlpha { break }
            }
            return maxEval
        } else {
            let moves = getAllValidMoves(for: .user, on: board)
            if moves.isEmpty {
                return minimax(board: board, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true)
            }
            var minEval = Int.max
            for move in moves {
                var tempBoard = board
                tempBoard[move.0][move.1] = .user
                let toFlip = getFlippablePieces(board: tempBoard, row: move.0, col: move.1, piece: .user)
                for pos in toFlip { tempBoard[pos.0][pos.1] = .user }
                
                let eval = minimax(board: tempBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, maximizingPlayer: true)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                if currentBeta <= currentAlpha { break }
            }
            return minEval
        }
    }
    
    private func evaluateBoard(_ b: [[Piece?]]) -> Int {
        var score = 0
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let p = b[r][c] {
                    let val = positionWeights[r][c]
                    if p == .waifu { score += val } else { score -= val }
                }
            }
        }
        return score
    }

    // MARK: - Helper Logic & Styling
    private func hideAllHints() {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                cells[r][c].viewWithTag(888)?.isHidden = true
            }
        }
    }
    
    private func applyChipStyle(_ chip: UIView, piece: Piece) {
        chip.layoutIfNeeded()
        chip.layer.cornerRadius = chip.bounds.height / 2
        
        if piece == .user {
            chip.backgroundColor = MyColors.pureWhite
            chip.layer.borderWidth = 1.5
            chip.layer.borderColor = MyColors.separator.cgColor
        } else {
            chip.backgroundColor = MyColors.primary
            chip.layer.borderWidth = 0
        }
    }
    
    private func updateUI() {
        let flatBoard = board.flatMap { $0 }
        let uCount = flatBoard.filter { $0 == .user }.count
        let wCount = flatBoard.filter { $0 == .waifu }.count
        
        userScoreLabel.text = "\(uCount)"
        waifuScoreLabel.text = "\(wCount)"
        
        UIView.animate(withDuration: 0.2) {
            if self.isUserTurn {
                self.userScoreCard.layer.borderColor = MyColors.gold.cgColor
                self.waifuScoreCard.layer.borderColor = MyColors.separator.cgColor
                self.turnIndicatorLabel.text = "◀︎"
            } else {
                self.userScoreCard.layer.borderColor = MyColors.separator.cgColor
                self.waifuScoreCard.layer.borderColor = MyColors.primary.cgColor
                self.turnIndicatorLabel.text = "▶︎"
            }
        }
        
        if isUserTurn && !isGameOver {
            let validMoves = getAllValidMoves(for: .user, on: board)
            hideAllHints()
            for move in validMoves {
                let hint = cells[move.0][move.1].viewWithTag(888)
                hint?.isHidden = false
                
                hint?.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                UIView.animate(withDuration: 0.4, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
                    hint?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }
            }
        } else {
            hideAllHints()
        }
    }

    private func getFlippablePieces(board: [[Piece?]], row: Int, col: Int, piece: Piece) -> [(Int, Int)] {
        var toFlip: [(Int, Int)] = []
        let directions = [(0,1),(0,-1),(1,0),(-1,0),(1,1),(-1,-1),(1,-1),(-1,1)]
        
        for dir in directions {
            var r = row + dir.0
            var c = col + dir.1
            var potential: [(Int, Int)] = []
            
            while r >= 0 && r < gridSize && c >= 0 && c < gridSize, let current = board[r][c], current != piece {
                potential.append((r, c))
                r += dir.0
                c += dir.1
            }
            
            if r >= 0 && r < gridSize && c >= 0 && c < gridSize, board[r][c] == piece {
                toFlip.append(contentsOf: potential)
            }
        }
        return toFlip
    }

    private func canPlace(board: [[Piece?]], row: Int, col: Int, piece: Piece) -> Bool {
        if board[row][col] != nil { return false }
        return !getFlippablePieces(board: board, row: row, col: col, piece: piece).isEmpty
    }

    private func hasMoves(for piece: Piece, on board: [[Piece?]]) -> Bool {
        return !getAllValidMoves(for: piece, on: board).isEmpty
    }

    private func getAllValidMoves(for piece: Piece, on board: [[Piece?]]) -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if canPlace(board: board, row: r, col: c, piece: piece) { moves.append((r, c)) }
            }
        }
        return moves
    }

    private func checkEndGame() {
        isGameOver = true
        updateUI()
        
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
        UserDefaults.standard.removeObject(forKey: turnSaveKey)
        
        let flatBoard = board.flatMap { $0 }
        let uCount = flatBoard.filter { $0 == .user }.count
        let wCount = flatBoard.filter { $0 == .waifu }.count
        
        if uCount > wCount {
            userScore += 1
            setWaifuMessage("reversi.win".localize())
        } else if wCount > uCount {
            waifuScore += 1
            setWaifuMessage("reversi.lose".localize())
        } else {
            setWaifuMessage("reversi.draw".localize())
        }
        
        updateScore(waifu: waifuScore, user: userScore)
        showRestartButton()
    }

    private func showRestartButton() {
        guard restartButton == nil else { return }
        
        let btn = UIButton(type: .system)
        btn.setTitle("reversi.restart".localize(), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .black)
        
        // Яркий контрастный стиль из палитры MyColors
        btn.setTitleColor(MyColors.pureBlack, for: .normal)
        btn.backgroundColor = MyColors.gold
        btn.layer.cornerRadius = 24
        btn.layer.borderWidth = 2
        btn.layer.borderColor = MyColors.pureWhite.cgColor
        
        // Свечение/Тень вокруг кнопки
        btn.layer.shadowColor = MyColors.gold.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowOpacity = 0.6
        btn.layer.shadowRadius = 10
        
        btn.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
        
        gameContainerView.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(boardContainer)
            make.width.equalTo(220)
            make.height.equalTo(52)
        }
        
        btn.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        btn.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            btn.transform = .identity
            btn.alpha = 1
        })
        
        restartButton = btn
    }

    @objc private func restartTapped(sender: UIButton) {
        startNewGame(isFirstGame: false)
    }
    
    // MARK: - Save & Restore Progress Logic
    
    private func saveGameState() {
        var flatBoardRepresentation: [Int] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let piece = board[r][c] {
                    flatBoardRepresentation.append(piece.rawValue)
                } else {
                    flatBoardRepresentation.append(0)
                }
            }
        }
        
        UserDefaults.standard.set(flatBoardRepresentation, forKey: boardSaveKey)
        UserDefaults.standard.set(isUserTurn, forKey: turnSaveKey)
    }
    
    private func restoreGameState() -> Bool {
        guard let flatBoard = UserDefaults.standard.array(forKey: boardSaveKey) as? [Int],
              flatBoard.count == gridSize * gridSize else {
            return false
        }
        
        isUserTurn = UserDefaults.standard.bool(forKey: turnSaveKey)
        isGameOver = false
        
        for index in 0..<flatBoard.count {
            let r = index / gridSize
            let c = index % gridSize
            let rawValue = flatBoard[index]
            
            let cell = cells[r][c]
            let chip = cell.viewWithTag(999)
            cell.viewWithTag(888)?.isHidden = true
            
            if let piece = Piece(rawValue: rawValue) {
                board[r][c] = piece
                chip?.alpha = 1
                chip?.transform = .identity
                if let chip = chip { applyChipStyle(chip, piece: piece) }
            } else {
                board[r][c] = nil
                chip?.alpha = 0
                chip?.transform = .identity
            }
        }
        
        updateUI()
        
        if !isUserTurn && !isGameOver {
            setWaifuMessage("reversi.waifuThinking".localize())
            runAI()
        } else {
            setWaifuMessage("reversi.yourTurn".localize())
        }
        
        return true
    }
    
    // MARK: - Animations
    
    private func flipAnimation(row: Int, col: Int, newPiece: Piece) {
        guard let chip = cells[row][col].viewWithTag(999) else { return }
        
        UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseIn, animations: {
            chip.transform = CGAffineTransform(scaleX: 0.01, y: 1.1)
        }) { _ in
            self.applyChipStyle(chip, piece: newPiece)
            
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: {
                chip.transform = .identity
            }, completion: nil)
        }
    }
    
    private func animateNewPiece(row: Int, col: Int, piece: Piece) {
        guard let chip = cells[row][col].viewWithTag(999) else { return }
        
        applyChipStyle(chip, piece: piece)
        chip.alpha = 1
        chip.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            chip.transform = .identity
        })
    }
}
