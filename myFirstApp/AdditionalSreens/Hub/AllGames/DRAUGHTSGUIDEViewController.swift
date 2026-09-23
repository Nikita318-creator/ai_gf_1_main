import UIKit
import SnapKit

class DRAUGHTSGUIDEViewController: MiniGameAbstractVC {
    
    // MARK: - Constants
    private var aiDepth = 4
    
    // MARK: - Models
    enum PieceColor: String { case white, black }
    
    struct Piece: Equatable {
        var color: PieceColor
        var isKing: Bool = false
    }
    
    struct Position: Equatable, Hashable {
        let row: Int
        let col: Int
    }
    
    struct Move: Equatable {
        let from: Position
        let to: Position
        let captures: [Position]
        let becomesKing: Bool
    }
    
    typealias Board = [[Piece?]]
    
    // MARK: - Game State
    private var board: Board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private var cellViews: [[UIView]] = []
    private var selectedPosition: Position?
    private var validMoves: [Move] = []
    
    private var isUserTurn = true
    private var mustContinueCapture = false
    
    private var consecutiveNonCaptures = 0
    private var userStartsNextGame = true
    
    // Ключ для сохранения поля (на базе boardSaveKey, который мы обсудили)
    private var checkersBoardKey: String { return boardSaveKey + "_matrix" }
    private var checkersTurnKey: String { return boardSaveKey + "_turn" }
    
    // UI Elements
    private var boardContainer: UIView!
    private var cellSize: CGFloat = 0
    
    override var gameRules: String {
        "DRAUGHTSGUIDE.INSTRUCTIONS".localize()
    }

