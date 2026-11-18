import UIKit
import SnapKit

final class Game2VC: UIViewController {
    
    // MARK: - Settings & Difficulty
    private var gridSize: Int = 4 {
        didSet {
            resetBoard()
        }
    }
    private let targetValue = 2048
    
    // MARK: - Game State
    private var board: [[Int]] = []
    private var tileViews: [UUID: TileView] = [:]
    private var tileIds: [[UUID?]] = []
    private var isGameOver = false
    private let spacing: CGFloat = 8
    private var cellSize: CGFloat = 0
    
    private var gameSaveKey: String { "Game2VC_grid_\(gridSize)_progress" }
    private var boardSaveKey: String { "Game2VC_grid_\(gridSize)_board_state" }
    
    // MARK: - UI Elements
    private let customNavBar = UIView()
    private let backButton = UIButton(type: .system)
    private let scoreContainer = UIView()
    private let scoreTitleLabel = UILabel()
    private let scoreValueLabel = UILabel()
    
    private let difficultyButton = UIButton(type: .system)
    private let gridContainer = UIView()
    private var overlayView: UIView?
    
    // Haptics
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let successFeedback = UINotificationFeedbackGenerator()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        addSwipeGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFieldLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadProgress()
        
        if !loadSavedBoard() {
            resetBoard()
        }
        
    }
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        // 1. Navigation Bar
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = BasePalitColors.background
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Back Button
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.backward", withConfiguration: backConfig), for: .normal)
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
        
        // Difficulty Picker Button
        difficultyButton.setTitle("\(gridSize)x\(gridSize)", for: .normal)
        difficultyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        difficultyButton.tintColor = BasePalitColors.primary
        difficultyButton.backgroundColor = BasePalitColors.cardBackground
        difficultyButton.layer.cornerRadius = 20
        difficultyButton.addTarget(self, action: #selector(showDifficultyPicker), for: .touchUpInside)
        customNavBar.addSubview(difficultyButton)
        difficultyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
            make.width.equalTo(64)
        }
        
        // Score View
        scoreContainer.backgroundColor = BasePalitColors.cardBackground
        scoreContainer.layer.cornerRadius = 16
        scoreContainer.layer.borderWidth = 1
        scoreContainer.layer.borderColor = BasePalitColors.separator.cgColor
        customNavBar.addSubview(scoreContainer)
        scoreContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(40)
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(difficultyButton.snp.leading).offset(-12)
            make.width.greaterThanOrEqualTo(110)
        }
        
        scoreTitleLabel.text = "SCORE"
        scoreTitleLabel.font = .systemFont(ofSize: 10, weight: .bold)
        scoreTitleLabel.textColor = BasePalitColors.textSecondary
        scoreTitleLabel.textAlignment = .center
        
        scoreValueLabel.text = "0"
        scoreValueLabel.font = .systemFont(ofSize: 16, weight: .black)
        scoreValueLabel.textColor = BasePalitColors.textPrimary
        scoreValueLabel.textAlignment = .center
        
        let scoreStack = UIStackView(arrangedSubviews: [scoreTitleLabel, scoreValueLabel])
        scoreStack.axis = .vertical
        scoreStack.alignment = .center
        scoreStack.spacing = 0
        scoreContainer.addSubview(scoreStack)
        scoreStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12))
        }
        
        // 2. Game Grid Container
        gridContainer.backgroundColor = BasePalitColors.bubbleBackground
        gridContainer.layer.cornerRadius = 24
        gridContainer.layer.borderWidth = 2
        gridContainer.layer.borderColor = BasePalitColors.separator.cgColor
        gridContainer.layer.shadowColor = BasePalitColors.pureBlack.cgColor
        gridContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        gridContainer.layer.shadowOpacity = 0.3
        gridContainer.layer.shadowRadius = 12
        view.addSubview(gridContainer)
        
        gridContainer.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(min(UIScreen.main.bounds.width - 32, 360))
        }
    }

    private func updateFieldLayout() {
        let fieldSize = gridContainer.frame.width
        guard fieldSize > 0 else { return }
        cellSize = (fieldSize - (CGFloat(gridSize + 1) * spacing)) / CGFloat(gridSize)
    }

    private func rebuildGridBackground() {
        gridContainer.subviews.forEach { $0.removeFromSuperview() }
        updateFieldLayout()
        
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let bg = UIView()
                bg.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.6)
                bg.layer.cornerRadius = 10
                gridContainer.addSubview(bg)
                bg.frame = frameForCell(atRow: r, col: c)
            }
        }
    }

    private func frameForCell(atRow row: Int, col: Int) -> CGRect {
        let x = spacing + CGFloat(col) * (cellSize + spacing)
        let y = spacing + CGFloat(row) * (cellSize + spacing)
        return CGRect(x: x, y: y, width: cellSize, height: cellSize)
    }

    // MARK: - Game Logic
    private var currentScore = 0 {
        didSet {
            scoreValueLabel.text = "\(currentScore)"
            saveProgress()
        }
    }

    private func resetBoard() {
        removeOverlay()
        clearSavedBoard()
        
        board = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        tileIds = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        tileViews.values.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        
        currentScore = 0
        isGameOver = false
        
        rebuildGridBackground()
        addRandomTile()
        addRandomTile()
        saveBoardState()
    }

    private func addRandomTile() {
        var emptyCells: [(Int, Int)] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if board[r][c] == 0 { emptyCells.append((r, c)) }
            }
        }
        
        if let randomCell = emptyCells.randomElement() {
            let value = Double.random(in: 0...1) < 0.9 ? 2 : 4
            let r = randomCell.0, c = randomCell.1
            let id = UUID()
            
            board[r][c] = value
            tileIds[r][c] = id
            
            let tile = TileView(frame: frameForCell(atRow: r, col: c), value: value)
            tile.backgroundColor = getTileColor(value)
            gridContainer.addSubview(tile)
            tileViews[id] = tile
            tile.appearanceAnim()
        }
    }

    private func renderBoard() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            for r in 0..<self.gridSize {
                for c in 0..<self.gridSize {
                    if let id = self.tileIds[r][c], let tile = self.tileViews[id] {
                        tile.frame = self.frameForCell(atRow: r, col: c)
                        tile.update(value: self.board[r][c], color: self.getTileColor(self.board[r][c]))
                    }
                }
            }
        }
    }

    private func getTileColor(_ value: Int) -> UIColor {
        switch value {
        case 0: return BasePalitColors.cardBackground
        case 2: return BasePalitColors.tile2
        case 4: return BasePalitColors.tile4
        case 8, 16: return BasePalitColors.link
        case 32, 64: return BasePalitColors.primary
        case 128, 256: return BasePalitColors.gold
        case 512, 1024: return BasePalitColors.accentRed
        case 2048: return BasePalitColors.avatarBackground
        default: return BasePalitColors.pureBlack
        }
    }

    private func addSwipeGestures() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right, .up, .down]
        for direction in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = direction
            view.addGestureRecognizer(swipe)
        }
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !isGameOver else { return }
        let oldBoard = board
        
        let range = Array(0..<gridSize)
        let reversed = Array((0..<gridSize).reversed())

        switch gesture.direction {
        case .left:  move(rows: range, cols: range, dr: 0, dc: -1)
        case .right: move(rows: range, cols: reversed, dr: 0, dc: 1)
        case .up:    move(rows: range, cols: range, dr: -1, dc: 0)
        case .down:  move(rows: reversed, cols: range, dr: 1, dc: 0)
        default: break
        }
        
        if board != oldBoard {
            impactFeedback.impactOccurred()
            renderBoard()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.addRandomTile()
                self.saveBoardState()
                self.checkGameState()
            }
        }
    }

    private func move(rows: [Int], cols: [Int], dr: Int, dc: Int) {
        var hasMerged = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        for r in rows {
            for c in cols {
                if board[r][c] == 0 { continue }
                var currR = r, currC = c
                while true {
                    let nextR = currR + dr, nextC = currC + dc
                    if nextR < 0 || nextR >= gridSize || nextC < 0 || nextC >= gridSize { break }
                    
                    if board[nextR][nextC] == 0 {
                        board[nextR][nextC] = board[currR][currC]
                        board[currR][currC] = 0
                        tileIds[nextR][nextC] = tileIds[currR][currC]
                        tileIds[currR][currC] = nil
                        currR = nextR; currC = nextC
                    } else if board[nextR][nextC] == board[currR][currC] && !hasMerged[nextR][nextC] {
                        let newValue = board[nextR][nextC] * 2
                        board[nextR][nextC] = newValue
                        board[currR][currC] = 0
                        
                        currentScore += newValue
                        
                        if let oldId = tileIds[currR][currC] {
                            tileViews[oldId]?.removeFromSuperview()
                            tileViews.removeValue(forKey: oldId)
                        }
                        tileIds[currR][currC] = nil
                        hasMerged[nextR][nextC] = true
                        
                        if newValue >= 128 {
                            successFeedback.notificationOccurred(.success)
                        }
                        break
                    } else { break }
                }
            }
        }
    }

    private func checkGameState() {
        if !canMove() {
            isGameOver = true
            clearSavedBoard()
            showGameOverOverlay(title: "Game Over")
        }
    }

    private func canMove() -> Bool {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if board[r][c] == 0 { return true }
                if c < gridSize - 1 && board[r][c] == board[r][c+1] { return true }
                if r < gridSize - 1 && board[r][c] == board[r+1][c] { return true }
            }
        }
        return false
    }

    // MARK: - Overlays & Actions
    private func showGameOverOverlay(title: String) {
        removeOverlay()
        
        let overlay = UIView()
        overlay.backgroundColor = BasePalitColors.pureBlack.withAlphaComponent(0.75)
        overlay.layer.cornerRadius = 24
        overlay.alpha = 0
        gridContainer.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = BasePalitColors.pureWhite
        label.textAlignment = .center
        
        let btn = UIButton(type: .system)
        btn.setTitle("Try Again", for: .normal)
        btn.backgroundColor = BasePalitColors.primary
        btn.tintColor = BasePalitColors.pureWhite
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.layer.cornerRadius = 20
        btn.addTarget(self, action: #selector(restartGame), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [label, btn])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        overlay.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        btn.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
        
        self.overlayView = overlay
        UIView.animate(withDuration: 0.3) { overlay.alpha = 1.0 }
    }

    private func removeOverlay() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }

    @objc private func restartGame() {
        resetBoard()
    }
    
    @objc private func dismissGame() {
        dismiss(animated: true)
    }

    @objc private func showDifficultyPicker() {
        let alert = UIAlertController(title: "Select Difficulty", message: "Choose grid size", preferredStyle: .actionSheet)
        
        let sizes = [3, 4, 5, 6]
        for size in sizes {
            alert.addAction(UIAlertAction(title: "\(size)x\(size) \(size == 3 ? "(Easy)" : size == 4 ? "(Normal)" : size == 5 ? "(Hard)" : "(Extreme)")", style: .default, handler: { [weak self] _ in
                self?.gridSize = size
                self?.difficultyButton.setTitle("\(size)x\(size)", for: .normal)
                self?.rebuildGridBackground()
                self?.resetBoard()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Persistence
    private func saveBoardState() {
        UserDefaults.standard.set(board, forKey: boardSaveKey)
    }
    
    private func clearSavedBoard() {
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(currentScore, forKey: gameSaveKey)
    }
    
    private func loadProgress() {
        currentScore = UserDefaults.standard.integer(forKey: gameSaveKey)
    }
    
    private func loadSavedBoard() -> Bool {
        rebuildGridBackground()
        guard let savedBoard = UserDefaults.standard.array(forKey: boardSaveKey) as? [[Int]],
              savedBoard.count == gridSize else {
            return false
        }
        
        tileViews.values.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        
        self.board = savedBoard
        self.tileIds = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        var hasTiles = false
        
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let value = board[r][c]
                if value > 0 {
                    let id = UUID()
                    tileIds[r][c] = id
                    
                    let tile = TileView(frame: frameForCell(atRow: r, col: c), value: value)
                    tile.backgroundColor = getTileColor(value)
                    gridContainer.addSubview(tile)
                    tileViews[id] = tile
                    hasTiles = true
                }
            }
        }
        
        if !canMove() {
            isGameOver = true
            showGameOverOverlay(title: "Game Over")
        }
        
        return hasTiles
    }
}

// MARK: - TileView
private class TileView: UIView {
    private let label = UILabel()
    private var lastValue: Int = 0

    init(frame: CGRect, value: Int) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.shadowColor = BasePalitColors.pureBlack.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22, weight: .black)
        label.textColor = BasePalitColors.pureWhite
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
        update(value: value, color: BasePalitColors.cardBackground)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    func update(value: Int, color: UIColor) {
        label.text = "\(value)"
        backgroundColor = color
        
        if value >= 1000 {
            label.font = .systemFont(ofSize: 16, weight: .black)
        } else if value >= 100 {
            label.font = .systemFont(ofSize: 18, weight: .black)
        } else {
            label.font = .systemFont(ofSize: 22, weight: .black)
        }
        
        if value > lastValue && lastValue != 0 { mergeAnim() }
        lastValue = value
    }

    func appearanceAnim() {
        self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            self.transform = .identity
        })
    }

    private func mergeAnim() {
        UIView.animate(withDuration: 0.08, animations: {
            self.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        }) { _ in
            UIView.animate(withDuration: 0.08) { self.transform = .identity }
        }
    }
}
