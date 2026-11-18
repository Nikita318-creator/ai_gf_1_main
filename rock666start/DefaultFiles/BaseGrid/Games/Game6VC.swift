import UIKit
import SnapKit

final class Game6VC: UIViewController, GameCompletionProtocol {
    var onGameCompleted: (() -> Void)? 
    // MARK: - Difficulty
    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
        
        var removedCells: Int {
            switch self {
            case .easy: return 32
            case .medium: return 40
            case .hard: return 48
            case .expert: return 54
            }
        }
    }
    
    private let gridSize = 9
    private var solutionBoard: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    private var currentBoard: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    private var initialMask: [[Bool]] = Array(repeating: Array(repeating: false, count: 9), count: 9)
    
    private var selectedCell: (row: Int, col: Int)? = nil
    private var cells: [[UIButton]] = []
    private var currentDifficulty: Difficulty = .medium {
        didSet {
            UserDefaults.standard.set(currentDifficulty.rawValue, forKey: difficultySaveKey)
        }
    }
    
    // Keys for persistence
    private let gameSaveKey = "Game6VC_progress_state"
    private var boardSaveKey: String { gameSaveKey + "_board" }
    private var solutionSaveKey: String { gameSaveKey + "_solution" }
    private var initialSaveKey: String { gameSaveKey + "_initial" }
    private var difficultySaveKey: String { gameSaveKey + "_difficulty" }
    
    // UI Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let difficultyButton = UIButton(type: .system)
    
    private let boardContainer = UIView()
    private let numberPadStack = UIStackView()
    private let statusLabel = UILabel()
    private var restartButton: UIButton?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        loadSavedDifficulty()
        setupUI()
        
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
        
        // Navigation Bar
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
        
        titleLabel.text = "Puzzle Game"
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
        
        // Status Label
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = BasePalitColors.textSecondary
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        // Board Container
        view.addSubview(boardContainer)
        boardContainer.backgroundColor = BasePalitColors.cardBackground
        boardContainer.layer.cornerRadius = 16
        boardContainer.layer.borderWidth = 2
        boardContainer.layer.borderColor = BasePalitColors.separator.cgColor
        boardContainer.clipsToBounds = true
        boardContainer.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(min(view.frame.width - 32, 380))
        }
        
        setupBoardGrid()
        setupNumberPad()
    }
    
    private func setupBoardGrid() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 1
        boardContainer.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        
        for r in 0..<gridSize {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 1
            mainStack.addArrangedSubview(rowStack)
            
            var rowButtons: [UIButton] = []
            for c in 0..<gridSize {
                let btn = UIButton()
                btn.backgroundColor = BasePalitColors.background
                btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
                btn.tag = r * 10 + c
                btn.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                rowStack.addArrangedSubview(btn)
                rowButtons.append(btn)
            }
            cells.append(rowButtons)
        }
    }
    
    private func setupNumberPad() {
        view.addSubview(numberPadStack)
        numberPadStack.axis = .horizontal
        numberPadStack.distribution = .fillEqually
        numberPadStack.spacing = 8
        
        numberPadStack.snp.makeConstraints { make in
            make.top.equalTo(boardContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        for i in 1...9 {
            let btn = UIButton(type: .system)
            btn.setTitle("\(i)", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
            btn.tintColor = BasePalitColors.textPrimary
            btn.backgroundColor = BasePalitColors.cardBackground
            btn.layer.cornerRadius = 12
            btn.tag = i
            btn.addTarget(self, action: #selector(numberPadTapped(_:)), for: .touchUpInside)
            numberPadStack.addArrangedSubview(btn)
        }
        
        // Erase button
        let eraseBtn = UIButton(type: .system)
        eraseBtn.setImage(UIImage(systemName: "delete.left"), for: .normal)
        eraseBtn.tintColor = BasePalitColors.accentRed
        eraseBtn.backgroundColor = BasePalitColors.cardBackground
        eraseBtn.layer.cornerRadius = 12
        eraseBtn.tag = 0
        eraseBtn.addTarget(self, action: #selector(numberPadTapped(_:)), for: .touchUpInside)
        numberPadStack.addArrangedSubview(eraseBtn)
    }

    // MARK: - Game Generation & Logic
    private func startNewGame() {
        generateValidSudoku()
        createPuzzle(from: solutionBoard, removedCount: currentDifficulty.removedCells)
        selectedCell = nil
        restartButton?.removeFromSuperview()
        restartButton = nil
        
        saveGameState()
        updateUI()
    }
    
    private func generateValidSudoku() {
        solutionBoard = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        fillBoard(row: 0, col: 0)
    }
    
    private func fillBoard(row: Int, col: Int) -> Bool {
        var nextRow = row
        var nextCol = col + 1
        if nextCol >= 9 {
            nextCol = 0
            nextRow += 1
            if nextRow >= 9 { return true }
        }
        
        let numbers = Array(1...9).shuffled()
        for num in numbers {
            if isValid(board: solutionBoard, row: row, col: col, num: num) {
                solutionBoard[row][col] = num
                if fillBoard(row: nextRow, col: nextCol) { return true }
                solutionBoard[row][col] = 0
            }
        }
        return false
    }
    
    private func isValid(board: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        for i in 0..<9 {
            if board[row][i] == num || board[i][col] == num { return false }
        }
        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for r in 0..<3 {
            for c in 0..<3 {
                if board[startRow + r][startCol + c] == num { return false }
            }
        }
        return true
    }
    
    private func createPuzzle(from solved: [[Int]], removedCount: Int) {
        currentBoard = solved
        initialMask = Array(repeating: Array(repeating: true, count: 9), count: 9)
        
        var removed = 0
        while removed < removedCount {
            let r = Int.random(in: 0..<9)
            let c = Int.random(in: 0..<9)
            if currentBoard[r][c] != 0 {
                currentBoard[r][c] = 0
                initialMask[r][c] = false
                removed += 1
            }
        }
    }

    @objc private func cellTapped(_ sender: UIButton) {
        let r = sender.tag / 10
        let c = sender.tag % 10
        
        selectedCell = (r, c)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateUI()
    }
    
    @objc private func numberPadTapped(_ sender: UIButton) {
        guard let sel = selectedCell else { return }
        if initialMask[sel.row][sel.col] { return } // Нельзя менять исходные цифры
        
        let val = sender.tag
        currentBoard[sel.row][sel.col] = val
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        saveGameState()
        updateUI()
        checkGameCompletion()
    }

    private func checkGameCompletion() {
        for r in 0..<9 {
            for c in 0..<9 {
                if currentBoard[r][c] == 0 || currentBoard[r][c] != solutionBoard[r][c] {
                    return
                }
            }
        }
        
        // Победа
        if let onGameCompleted {
            onGameCompleted()
            return
        }
        
        statusLabel.text = "Congratulations! Puzzle Solved!"
        clearSavedState()
        showRestartButton()
    }

    private func updateUI() {
        statusLabel.text = "Difficulty: \(currentDifficulty.rawValue)"
        
        for r in 0..<9 {
            for c in 0..<9 {
                let btn = cells[r][c]
                let val = currentBoard[r][c]
                
                if val == 0 {
                    btn.setTitle("", for: .normal)
                } else {
                    btn.setTitle("\(val)", for: .normal)
                }
                
                // Стилизация текста и фона в зависимости от состояния
                if initialMask[r][c] {
                    btn.setTitleColor(BasePalitColors.textPrimary, for: .normal)
                    btn.backgroundColor = BasePalitColors.cardBackground
                } else {
                    btn.setTitleColor(BasePalitColors.primary, for: .normal)
                    btn.backgroundColor = BasePalitColors.background
                }
                
                // Выделение выбранной ячейки
                if let sel = selectedCell, sel.row == r, sel.col == c {
                    btn.backgroundColor = BasePalitColors.selectedOption
                }
            }
        }
    }

    // MARK: - Save & Restore State
    private func saveGameState() {
        let flatBoard = currentBoard.flatMap { $0 }
        let flatSolution = solutionBoard.flatMap { $0 }
        let flatInitial = initialMask.flatMap { $0.map { $0 ? 1 : 0 } }
        
        UserDefaults.standard.set(flatBoard, forKey: boardSaveKey)
        UserDefaults.standard.set(flatSolution, forKey: solutionSaveKey)
        UserDefaults.standard.set(flatInitial, forKey: initialSaveKey)
    }
    
    private func restoreGameState() -> Bool {
        guard let flatBoard = UserDefaults.standard.array(forKey: boardSaveKey) as? [Int],
              let flatSolution = UserDefaults.standard.array(forKey: solutionSaveKey) as? [Int],
              let flatInitial = UserDefaults.standard.array(forKey: initialSaveKey) as? [Int],
              flatBoard.count == 81, flatSolution.count == 81, flatInitial.count == 81 else {
            return false
        }
        
        for i in 0..<81 {
            let r = i / 9
            let c = i % 9
            currentBoard[r][c] = flatBoard[i]
            solutionBoard[r][c] = flatSolution[i]
            initialMask[r][c] = flatInitial[i] == 1
        }
        
        updateUI()
        return true
    }
    
    private func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
        UserDefaults.standard.removeObject(forKey: solutionSaveKey)
        UserDefaults.standard.removeObject(forKey: initialSaveKey)
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
            make.bottom.equalTo(numberPadStack.snp.top).offset(-16)
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
}
