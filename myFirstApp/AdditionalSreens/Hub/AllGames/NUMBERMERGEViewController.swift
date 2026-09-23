import UIKit
import SnapKit

class NUMBERMERGEViewController: MiniGameAbstractVC {
    
    private let gridSize = 4
    private var board: [[Int]] = []
    private var tileViews: [UUID: TileView] = [:]
    private var tileIds: [[UUID?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    
    private let targetValue = 2048
    private var isGameOver = false
    private let spacing: CGFloat = 10
    private var cellSize: CGFloat = 0
    
    // UI Elements
    private let gridContainer = UIView()
    private let topHeaderView = UIView()
    private let maxTileLabel = UILabel()
    private let maxTileValueLabel = UILabel()
    private var overlayView: UIView?
    
    // Haptics
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let successFeedback = UINotificationFeedbackGenerator()

    override var gameRules: String {
        "NUMBERMERGE.INSTRUCTIONS".localize()
    }

    override func didResetProgress() {
        clearSavedBoard()
        resetBoard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeaderUI()
        setupGameField()
        loadProgress()
        
        if !loadSavedBoard() {
            resetBoard()
        }
        
        addSwipeGestures()
    }

    override func updateScore(waifu: Int, user: Int) {
        super.updateScore(waifu: waifu, user: user)

        let imageName: String
        switch userScore {
        case 0: imageName = "AvatarForGeme1"
        case 1: imageName = "AvatarForGeme2"
        case 2: imageName = "AvatarForGeme3"
        case 3: imageName = "AvatarForGeme4"
        case 4: imageName = "AvatarForGeme5"
        case 5: imageName = "AvatarForGeme6"
        case 6: imageName = "AvatarForGeme7"
        case 7...:
            let suffix = (userScore % 2 == 0) ? "7" : "8"
            imageName = "AvatarForGeme\(suffix)"
        default:
            imageName = "AvatarForGeme8"
        }
        
        UIView.animate(withDuration: 1) {
            self.waifuImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: imageName)
        }
    }
    
    // MARK: - UI Setup
    private func setupHeaderUI() {
        topHeaderView.backgroundColor = MyColors.cardBackground
        topHeaderView.layer.cornerRadius = 16
        topHeaderView.layer.borderWidth = 1.5
        topHeaderView.layer.borderColor = MyColors.separator.cgColor
        gameContainerView.addSubview(topHeaderView)
        
        maxTileLabel.text = "NumberMerge.MaxTile".localize().uppercased()
        maxTileLabel.font = .systemFont(ofSize: 11, weight: .bold)
        maxTileLabel.textColor = MyColors.textSecondary
        
        maxTileValueLabel.text = "2"
        maxTileValueLabel.font = .systemFont(ofSize: 22, weight: .black)
        maxTileValueLabel.textColor = MyColors.gold
        
        let headerStack = UIStackView(arrangedSubviews: [maxTileLabel, maxTileValueLabel])
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 2
        topHeaderView.addSubview(headerStack)
        
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        topHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(140)
        }
    }
    