    override func didResetProgress() {
        updateDifficultyBasedOnScore()
        // При полном сбросе — очищаем сохраненную доску
        UserDefaults.standard.removeObject(forKey: checkersBoardKey)
        UserDefaults.standard.removeObject(forKey: checkersTurnKey)
        resetGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProgress() // Сначала грузим очки, чтобы знать userScore
        updateDifficultyBasedOnScore()
        
        // Пытаемся загрузить сохраненную сессию
        if !loadGameState() {
            // Если сохранения нет — стартуем новую доску с нуля
            setupInitialBoardState()
            isUserTurn = true
        }
        
        renderBoard()
        
        // Если восстановили состояние, и сейчас ход AI — запускаем его
        if !isUserTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.aiTurn()
            }
        }
    }
    
    private func updateDifficultyBasedOnScore() {
        switch userScore {
        case 0: aiDepth = 1
        case 1: aiDepth = 2
        case 2: aiDepth = 3
        case 3...: aiDepth = 4
        default: aiDepth = 4
        }
        print("Текущая сложность AI: \(aiDepth)")
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
    
    private func setupInitialBoardState() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        
        for row in 0..<8 {
            for col in 0..<8 {
                if (row + col) % 2 != 0 {
                    if row < 3 {
                        board[row][col] = Piece(color: .black)
                    } else if row > 4 {
                        board[row][col] = Piece(color: .white)
                    }
                }
            }
        }
    }
    
    // MARK: - UI Rendering
    private func renderBoard() {
        // Защита от дублирования вьюх при пересоздании доски
        boardContainer?.removeFromSuperview()
        
        boardContainer = UIView()
        boardContainer.backgroundColor = MyColors.pureBlack
        boardContainer.layer.cornerRadius = 12
        boardContainer.layer.borderWidth = 3
        boardContainer.layer.borderColor = MyColors.primary.cgColor
        boardContainer.clipsToBounds = true
        
        gameContainerView.addSubview(boardContainer)
        let boardSize = min(view.frame.width - 40, 400)
        boardContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(boardSize)
        }
        
        cellSize = boardSize / 8
        cellViews = []
        
        for row in 0..<8 {
            var rowViews: [UIView] = []
            for col in 0..<8 {
                let cell = createCell(row: row, col: col)
                rowViews.append(cell)
            }
            cellViews.append(rowViews)
        }
        
        updateAllCells()
    }
    
    private func createCell(row: Int, col: Int) -> UIView {
        let cell = UIView()
        let isDark = (row + col) % 2 != 0
        cell.backgroundColor = isDark ? MyColors.cardBackground : MyColors.textPrimary
        
        boardContainer.addSubview(cell)
        cell.snp.makeConstraints { make in
            make.width.height.equalTo(cellSize)
            make.top.equalToSuperview().offset(CGFloat(row) * cellSize)
            make.leading.equalToSuperview().offset(CGFloat(col) * cellSize)
        }
        
        if isDark {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleCellTap(_:)))
            cell.tag = row * 10 + col
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }
    
    private func updateAllCells() {
        for row in 0..<8 {
            for col in 0..<8 {
                updateCell(at: Position(row: row, col: col))
            }
        }
    }
    
    private func updateCell(at pos: Position) {
        let cell = cellViews[pos.row][pos.col]
        cell.subviews.forEach { $0.removeFromSuperview() }
        
        if let selected = selectedPosition {
            let isValidDest = validMoves.contains { $0.from == selected && $0.to == pos }
            if isValidDest {
                let highlight = UIView()
                highlight.backgroundColor = MyColors.avatarBackground.withAlphaComponent(0.4)
                highlight.layer.cornerRadius = cellSize * 0.15
                cell.addSubview(highlight)
                highlight.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(cellSize * 0.3)
                }
            }
        }
        
        guard let piece = board[pos.row][pos.col] else { return }
        
        let pieceView = UIView()
        pieceView.layer.cornerRadius = cellSize * 0.35
        pieceView.backgroundColor = piece.color == .white ? MyColors.pureWhite : MyColors.primary
        pieceView.layer.shadowColor = MyColors.pureBlack.cgColor
        pieceView.layer.shadowOffset = CGSize(width: 0, height: 2)
        pieceView.layer.shadowRadius = 4
        pieceView.layer.shadowOpacity = 0.3
        
        if let selected = selectedPosition, selected == pos {
            pieceView.layer.borderWidth = 3
            pieceView.layer.borderColor = MyColors.gold.cgColor
        }
        
        cell.addSubview(pieceView)
        pieceView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(cellSize * 0.7)
        }
        
        if piece.isKing {
            let crown = UILabel()
            crown.text = "👑"
            crown.font = .systemFont(ofSize: cellSize * 0.35)
            crown.textAlignment = .center
            pieceView.addSubview(crown)
            crown.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
    }
    
    // MARK: - User Interaction
    @objc private func handleCellTap(_ sender: UITapGestureRecognizer) {
        guard isUserTurn else { return }
        
        guard let cell = sender.view else { return }
        let row = cell.tag / 10
        let col = cell.tag % 10
        let tappedPos = Position(row: row, col: col)
        
        if let selected = selectedPosition {
            if let move = validMoves.first(where: { $0.from == selected && $0.to == tappedPos }) {
                executeUserMove(move)
                return
            }
        }
        
        if mustContinueCapture { return }
        
        if board[row][col]?.color == .white {
            selectedPosition = tappedPos
            calculateUserMoves()
            updateAllCells()
        } else {
            if !mustContinueCapture {
                selectedPosition = nil
                validMoves = []
                updateAllCells()
            }
        }
    }
    
    // MARK: - Move Generation Logic (Engine)
    private func calculateUserMoves() {
        validMoves = []
        guard let selected = selectedPosition else { return }
        let allMoves = getLegalMoves(for: board, color: .white)
        validMoves = allMoves.filter { $0.from == selected }
    }
    
    private func getLegalMoves(for currentBoard: Board, color: PieceColor) -> [Move] {
        var captureMoves: [Move] = []
        var regularMoves: [Move] = []
        
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = currentBoard[row][col], piece.color == color else { continue }
                let pos = Position(row: row, col: col)
                
                let captures = getCaptureMoves(board: currentBoard, from: pos)
                captureMoves.append(contentsOf: captures)
                
                if captureMoves.isEmpty {
                    let walks = getRegularMoves(board: currentBoard, from: pos)
                    regularMoves.append(contentsOf: walks)
                }
            }
        }
        
        if !captureMoves.isEmpty {
            return captureMoves
        }
        return regularMoves
    }
    
    private func getRegularMoves(board: Board, from pos: Position) -> [Move] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        var moves: [Move] = []
        
        let directions: [(Int, Int)] = piece.isKing ?
            [(-1, -1), (-1, 1), (1, -1), (1, 1)] :
            (piece.color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])
        
        for (dRow, dCol) in directions {
            let newRow = pos.row + dRow
            let newCol = pos.col + dCol
            
            if isValid(newRow, newCol), board[newRow][newCol] == nil {
                let newPos = Position(row: newRow, col: newCol)
                moves.append(Move(
                    from: pos,
                    to: newPos,
                    captures: [],
                    becomesKing: willBecomeKing(at: newPos, color: piece.color, isKing: piece.isKing)
                ))
            }
        }
        return moves
    }
    
    private func getCaptureMoves(board: Board, from pos: Position) -> [Move] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        return findJumps(board: board, currentPos: pos, color: piece.color, isKing: piece.isKing, capturedSoFar: [])
    }
    
    private func findJumps(board: Board, currentPos: Position, color: PieceColor, isKing: Bool, capturedSoFar: [Position]) -> [Move] {
        var moves: [Move] = []
        
        let directions: [(Int, Int)] = isKing ?
            [(-1, -1), (-1, 1), (1, -1), (1, 1)] :
            (color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])
        
        for (dRow, dCol) in directions {
            let enemyRow = currentPos.row + dRow
            let enemyCol = currentPos.col + dCol
            let landRow = currentPos.row + dRow * 2
            let landCol = currentPos.col + dCol * 2
            
            let enemyPos = Position(row: enemyRow, col: enemyCol)
            
            if isValid(landRow, landCol),
               let enemyPiece = board[enemyRow][enemyCol],
               enemyPiece.color != color,
               board[landRow][landCol] == nil,
               !capturedSoFar.contains(enemyPos) {
                
                var nextBoard = board
                nextBoard[landRow][landCol] = nextBoard[currentPos.row][currentPos.col]
                nextBoard[currentPos.row][currentPos.col] = nil
                nextBoard[enemyRow][enemyCol] = nil
                
                let landPos = Position(row: landRow, col: landCol)
                var newCaptures = capturedSoFar
                newCaptures.append(enemyPos)
                
                let promoted = willBecomeKing(at: landPos, color: color, isKing: isKing)
                
                if promoted && !isKing {
                    moves.append(Move(from: currentPos, to: landPos, captures: newCaptures, becomesKing: true))
                } else {
                    let subMoves = findJumps(board: nextBoard, currentPos: landPos, color: color, isKing: isKing, capturedSoFar: newCaptures)
                    if subMoves.isEmpty {
                        moves.append(Move(from: currentPos, to: landPos, captures: newCaptures, becomesKing: isKing))
                    } else {
                        moves.append(contentsOf: subMoves)
                    }
                }
            }
        }
        
        return moves.map { move in
            return Move(from: currentPos, to: move.to, captures: move.captures, becomesKing: move.becomesKing)
        }
    }
    
    // MARK: - Game Loop
    private func executeUserMove(_ move: Move) {
        animateMove(move) { [weak self] in
            guard let self = self else { return }
            self.finalizeMove(move)
            
            if !move.captures.isEmpty {
                let canCaptureMore = !self.getCaptureMoves(board: self.board, from: move.to).isEmpty
                if canCaptureMore && !move.becomesKing {
                    self.mustContinueCapture = true
                    self.selectedPosition = move.to
                    self.calculateUserMoves()
                    self.updateAllCells()
                    self.saveGameState() // Фиксируем промежуточное состояние серии боев
                    return
                }
            }
            
            self.mustContinueCapture = false
            self.isUserTurn = false
            
            self.saveGameState() // Фиксируем окончание хода юзера
            
            if self.checkWinCondition() { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.aiTurn()
            }
        }
    }
    
    private func finalizeMove(_ move: Move) {
        for capture in move.captures {
            board[capture.row][capture.col] = nil
        }
        
        let movingPiece = board[move.from.row][move.from.col]
        board[move.to.row][move.to.col] = movingPiece
        board[move.from.row][move.from.col] = nil
        
        if move.becomesKing {
            board[move.to.row][move.to.col]?.isKing = true
        }
        
        if !move.captures.isEmpty {
            consecutiveNonCaptures = 0
            if isUserTurn {
                let messages = ["mini.game.aigf.texts19".localize(), "mini.game.aigf.texts20".localize(), "mini.game.aigf.texts21".localize()]
                setWaifuMessage(messages.randomElement()!)
            } else {
                let messages = ["mini.game.aigf.texts24".localize(), "mini.game.aigf.texts25".localize(), "mini.game.aigf.texts26".localize()]
                setWaifuMessage(messages.randomElement()!)
            }
        } else {
            consecutiveNonCaptures += 1
        }
        
        selectedPosition = nil
        validMoves = []
        updateAllCells()
    }
    
    // MARK: - AI Logic
    private func aiTurn() {
        guard !isUserTurn else { return }
        
        setWaifuMessage("mini.game.aigf.texts18".localize())
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let bestMove = self.runMinimax()
            
            DispatchQueue.main.async {
                guard let move = bestMove else {
                    self.handleAILoss()
                    return
                }
                
                self.executeAIMove(move)
            }
        }
    }

    private func executeAIMove(_ move: Move) {
        animateMove(move) { [weak self] in
            guard let self = self else { return }
            self.finalizeMove(move)
            
            self.isUserTurn = true
            self.saveGameState() // Фиксируем окончание хода AI
            
            if self.checkWinCondition() { return }
            
            self.setWaifuMessage("mini.game.aigf.texts19".localize())
        }
    }
    
    private func runMinimax() -> Move? {
        let possibleMoves = getLegalMoves(for: board, color: .black)
        if possibleMoves.count == 1 { return possibleMoves.first }
        if possibleMoves.isEmpty { return nil }
        
        var bestMove: Move?
        var maxEval = Int.min
        let alpha = Int.min
        let beta = Int.max
        
        for move in possibleMoves {
            let simulatedBoard = applyMoveToBoard(board, move: move)
            let eval = minimax(board: simulatedBoard, depth: aiDepth - 1, alpha: alpha, beta: beta, isMaximizing: false)
            
            if eval > maxEval {
                maxEval = eval
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    private func minimax(board: Board, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        if depth == 0 { return evaluateBoard(board) }
        
        let color: PieceColor = isMaximizing ? .black : .white
        let moves = getLegalMoves(for: board, color: color)
        
        if moves.isEmpty {
            return isMaximizing ? (-100000 + (aiDepth - depth)) : (100000 - (aiDepth - depth))
        }
        
        var currentAlpha = alpha
        var currentBeta = beta
        
        if isMaximizing {
            var maxEval = Int.min
            for move in moves {
                let nextBoard = applyMoveToBoard(board, move: move)
                let eval = minimax(board: nextBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, isMaximizing: false)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                if currentBeta <= currentAlpha { break }
            }
            return maxEval
        } else {
            var minEval = Int.max
            for move in moves {
                let nextBoard = applyMoveToBoard(board, move: move)
                let eval = minimax(board: nextBoard, depth: depth - 1, alpha: currentAlpha, beta: currentBeta, isMaximizing: true)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                if currentBeta <= currentAlpha { break }
            }
            return minEval
        }
    }
    
    private func applyMoveToBoard(_ currentBoard: Board, move: Move) -> Board {
        var newBoard = currentBoard
        for capture in move.captures {
            newBoard[capture.row][capture.col] = nil
        }
        if let piece = newBoard[move.from.row][move.from.col] {
            newBoard[move.to.row][move.to.col] = piece
            newBoard[move.from.row][move.from.col] = nil
            if move.becomesKing {
                newBoard[move.to.row][move.to.col]?.isKing = true
            }
        }
        return newBoard
    }
    
    private func evaluateBoard(_ board: Board) -> Int {
        var score = 0
        var whitePieces: [Position] = []
        var blackPieces: [Position] = []

        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board[row][col] else { continue }
                let pos = Position(row: row, col: col)
                
                let value = piece.isKing ? 500 : 100
                let sideMult = (piece.color == .black ? 1 : -1)
                score += value * sideMult
                
                if piece.color == .black { blackPieces.append(pos) }
                else { whitePieces.append(pos) }
            }
        }

        if whitePieces.count <= 2 && !blackPieces.isEmpty {
            for bPos in blackPieces {
                for wPos in whitePieces {
                    let dist = abs(bPos.row - wPos.row) + abs(bPos.col - wPos.col)
                    score += (14 - dist) * 5
                }
            }
        }
        return score
    }
    
    // MARK: - Helpers & Animation
    private func animateMove(_ move: Move, completion: @escaping () -> Void) {
        let fromCell = cellViews[move.from.row][move.from.col]
        let toCell = cellViews[move.to.row][move.to.col]
        
        guard let pieceView = fromCell.subviews.first(where: { $0.layer.cornerRadius > 5 }) else {
            completion()
            return
        }
        
        let tempPiece = UIView()
        tempPiece.backgroundColor = pieceView.backgroundColor
        tempPiece.layer.cornerRadius = pieceView.layer.cornerRadius
        tempPiece.layer.shadowColor = pieceView.layer.shadowColor
        tempPiece.layer.shadowOffset = pieceView.layer.shadowOffset
        tempPiece.layer.shadowRadius = pieceView.layer.shadowRadius
        tempPiece.layer.shadowOpacity = pieceView.layer.shadowOpacity
        
        if let existingCrown = pieceView.subviews.first(where: { ($0 as? UILabel)?.text == "👑" }) as? UILabel {
            let crown = UILabel()
            crown.text = "👑"
            crown.font = existingCrown.font
            crown.textAlignment = .center
            tempPiece.addSubview(crown)
            crown.snp.makeConstraints { $0.center.equalToSuperview() }
        }
        
        boardContainer.addSubview(tempPiece)
        let initialFrame = boardContainer.convert(pieceView.frame, from: fromCell)
        tempPiece.frame = initialFrame
        pieceView.alpha = 0
        
        let targetCenter = boardContainer.convert(toCell.center, from: boardContainer)
        let targetFrame = CGRect(
            x: targetCenter.x - initialFrame.width / 2,
            y: targetCenter.y - initialFrame.height / 2,
            width: initialFrame.width,
            height: initialFrame.height
        )
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            tempPiece.frame = targetFrame
        } completion: { _ in
            tempPiece.removeFromSuperview()
            completion()
        }
    }
    
    private func isValid(_ row: Int, _ col: Int) -> Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
    
    private func willBecomeKing(at pos: Position, color: PieceColor, isKing: Bool) -> Bool {
        if isKing { return true }
        return (color == .white && pos.row == 0) || (color == .black && pos.row == 7)
    }

    private func checkWinCondition() -> Bool {
        let whitePieces = board.flatMap { $0 }.compactMap { $0 }.filter { $0.color == .white }
        let blackPieces = board.flatMap { $0 }.compactMap { $0 }.filter { $0.color == .black }
        
        if whitePieces.isEmpty { clearGameState(); handleAIWin(); return true }
        if blackPieces.isEmpty { clearGameState(); handleUserWin(); return true }
        
        let currentTurnColor: PieceColor = isUserTurn ? .white : .black
        let availableMoves = getLegalMoves(for: board, color: currentTurnColor)
        
        if availableMoves.isEmpty {
            clearGameState()
            if isUserTurn { handleAIWin() } else { handleUserWin() }
            return true
        }
        
        if consecutiveNonCaptures >= 40 {
            clearGameState()
            setWaifuMessage("mini.game.aigf.texts27".localize())
            showGameOverAlert(title: "Draw", message: "mini.game.aigf.texts27".localize())
            return true
        }
        
        return false
    }
    
    private func handleUserWin() {
        updateScore(waifu: waifuScore, user: userScore + 1)
        updateDifficultyBasedOnScore()
        setWaifuMessage("mini.game.aigf.texts28".localize())
        showGameOverAlert(title: "mini.game.aigf.texts29".localize(), message: "mini.game.aigf.texts30".localize())
    }

    private func handleAIWin() {
        updateScore(waifu: waifuScore + 1, user: userScore)
        setWaifuMessage("mini.game.aigf.texts31".localize())
        showGameOverAlert(title: "mini.game.aigf.texts32".localize(), message: "mini.game.aigf.texts33".localize())
    }
    
    private func handleAILoss() {
        updateScore(waifu: waifuScore + 1, user: userScore)
        setWaifuMessage("mini.game.aigf.texts36".localize())
        showGameOverAlert(title: "mini.game.aigf.texts29".localize(), message: "mini.game.aigf.texts37".localize())
    }

    private func resetGame() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        selectedPosition = nil
        validMoves = []
        mustContinueCapture = false
        consecutiveNonCaptures = 0
        userStartsNextGame.toggle()
        isUserTurn = userStartsNextGame
        setupInitialBoardState()
        updateAllCells()
        
        clearGameState() // Чистим старый сейв, так как пошел новый раунд
        
        setWaifuMessage(isUserTurn ? "mini.game.aigf.texts34".localize() : "mini.game.aigf.texts35".localize())
        if !isUserTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.aiTurn()
            }
        }
    }
    
    private func showGameOverAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mini.game.aigf.texts38".localize(), style: .default) { [weak self] _ in
            self?.resetGame()
        })
        present(alert, animated: true)
    }
    
    // MARK: - State Persistence Serialization
    
    private func saveGameState() {
        var stringRows: [String] = []
        for row in 0..<8 {
            var rowItems: [String] = []
            for col in 0..<8 {
                if let piece = board[row][col] {
                    let typeStr = piece.color.rawValue // "white" или "black"
                    let kingStr = piece.isKing ? "_king" : ""
                    rowItems.append("\(typeStr)\(kingStr)")
                } else {
                    rowItems.append("empty")
                }
            }
            stringRows.append(rowItems.joined(separator: ","))
        }
        
        let boardStringRepresentation = stringRows.joined(separator: "|")
        UserDefaults.standard.set(boardStringRepresentation, forKey: checkersBoardKey)
        UserDefaults.standard.set(isUserTurn, forKey: checkersTurnKey)
    }
    
    private func loadGameState() -> Bool {
        guard let savedStr = UserDefaults.standard.string(forKey: checkersBoardKey) else { return false }
        
        let rows = savedStr.components(separatedBy: "|")
        guard rows.count == 8 else { return false }
        
        var loadedBoard: Board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        
        for (rowIndex, rowStr) in rows.enumerated() {
            let items = rowStr.components(separatedBy: ",")
            guard items.count == 8 else { return false }
            
            for (colIndex, item) in items.enumerated() {
                if item == "empty" {
                    loadedBoard[rowIndex][colIndex] = nil
                } else if item.hasPrefix("white") {
                    let isKing = item.contains("_king")
                    loadedBoard[rowIndex][colIndex] = Piece(color: .white, isKing: isKing)
                } else if item.hasPrefix("black") {
                    let isKing = item.contains("_king")
                    loadedBoard[rowIndex][colIndex] = Piece(color: .black, isKing: isKing)
                }
            }
        }
        
        self.board = loadedBoard
        self.isUserTurn = UserDefaults.standard.bool(forKey: checkersTurnKey)
        return true
    }
    
    private func clearGameState() {
        UserDefaults.standard.removeObject(forKey: checkersBoardKey)
        UserDefaults.standard.removeObject(forKey: checkersTurnKey)
    }
}
