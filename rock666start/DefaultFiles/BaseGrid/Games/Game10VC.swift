import UIKit
import SnapKit

// MARK: - Word Search Engine & Models

private struct WordSearchCoord: Hashable {
    let row: Int
    let col: Int
}

private struct WordSearchPlacement {
    let word: String
    let coords: [WordSearchCoord]
}

private enum WordSearchGenerator {
    
    // Тематические слова для разных уровней
    static func words(for level: Int) -> [String] {
        let pool: [[String]] = [
            ["CAT", "DOG", "SUN", "SKY", "BOX"], // Уровень 1
            ["SWIFT", "APPLE", "HOUSE", "WATER", "GREEN", "MUSIC"], // Уровень 2
            ["COFFEE", "PLANET", "BRIDGE", "CLIENT", "MOBILE", "VECTOR"], // Уровень 3
            ["ENGINEER", "KEYBOARD", "NOTEBOOK", "TERMINAL", "SOFTWARE", "HARDWARE", "NETWORK"] // Уровень 4+
        ]
        let index = min(level - 1, pool.count - 1)
        return pool[max(0, index)]
    }

    static func gridDimension(for level: Int) -> Int {
        switch level {
        case 1: return 10
        case 2: return 12
        case 3: return 15
        default: return 20
        }
    }

    static func generateBoard(level: Int) -> (grid: [[Character]], placements: [WordSearchPlacement], size: Int) {
        let size = gridDimension(for: level)
        let targetWords = words(for: level)
        
        var grid = Array(repeating: Array(repeating: Character("A"), count: size), count: size)
        var placements: [WordSearchPlacement] = []
        var occupied = Set<WordSearchCoord>()

        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

        // Заполняем случайными буквами
        for r in 0..<size {
            for c in 0..<size {
                grid[r][c] = alphabet.randomElement()!
            }
        }

        // Размещаем слова (с поддержкой изгибов / ломаных линий по соседним клеткам)
        for word in targetWords {
            let chars = Array(word)
            if let path = findWanderingPath(for: chars, size: size, occupied: &occupied) {
                placements.append(WordSearchPlacement(word: word, coords: path))
                for (index, char) in chars.enumerated() {
                    let coord = path[index]
                    grid[coord.row][coord.col] = char
                    occupied.insert(coord)
                }
            }
        }

        return (grid, placements, size)
    }

    private static func findWanderingPath(for chars: [Character], size: Int, occupied: inout Set<WordSearchCoord>) -> [WordSearchCoord]? {
        // Поиск пути с изгибами (random walk по соседям)
        for _ in 0..<150 {
            let startRow = Int.random(in: 0..<size)
            let startCol = Int.random(in: 0..<size)
            let startCoord = WordSearchCoord(row: startRow, col: startCol)
            
            var currentPath = [startCoord]
            var visited = Set([startCoord])
            
            if backtrackPath(chars: chars, currentIndex: 1, currentPath: &currentPath, visited: &visited, size: size) {
                return currentPath
            }
        }
        
        // Запасной линейный вариант, если изгибистый путь не сошелся
        return findLinearPath(for: chars, size: size)
    }

    private static func backtrackPath(chars: [Character], currentIndex: Int, currentPath: inout [WordSearchCoord], visited: inout Set<WordSearchCoord>, size: Int) -> Bool {
        if currentIndex == chars.count { return true }
        
        let lastCoord = currentPath.last!
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)].shuffled()
        
        for dir in directions {
            let nextRow = lastCoord.row + dir.0
            let nextCol = lastCoord.col + dir.1
            let nextCoord = WordSearchCoord(row: nextRow, col: nextCol)
            
            if nextRow >= 0 && nextRow < size && nextCol >= 0 && nextCol < size && !visited.contains(nextCoord) {
                visited.insert(nextCoord)
                currentPath.append(nextCoord)
                
                if backtrackPath(chars: chars, currentIndex: currentIndex + 1, currentPath: &currentPath, visited: &visited, size: size) {
                    return true
                }
                
                currentPath.removeLast()
                visited.remove(nextCoord)
            }
        }
        return false
    }

    private static func findLinearPath(for chars: [Character], size: Int) -> [WordSearchCoord]? {
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]
        let length = chars.count
        
        for r in 0..<size {
            for c in 0..<size {
                for dir in directions {
                    var path: [WordSearchCoord] = []
                    var valid = true
                    for i in 0..<length {
                        let nr = r + dir.0 * i
                        let nc = c + dir.1 * i
                        if nr >= 0 && nr < size && nc >= 0 && nc < size {
                            path.append(WordSearchCoord(row: nr, col: nc))
                        } else {
                            valid = false
                            break
                        }
                    }
                    if valid { return path }
                }
            }
        }
        return nil
    }
}

