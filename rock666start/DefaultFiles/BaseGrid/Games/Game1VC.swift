import UIKit
import SnapKit

final class Game1VC: UIViewController {

    // MARK: - Constants & Difficulty
    private var aiDepth: Int = 2 // Начинаем со среднего уровня по умолчанию

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
    
    // MARK: - UI Components
    private lazy var customNavBar: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.background
        return view
    }()
    
    private lazy var navSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.separator
        return view
    }()
    
    private lazy var backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.backward", withConfiguration: config), for: .normal)
        btn.tintColor = BasePalitColors.textPrimary
        btn.backgroundColor = BasePalitColors.cardBackground
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(dismissGame), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Checkers"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = BasePalitColors.textPrimary
        label.textAlignment = .center
        return label
    }()
    
    // Кнопка переключения сложности AI
    private lazy var difficultyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("AI: Medium", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        btn.setTitleColor(BasePalitColors.primary, for: .normal)
        btn.backgroundColor = BasePalitColors.cardBackground
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 1
        btn.layer.borderColor = BasePalitColors.separator.cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        btn.addTarget(self, action: #selector(changeDifficultyTapped), for: .touchUpInside)
        return btn
    }()
    
    private var boardContainer: UIView!
    private var cellSize: CGFloat = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BasePalitColors.background
        
        setupNavigationBar()
        setupInitialBoardState()
        isUserTurn = true
        renderBoard()
    }
    
    // MARK: - UI Setup
    private func setupNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.addSubview(navSeparator)
        customNavBar.addSubview(backButton)
        customNavBar.addSubview(titleLabel)
        customNavBar.addSubview(difficultyButton)
        
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        difficultyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
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
    
    // MARK: - Board Rendering
    private func renderBoard() {
        boardContainer?.removeFromSuperview()
        
        boardContainer = UIView()
        boardContainer.backgroundColor = BasePalitColors.cardBackground
        boardContainer.layer.cornerRadius = 20
        boardContainer.layer.borderWidth = 2
        boardContainer.layer.borderColor = BasePalitColors.primary.withAlphaComponent(0.6).cgColor
        boardContainer.layer.shadowColor = BasePalitColors.pureBlack.cgColor
        boardContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        boardContainer.layer.shadowRadius = 16
        boardContainer.layer.shadowOpacity = 0.3
        boardContainer.clipsToBounds = true
        
        view.addSubview(boardContainer)
        let boardSize = min(view.frame.width - 32, 380)
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
        cell.backgroundColor = isDark ? BasePalitColors.tile2 : BasePalitColors.cardBackground.withAlphaComponent(0.3)
        
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
        
        // Подсветка доступных ходов
        if let selected = selectedPosition {
            let isValidDest = validMoves.contains { $0.from == selected && $0.to == pos }
            if isValidDest {
                let highlightDot = UIView()
                highlightDot.backgroundColor = BasePalitColors.gold
                highlightDot.layer.cornerRadius = (cellSize * 0.28) / 2
                cell.addSubview(highlightDot)
                highlightDot.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(cellSize * 0.28)
                }
            }
        }
        
        guard let piece = board[pos.row][pos.col] else { return }
        
        let pieceView = UIView()
        let pieceSize = cellSize * 0.76
        pieceView.layer.cornerRadius = pieceSize / 2
        
        if piece.color == .white {
            pieceView.backgroundColor = BasePalitColors.pureWhite
            pieceView.layer.borderWidth = 3
            pieceView.layer.borderColor = BasePalitColors.separator.cgColor
        } else {
            pieceView.backgroundColor = BasePalitColors.primary
            pieceView.layer.borderWidth = 2
            pieceView.layer.borderColor = BasePalitColors.gold.withAlphaComponent(0.6).cgColor
        }
        
        if let selected = selectedPosition, selected == pos {
            pieceView.layer.borderWidth = 3.5
            pieceView.layer.borderColor = BasePalitColors.gold.cgColor
            pieceView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }
        
        cell.addSubview(pieceView)
        pieceView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(pieceSize)
        }
        
        if piece.isKing {
            let crown = UILabel()
            crown.text = "👑"
            crown.font = .systemFont(ofSize: cellSize * 0.38)
            crown.textAlignment = .center
            pieceView.addSubview(crown)
            crown.snp.makeConstraints { $0.center.equalToSuperview() }
        }
    }
    
    // MARK: - User Interaction & Game Logic
    @objc private func handleCellTap(_ sender: UITapGestureRecognizer) {
        guard isUserTurn, let cell = sender.view else { return }
        let row = cell.tag / 10
        let col = cell.tag % 10
        let tappedPos = Position(row: row, col: col)
        
        if let selected = selectedPosition {
            if let move = validMoves.first(where: { $0.from == selected && $0.to == tappedPos }) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                executeUserMove(move)
                return
            }
        }
        
        if mustContinueCapture { return }
        
        let allLegalMoves = getLegalMoves(for: board, color: .white)
        let mandatoryCaptureMoves = allLegalMoves.filter { !$0.captures.isEmpty }
        
        if !mandatoryCaptureMoves.isEmpty {
            let validCapPositions = Set(mandatoryCaptureMoves.map { $0.from })
            if validCapPositions.contains(tappedPos) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedPosition = tappedPos
                calculateUserMoves()
                updateAllCells()
            }
            return
        }
        
        if board[row][col]?.color == .white {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedPosition = tappedPos
            calculateUserMoves()
            updateAllCells()
        } else {
            selectedPosition = nil
            validMoves = []
            updateAllCells()
        }
    }
    
    private func calculateUserMoves() {
        validMoves = []
        guard let selected = selectedPosition else { return }
        validMoves = getLegalMoves(for: board, color: .white).filter { $0.from == selected }
    }
    
    private func getLegalMoves(for currentBoard: Board, color: PieceColor) -> [Move] {
        var captureMoves: [Move] = []
        var regularMoves: [Move] = []
        
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = currentBoard[row][col], piece.color == color else { continue }
                let pos = Position(row: row, col: col)
                captureMoves.append(contentsOf: getCaptureMoves(board: currentBoard, from: pos))
                if captureMoves.isEmpty {
                    regularMoves.append(contentsOf: getRegularMoves(board: currentBoard, from: pos))
                }
            }
        }
        return !captureMoves.isEmpty ? captureMoves : regularMoves
    }
    
    private func getRegularMoves(board: Board, from pos: Position) -> [Move] {
        guard let piece = board[pos.row][pos.col] else { return [] }
        var moves: [Move] = []
        let directions: [(Int, Int)] = piece.isKing ? [(-1, -1), (-1, 1), (1, -1), (1, 1)] : (piece.color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])
        
        for (dRow, dCol) in directions {
            let newRow = pos.row + dRow, newCol = pos.col + dCol
            if isValid(newRow, newCol), board[newRow][newCol] == nil {
                let newPos = Position(row: newRow, col: newCol)
                moves.append(Move(from: pos, to: newPos, captures: [], becomesKing: willBecomeKing(at: newPos, color: piece.color, isKing: piece.isKing)))
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
        let directions: [(Int, Int)] = isKing ? [(-1, -1), (-1, 1), (1, -1), (1, 1)] : (color == .white ? [(-1, -1), (-1, 1)] : [(1, -1), (1, 1)])
        
        for (dRow, dCol) in directions {
            let enemyRow = currentPos.row + dRow, enemyCol = currentPos.col + dCol
            let landRow = currentPos.row + dRow * 2, landCol = currentPos.col + dCol * 2
            let enemyPos = Position(row: enemyRow, col: enemyCol)
            
            if isValid(landRow, landCol), let enemyPiece = board[enemyRow][enemyCol], enemyPiece.color != color, board[landRow][landCol] == nil, !capturedSoFar.contains(enemyPos) {
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
        return moves
    }
    
    private func executeUserMove(_ move: Move) {
        animateMove(move) { [weak self] in
            guard let self = self else { return }
            self.finalizeMove(move)
            
            if !move.captures.isEmpty, !move.becomesKing, !self.getCaptureMoves(board: self.board, from: move.to).isEmpty {
                self.mustContinueCapture = true
                self.selectedPosition = move.to
                self.calculateUserMoves()
                self.updateAllCells()
                return
            }
            
            self.mustContinueCapture = false
            self.isUserTurn = false
            if self.checkWinCondition() { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.aiTurn()
            }
        }
    }
    
    private func finalizeMove(_ move: Move) {
        for capture in move.captures { board[capture.row][capture.col] = nil }
        let movingPiece = board[move.from.row][move.from.col]
        board[move.to.row][move.to.col] = movingPiece
        board[move.from.row][move.from.col] = nil
        if move.becomesKing { board[move.to.row][move.to.col]?.isKing = true }
        
        if move.captures.isEmpty { consecutiveNonCaptures += 1 } else { consecutiveNonCaptures = 0 }
        
        selectedPosition = nil
        validMoves = []
        updateAllCells()
    }
    
    // MARK: - AI Minimax Logic
    private func aiTurn() {
        guard !isUserTurn else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let bestMove = self.runMinimax()
            DispatchQueue.main.async {
                guard let move = bestMove else {
                    self.showGameOverAlert(title: "Victory!", message: "You have defeated the AI!")
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
            _ = self.checkWinCondition()
        }
    }
    
    private func runMinimax() -> Move? {
        let possibleMoves = getLegalMoves(for: board, color: .black)
        if possibleMoves.isEmpty { return nil }
        if possibleMoves.count == 1 { return possibleMoves.first }
        
        var bestMove: Move?
        var maxEval = Int.min
        
        for move in possibleMoves {
            let simulatedBoard = applyMoveToBoard(board, move: move)
            let eval = minimax(board: simulatedBoard, depth: aiDepth - 1, alpha: Int.min, beta: Int.max, isMaximizing: false)
            if eval > maxEval {
                maxEval = eval
                bestMove = move
            }
        }
        return bestMove ?? possibleMoves.first
    }
    
    private func minimax(board: Board, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        if depth == 0 { return evaluateBoard(board) }
        let color: PieceColor = isMaximizing ? .black : .white
        let moves = getLegalMoves(for: board, color: color)
        
        if moves.isEmpty {
            return isMaximizing ? -100000 : 100000
        }
        
        var currentAlpha = alpha, currentBeta = beta
        if isMaximizing {
            var maxEval = Int.min
            for move in moves {
                let eval = minimax(board: applyMoveToBoard(board, move: move), depth: depth - 1, alpha: currentAlpha, beta: currentBeta, isMaximizing: false)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                if currentBeta <= currentAlpha { break }
            }
            return maxEval
        } else {
            var minEval = Int.max
            for move in moves {
                let eval = minimax(board: applyMoveToBoard(board, move: move), depth: depth - 1, alpha: currentAlpha, beta: currentBeta, isMaximizing: true)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                if currentBeta <= currentAlpha { break }
            }
            return minEval
        }
    }
    
    private func applyMoveToBoard(_ currentBoard: Board, move: Move) -> Board {
        var newBoard = currentBoard
        for capture in move.captures { newBoard[capture.row][capture.col] = nil }
        if let piece = newBoard[move.from.row][move.from.col] {
            newBoard[move.to.row][move.to.col] = piece
            newBoard[move.from.row][move.from.col] = nil
            if move.becomesKing { newBoard[move.to.row][move.to.col]?.isKing = true }
        }
        return newBoard
    }
    
    private func evaluateBoard(_ board: Board) -> Int {
        var score = 0
        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = board[row][col] else { continue }
                let value = piece.isKing ? 500 : 100
                score += value * (piece.color == .black ? 1 : -1)
            }
        }
        return score
    }
    
    // MARK: - Animation & Helpers
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
        tempPiece.layer.borderWidth = pieceView.layer.borderWidth
        tempPiece.layer.borderColor = pieceView.layer.borderColor
        
        boardContainer.addSubview(tempPiece)
        let initialFrame = boardContainer.convert(pieceView.frame, from: fromCell)
        tempPiece.frame = initialFrame
        pieceView.alpha = 0
        
        let targetCenter = boardContainer.convert(toCell.center, from: boardContainer)
        let targetFrame = CGRect(x: targetCenter.x - initialFrame.width / 2, y: targetCenter.y - initialFrame.height / 2, width: initialFrame.width, height: initialFrame.height)
        
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            tempPiece.frame = targetFrame
        } completion: { _ in
            tempPiece.removeFromSuperview()
            completion()
        }
    }
    
    private func isValid(_ row: Int, _ col: Int) -> Bool { row >= 0 && row < 8 && col >= 0 && col < 8 }
    
    private func willBecomeKing(at pos: Position, color: PieceColor, isKing: Bool) -> Bool {
        if isKing { return true }
        return (color == .white && pos.row == 0) || (color == .black && pos.row == 7)
    }
    
    private func checkWinCondition() -> Bool {
        let whitePieces = board.flatMap { $0 }.compactMap { $0 }.filter { $0.color == .white }
        let blackPieces = board.flatMap { $0 }.compactMap { $0 }.filter { $0.color == .black }
        
        if whitePieces.isEmpty { showGameOverAlert(title: "Game Over", message: "AI wins the match!"); return true }
        if blackPieces.isEmpty { showGameOverAlert(title: "Victory!", message: "You won the match!"); return true }
        
        if getLegalMoves(for: board, color: isUserTurn ? .white : .black).isEmpty {
            showGameOverAlert(title: "Game Over", message: isUserTurn ? "No moves left. AI wins!" : "No moves left. You win!")
            return true
        }
        return false
    }
    
    private func resetGame() {
        userStartsNextGame.toggle()
        isUserTurn = userStartsNextGame
        setupInitialBoardState()
        selectedPosition = nil
        validMoves = []
        mustContinueCapture = false
        consecutiveNonCaptures = 0
        updateAllCells()
        
        if !isUserTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.aiTurn() }
        }
    }
    
    // MARK: - Actions & Alerts
    @objc private func changeDifficultyTapped() {
        let alert = UIAlertController(title: "Select AI Difficulty", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Easy", style: .default) { [weak self] _ in
            self?.aiDepth = 1
            self?.difficultyButton.setTitle("AI: Easy", for: .normal)
        })
        alert.addAction(UIAlertAction(title: "Medium", style: .default) { [weak self] _ in
            self?.aiDepth = 2
            self?.difficultyButton.setTitle("AI: Medium", for: .normal)
        })
        alert.addAction(UIAlertAction(title: "Hard", style: .default) { [weak self] _ in
            self?.aiDepth = 4
            self?.difficultyButton.setTitle("AI: Hard", for: .normal)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func dismissGame() {
        dismiss(animated: true)
    }
    
    private func showGameOverAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: .default) { [weak self] _ in
            self?.resetGame()
        })

        // Аккуратный вызов без лишних аргументов:
         present(alert, animated: true)
    }
}