    private func setupGameField() {
        let fieldSize = min(view.frame.width - 32, 330)
        cellSize = (fieldSize - (CGFloat(gridSize + 1) * spacing)) / CGFloat(gridSize)
        
        gridContainer.backgroundColor = MyColors.bubbleBackground
        gridContainer.layer.cornerRadius = 24
        gridContainer.layer.borderWidth = 2
        gridContainer.layer.borderColor = MyColors.separator.cgColor
        gridContainer.layer.shadowColor = MyColors.pureBlack.cgColor
        gridContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        gridContainer.layer.shadowOpacity = 0.3
        gridContainer.layer.shadowRadius = 12
        gameContainerView.addSubview(gridContainer)
        
        gridContainer.snp.makeConstraints { make in
            make.top.equalTo(topHeaderView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(fieldSize)
        }
        
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let bg = UIView()
                bg.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.6)
                bg.layer.cornerRadius = 12
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

    private func resetBoard() {
        removeOverlay()
        clearSavedBoard()
        board = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        tileIds = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        tileViews.values.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        
        isGameOver = false
        addRandomTile()
        addRandomTile()
        updateMaxTileLabel()
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
        case 0: return MyColors.cardBackground
        case 2: return MyColors.tile2
        case 4: return MyColors.tile4
        case 8, 16: return MyColors.link
        case 32, 64: return MyColors.primary
        case 128, 256: return MyColors.gold
        case 512, 1024: return MyColors.accentRed
        case 2048: return MyColors.avatarBackground
        default: return MyColors.pureBlack
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
                self.updateMaxTileLabel()
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
                        if let oldId = tileIds[currR][currC] {
                            tileViews[oldId]?.removeFromSuperview()
                            tileViews.removeValue(forKey: oldId)
                        }
                        tileIds[currR][currC] = nil
                        hasMerged[nextR][nextC] = true
                        
                        if newValue >= 128 {
                            successFeedback.notificationOccurred(.success)
                            setWaifuMessage("Wow! \(newValue)? " + "mini.game.aigf.texts9".localize())
                        }
                        break
                    } else { break }
                }
            }
        }
    }

    private func updateMaxTileLabel() {
        let maxVal = board.flatMap { $0 }.max() ?? 2
        maxTileValueLabel.text = "\(maxVal)"
    }

    private func checkGameState() {
        if board.flatMap({ $0 }).contains(targetValue) {
            userScore += 1
            updateScore(waifu: waifuScore, user: userScore)
            setWaifuMessage("mini.game.aigf.texts10".localize())
            isGameOver = true
            clearSavedBoard()
            showGameOverOverlay(title: "NumberMerge.Victory".localize())
            return
        }
        
        if !canMove() {
            waifuScore += 1
            updateScore(waifu: waifuScore, user: userScore)
            setWaifuMessage("mini.game.aigf.texts11".localize())
            isGameOver = true
            clearSavedBoard()
            showGameOverOverlay(title: "NumberMerge.GameOver".localize())
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

    // MARK: - Game Over Overlay
    private func showGameOverOverlay(title: String) {
        removeOverlay()
        
        let overlay = UIView()
        overlay.backgroundColor = MyColors.pureBlack.withAlphaComponent(0.7)
        overlay.layer.cornerRadius = 24
        overlay.alpha = 0
        gridContainer.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = MyColors.pureWhite
        label.textAlignment = .center
        
        let btn = UIButton(type: .system)
        btn.setTitle("NumberMerge.TryAgain".localize(), for: .normal)
        btn.backgroundColor = MyColors.primary
        btn.tintColor = MyColors.pureWhite
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = MyColors.primary.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowOpacity = 0.4
        btn.layer.shadowRadius = 8
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
        
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1.0
        }
    }

    private func removeOverlay() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }

    @objc private func restartGame() {
        resetBoard()
        setWaifuMessage("mini.game.aigf.texts13".localize())
    }
    
    // MARK: - Local Save Logic
    private func saveBoardState() {
        UserDefaults.standard.set(board, forKey: boardSaveKey)
    }
    
    private func clearSavedBoard() {
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
    }
    
    private func loadSavedBoard() -> Bool {
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
        
        updateMaxTileLabel()
        
        if !canMove() || board.flatMap({ $0 }).contains(targetValue) {
            isGameOver = true
            showGameOverOverlay(title: !canMove() ? "NumberMerge.GameOver".localize() : "NumberMerge.Victory".localize())
        }
        
        return hasTiles
    }
}

// MARK: - TileView
class TileView: UIView {
    private let label = UILabel()
    private var lastValue: Int = 0

    init(frame: CGRect, value: Int) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        layer.shadowColor = MyColors.pureBlack.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4
        
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22, weight: .black)
        label.textColor = MyColors.pureWhite
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
        update(value: value, color: MyColors.cardBackground)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    func update(value: Int, color: UIColor) {
        label.text = "\(value)"
        backgroundColor = color
        
        // Масштабирование размера шрифта для трехзначных и четырехзначных чисел
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