// MARK: - Cell View

private final class WordCellView: UIView {
    private let label = UILabel()

    init(character: Character, sideSize: CGFloat) {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: sideSize, height: sideSize)))
        backgroundColor = BasePalitColors.cardBackground
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = BasePalitColors.separator.cgColor

        label.text = String(character)
        label.font = .systemFont(ofSize: sideSize * 0.45, weight: .bold)
        label.textColor = BasePalitColors.textPrimary
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateState(isSelected: Bool, isFound: Bool) {
        if isFound {
            backgroundColor = BasePalitColors.avatarBackground
            label.textColor = BasePalitColors.pureWhite
            layer.borderColor = BasePalitColors.avatarBackground.cgColor
        } else if isSelected {
            backgroundColor = BasePalitColors.selectedOption
            label.textColor = BasePalitColors.link
            layer.borderColor = BasePalitColors.link.cgColor
        } else {
            backgroundColor = BasePalitColors.cardBackground
            label.textColor = BasePalitColors.textPrimary
            layer.borderColor = BasePalitColors.separator.cgColor
        }
    }
}

// MARK: - Main Game Controller

final class Game10VC: UIViewController, GameCompletionProtocol {

    private var currentLevel = 1
    private var boardSize = 10
    private var gridLetters: [[Character]] = []
    private var placements: [WordSearchPlacement] = []
    private var foundWords = Set<String>()
    private var cellViews: [[WordCellView]] = []
    var onGameCompleted: (() -> Void)?
    
    private var currentSelectedCoords = Set<WordSearchCoord>()

