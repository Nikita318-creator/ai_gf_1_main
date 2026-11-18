import UIKit
import SnapKit

final class Game5VC: UIViewController, GameCompletionProtocol {
    var onGameCompleted: (() -> Void)? 
    // MARK: - State
    enum Piece: Int {
        case user = 1    // White
        case ai = 2      // Dark/Primary
    }
    
    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
        
        var depth: Int {
            switch self {
            case .easy: return 1
            case .medium: return 2
            case .hard: return 3
            case .expert: return 4
            }
        }
    }
    
    private let gridSize = 8
    private var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private var cells: [[UIButton]] = []
    private var isGameOver = false
    private var isUserTurn = true
    
    // Current AI Difficulty
    private var currentDifficulty: Difficulty = .medium {
        didSet {
            UserDefaults.standard.set(currentDifficulty.rawValue, forKey: difficultySaveKey)
        }
    }
    
    // Keys for persistence
    private let gameSaveKey = "Game4VC_progress_state"
    private var boardSaveKey: String { gameSaveKey + "_board" }
    private var turnSaveKey: String { gameSaveKey + "_turn" }
    private var difficultySaveKey: String { gameSaveKey + "_difficulty" }
    
    // UI Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let difficultyButton = UIButton(type: .system)
    
    private let scoreContainer = UIView()
    private let userScoreLabel = UILabel()
    private let aiScoreLabel = UILabel()
    private let turnIndicatorLabel = UILabel()
    
    private let boardContainer = UIView()
    private var restartButton: UIButton?
    
    // Матрица весов для Minimax AI
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        loadSavedDifficulty()
        setupUI()
        
        // Пытаемся восстановить игру, если сохранения нет — стартуем новую
        if !restoreGameState() {
            startNewGame()
        }
    }
    
    private func loadSavedDifficulty() {
        if let savedDiffRaw = UserDefaults.standard.string(forKey: difficultySaveKey),
           let diff = Difficulty(rawValue: savedDiffRaw) {
            currentDifficulty = diff
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        // Custom Navigation Bar
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
        
        titleLabel.text = "Reversi"
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
            make.width.equalTo(96)
        }
        
        // Score & Turn Container
        view.addSubview(scoreContainer)
        scoreContainer.backgroundColor = BasePalitColors.cardBackground
        scoreContainer.layer.cornerRadius = 16
        scoreContainer.layer.borderWidth = 1
        scoreContainer.layer.borderColor = BasePalitColors.separator.cgColor
        scoreContainer.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(60)
        }
        
        userScoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        userScoreLabel.textColor = BasePalitColors.textPrimary
        scoreContainer.addSubview(userScoreLabel)
        userScoreLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        aiScoreLabel.font = .systemFont(ofSize: 16, weight: .bold)
        aiScoreLabel.textColor = BasePalitColors.primary
        scoreContainer.addSubview(aiScoreLabel)
        aiScoreLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        turnIndicatorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        turnIndicatorLabel.textColor = BasePalitColors.textSecondary
        turnIndicatorLabel.textAlignment = .center
        scoreContainer.addSubview(turnIndicatorLabel)
        turnIndicatorLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
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
            make.width.height.equalTo(min(view.frame.width - 32, 380))
        }
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 2
        boardContainer.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(6)
        }
        
        for r in 0..<gridSize {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 2
            mainStack.addArrangedSubview(rowStack)
            
            var rowButtons: [UIButton] = []
            for c in 0..<gridSize {
                let btn = UIButton()
                btn.backgroundColor = BasePalitColors.background
                btn.tag = r * 10 + c
                btn.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                // Chip View
                let chip = UIView()
                chip.isUserInteractionEnabled = false
                chip.layer.cornerRadius = ((min(view.frame.width - 32, 380) / CGFloat(gridSize)) - 8) / 2
                chip.tag = 999
                chip.alpha = 0
                btn.addSubview(chip)
                chip.snp.makeConstraints { make in
                    make.edges.equalToSuperview().inset(6)
                }
                
                // Hint View
                let hint = UIView()
                hint.isUserInteractionEnabled = false
                hint.backgroundColor = BasePalitColors.primary.withAlphaComponent(0.4)
                hint.layer.cornerRadius = 6
                hint.tag = 888
                hint.isHidden = true
                btn.addSubview(hint)
                hint.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(12)
                }
                
                rowStack.addArrangedSubview(btn)
                rowButtons.append(btn)
            }
            cells.append(rowButtons)
        }
    }

    // MARK: - Game Logic
    private func startNewGame() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        isGameOver = false
        isUserTurn = true
        restartButton?.removeFromSuperview()
        restartButton = nil
        
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let cell = cells[r][c]
                cell.viewWithTag(999)?.alpha = 0
                cell.viewWithTag(999)?.transform = .identity
                cell.viewWithTag(888)?.isHidden = true
            }
        }
        
        setInitialPiece(row: 3, col: 3, piece: .ai)
        setInitialPiece(row: 3, col: 4, piece: .user)
        setInitialPiece(row: 4, col: 3, piece: .user)
        setInitialPiece(row: 4, col: 4, piece: .ai)
        
        saveGameState()
        updateUI()
    }

    private func setInitialPiece(row: Int, col: Int, piece: Piece) {
        board[row][col] = piece
        let chip = cells[row][col].viewWithTag(999)
        chip?.alpha = 1
        chip?.backgroundColor = (piece == .user) ? BasePalitColors.pureWhite : BasePalitColors.primary
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
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func applyMove(row: Int, col: Int, piece: Piece) {
        board[row][col] = piece
        animateNewPiece(row: row, col: col, piece: piece)
        
        let toFlip = getFlippablePieces(board: board, row: row, col: col, piece: piece)
        
        for (index, pos) in toFlip.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                self.board[pos.0][pos.1] = piece
                self.flipAnimation(row: pos.0, col: pos.1, newPiece: piece)
            }
        }
        
        let totalDelay = Double(toFlip.count) * 0.04 + 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            self.finalizeTurn(after: piece)
        }
    }

    private func finalizeTurn(after currentPiece: Piece) {
        guard !isGameOver else { return }
        
        let nextPlayer: Piece = (currentPiece == .user) ? .ai : .user
        
        if hasMoves(for: nextPlayer, on: board) {
            isUserTurn = (nextPlayer == .user)
            saveGameState()
            updateUI()
            
            if !isUserTurn {
                runAI()
            }
        } else {
            if hasMoves(for: currentPiece, on: board) {
                isUserTurn = (currentPiece == .user)
                saveGameState()
                updateUI()
                
                if !isUserTurn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.runAI()
                    }
                }
            } else {
                checkEndGame()
            }
        }
    }
    
    private func runAI() {
        turnIndicatorLabel.text = "AI is thinking..."
        DispatchQueue.global(qos: .userInitiated).async {
            let bestMove = self.getBestMoveMinimax()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let move = bestMove {
                    self.applyMove(row: move.0, col: move.1, piece: .ai)
                } else {
                    self.finalizeTurn(after: .ai)
                }
            }
        }
    }

    // MARK: - AI & Minimax Logic
    private func getBestMoveMinimax() -> (Int, Int)? {
        let validMoves = getAllValidMoves(for: .ai, on: board)
        if validMoves.isEmpty { return nil }
        
        if currentDifficulty == .easy {
            return validMoves.randomElement()
        }
        
        var bestScore = Int.min
        var bestMove = validMoves[0]
        let alpha = Int.min
        let beta = Int.max
        
        let sortedMoves = validMoves.sorted {
            positionWeights[$0.0][$0.1] > positionWeights[$1.0][$1.1]
        }
        
        for move in sortedMoves {
            var tempBoard = board
            tempBoard[move.0][move.1] = .ai
            let flippable = getFlippablePieces(board: tempBoard, row: move.0, col: move.1, piece: .ai)
            for pos in flippable { tempBoard[pos.0][pos.1] = .ai }
            
            let score = minimax(board: tempBoard, depth: currentDifficulty.depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }
    
    private func minimax(board: [[Piece?]], depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool) -> Int {
        if depth == 0 { return evaluateBoard(board) }
        
        var currentAlpha = alpha
        var currentBeta = beta
        
        if maximizingPlayer {
            let moves = getAllValidMoves(for: .ai, on: board)
            if moves.isEmpty {
                return minimax(board: board, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
            }
            var maxEval = Int.min
            for move in moves {
                var tempBoard = board
                tempBoard[move.0][move.1] = .ai
                let toFlip = getFlippablePieces(board: tempBoard, row: move.0, col: move.1, piece: .ai)
                for pos in toFlip { tempBoard[pos.0][pos.1] = .ai }
                
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
                    if p == .ai { score += val } else { score -= val }
                }
            }
        }
        return score
    }

    // MARK: - Save & Restore State
    private func saveGameState() {
        var flatBoard: [Int] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let piece = board[r][c] {
                    flatBoard.append(piece.rawValue)
                } else {
                    flatBoard.append(0)
                }
            }
        }
        UserDefaults.standard.set(flatBoard, forKey: boardSaveKey)
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
                chip?.backgroundColor = (piece == .user) ? BasePalitColors.pureWhite : BasePalitColors.primary
            } else {
                board[r][c] = nil
                chip?.alpha = 0
                chip?.transform = .identity
            }
        }
        
        updateUI()
        
        if !isUserTurn && !isGameOver {
            turnIndicatorLabel.text = "AI is thinking..."
            runAI()
        }
        
        return true
    }
    
    private func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
        UserDefaults.standard.removeObject(forKey: turnSaveKey)
    }

    // MARK: - Helpers
    private func hideAllHints() {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                cells[r][c].viewWithTag(888)?.isHidden = true
            }
        }
    }
    
    private func updateUI() {
        let flatBoard = board.flatMap { $0 }
        let uCount = flatBoard.filter { $0 == .user }.count
        let aCount = flatBoard.filter { $0 == .ai }.count
        
        userScoreLabel.text = "You (⚪️): \(uCount)"
        aiScoreLabel.text = "AI (🟣): \(aCount)"
        
        if !isGameOver {
            turnIndicatorLabel.text = isUserTurn ? "Your Turn" : "AI Turn"
        }
        
        if isUserTurn && !isGameOver {
            let validMoves = getAllValidMoves(for: .user, on: board)
            hideAllHints()
            for move in validMoves {
                cells[move.0][move.1].viewWithTag(888)?.isHidden = false
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
        if let onGameCompleted {
            onGameCompleted()
            return
        }
        
        isGameOver = true
        clearSavedState()
        updateUI()
        
        let flatBoard = board.flatMap { $0 }
        let uCount = flatBoard.filter { $0 == .user }.count
        let aCount = flatBoard.filter { $0 == .ai }.count
        
        if uCount > aCount {
            turnIndicatorLabel.text = "You Won!"
        } else if aCount > uCount {
            turnIndicatorLabel.text = "AI Won!"
        } else {
            turnIndicatorLabel.text = "It's a Draw!"
        }
        
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
            make.bottom.equalTo(boardContainer.snp.bottom).inset(20)
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
        restartButton = btn
    }

    @objc private func restartTapped() {
        clearSavedState()
        startNewGame()
    }
    
    @objc private func changeDifficultyTapped() {
        let alert = UIAlertController(title: "Select Difficulty", message: nil, preferredStyle: .actionSheet)
        
        for level in Difficulty.allCases {
            let action = UIAlertAction(title: level.rawValue, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.currentDifficulty = level
                self.difficultyButton.setTitle(level.rawValue, for: .normal)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                // Сбрасываем старое сохранение и начинаем новую партию при смене уровня
                self.clearSavedState()
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
    
    // MARK: - Animations
    private func flipAnimation(row: Int, col: Int, newPiece: Piece) {
        guard let chip = cells[row][col].viewWithTag(999) else { return }
        
        UIView.animate(withDuration: 0.15, animations: {
            chip.transform = CGAffineTransform(scaleX: 0.01, y: 1.0)
        }) { _ in
            chip.backgroundColor = (newPiece == .user) ? BasePalitColors.pureWhite : BasePalitColors.primary
            UIView.animate(withDuration: 0.25, animations: {
                chip.transform = .identity
            })
        }
    }
    
    private func animateNewPiece(row: Int, col: Int, piece: Piece) {
        let chip = cells[row][col].viewWithTag(999)
        chip?.backgroundColor = (piece == .user) ? BasePalitColors.pureWhite : BasePalitColors.primary
        chip?.alpha = 1
        chip?.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        
        UIView.animate(withDuration: 0.3) {
            chip?.transform = .identity
        }
    }
}