    // MARK: UI Elements
    private let topCard: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.separator.cgColor
        return view
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = BasePalitColors.textPrimary
        btn.backgroundColor = BasePalitColors.unselectedOption
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return btn
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Word Search"
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = BasePalitColors.textPrimary
        lbl.textAlignment = .center
        return lbl
    }()

    private let levelLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = BasePalitColors.primary
        lbl.textAlignment = .center
        return lbl
    }()

    private lazy var prevLevelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = BasePalitColors.textPrimary
        btn.backgroundColor = BasePalitColors.unselectedOption
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(handlePrevLevel), for: .touchUpInside)
        return btn
    }()

    private lazy var nextLevelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        btn.tintColor = BasePalitColors.textPrimary
        btn.backgroundColor = BasePalitColors.unselectedOption
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(handleNextLevel), for: .touchUpInside)
        return btn
    }()

    private let wordsContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let gridContainerView = UIView()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BasePalitColors.background
        setupLayout()
        loadLevel(currentLevel)
    }

    private func setupLayout() {
        view.addSubview(topCard)
        topCard.addSubview(closeButton)
        topCard.addSubview(titleLabel)
        topCard.addSubview(levelLabel)
        topCard.addSubview(prevLevelButton)
        topCard.addSubview(nextLevelButton)
        topCard.addSubview(wordsContainerView)

        view.addSubview(scrollView)
        scrollView.addSubview(gridContainerView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        gridContainerView.addGestureRecognizer(panGesture)

        topCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }

        levelLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
        }

        prevLevelButton.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.leading.equalTo(closeButton.snp.trailing).offset(12)
            make.size.equalTo(28)
        }

        nextLevelButton.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(28)
        }

        wordsContainerView.snp.makeConstraints { make in
            make.top.equalTo(levelLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
            make.height.equalTo(36)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(topCard.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        gridContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(1) // динамически пересчитывается
        }
    }

    private func loadLevel(_ level: Int) {
        currentLevel = level
        foundWords.removeAll()
        currentSelectedCoords.removeAll()

        let data = WordSearchGenerator.generateBoard(level: level)
        gridLetters = data.grid
        placements = data.placements
        boardSize = data.size

        levelLabel.text = "LEVEL \(currentLevel) (\(boardSize)x\(boardSize))"
        rebuildWordsHeader()
        rebuildGridUI()
    }

    private func rebuildWordsHeader() {
        wordsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .equalCentering
        
        for placement in placements {
            let label = UILabel()
            label.text = placement.word
            label.font = .systemFont(ofSize: 13, weight: .bold)
            if foundWords.contains(placement.word) {
                label.textColor = BasePalitColors.textSecondary
                // Эффект зачеркивания
                let attributeString = NSMutableAttributedString(string: placement.word)
                attributeString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, placement.word.count))
                label.attributedText = attributeString
            } else {
                label.textColor = BasePalitColors.textPrimary
            }
            stack.addArrangedSubview(label)
        }

        wordsContainerView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func rebuildGridUI() {
        gridContainerView.subviews.forEach { $0.removeFromSuperview() }
        cellViews = []

        let availableWidth = view.bounds.width - 32
        let cellSize = floor(availableWidth / CGFloat(boardSize))

        var rows: [[WordCellView]] = []
        for r in 0..<boardSize {
            var rowViews: [WordCellView] = []
            for c in 0..<boardSize {
                let cell = WordCellView(character: gridLetters[r][c], sideSize: cellSize - 3)
                gridContainerView.addSubview(cell)
                cell.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(CGFloat(r) * cellSize)
                    make.leading.equalToSuperview().offset(CGFloat(c) * cellSize)
                    make.size.equalTo(cellSize - 3)
                }
                rowViews.append(cell)
            }
            rows.append(rowViews)
        }
        cellViews = rows

        let totalGridSize = CGFloat(boardSize) * cellSize
        gridContainerView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(totalGridSize)
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: gridContainerView)
        let availableWidth = gridContainerView.bounds.width
        let cellSize = availableWidth / CGFloat(boardSize)

        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)

        if row >= 0 && row < boardSize && col >= 0 && col < boardSize {
            let coord = WordSearchCoord(row: row, col: col)
            if gesture.state == .began {
                currentSelectedCoords = [coord]
                updateCellSelectionVisuals()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else if gesture.state == .changed {
                if !currentSelectedCoords.contains(coord) {
                    currentSelectedCoords.insert(coord)
                    updateCellSelectionVisuals()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else if gesture.state == .ended || gesture.state == .cancelled {
                evaluateSelection()
            }
        } else if gesture.state == .ended || gesture.state == .cancelled {
            currentSelectedCoords.removeAll()
            updateCellSelectionVisuals()
        }
    }

    private func updateCellSelectionVisuals() {
        for r in 0..<boardSize {
            for c in 0..<boardSize {
                let coord = WordSearchCoord(row: r, col: c)
                let isSelected = currentSelectedCoords.contains(coord)
                
                // Проверяем, входит ли ячейка в уже найденное слово
                let isFound = placements.contains { placement in
                    foundWords.contains(placement.word) && placement.coords.contains(coord)
                }
                
                cellViews[r][c].updateState(isSelected: isSelected, isFound: isFound)
            }
        }
    }

    private func evaluateSelection() {
        // Проверяем, совпадает ли выбранный набор координат с каким-то скрытым словом
        for placement in placements {
            if !foundWords.contains(placement.word) {
                let placementSet = Set(placement.coords)
                if placementSet == currentSelectedCoords {
                    foundWords.insert(placement.word)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    rebuildWordsHeader()
                    checkVictory()
                    break
                }
            }
        }
        currentSelectedCoords.removeAll()
        updateCellSelectionVisuals()
    }

    private func checkVictory() {
        if foundWords.count == placements.count {
            if let onGameCompleted {
                onGameCompleted()
                return
            }
            
            let alert = UIAlertController(title: "Stage Cleared!", message: "You found all words in level \(currentLevel). Ready for the next challenge?", preferredStyle: .alert)
            alert.overrideUserInterfaceStyle = .dark
            alert.addAction(UIAlertAction(title: "Next Level", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.loadLevel(self.currentLevel + 1)
            }))
            present(alert, animated: true)
        }
    }

    @objc private func handlePrevLevel() {
        if currentLevel > 1 {
            loadLevel(currentLevel - 1)
        }
    }

    @objc private func handleNextLevel() {
        loadLevel(currentLevel + 1)
    }

    @objc private func handleClose() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
