import UIKit
import SnapKit

final class Game7VC: UIViewController {
    
    // MARK: - Models & State
    enum Difficulty: String, CaseIterable {
        case easy = "Easy (4x3)"
        case medium = "Medium (4x4)"
        case hard = "Hard (4x5)"
        
        var rows: Int {
            switch self {
            case .easy: return 4
            case .medium: return 4
            case .hard: return 5
            }
        }
        
        var cols: Int {
            switch self {
            case .easy: return 3
            case .medium: return 4
            case .hard: return 4
            }
        }
    }
    
    struct Card {
        let id: Int
        let symbol: String
        var isFlipped = false
        var isMatched = false
    }
    
    private var cards: [Card] = []
    private var currentDifficulty: Difficulty = .medium {
        didSet {
            UserDefaults.standard.set(currentDifficulty.rawValue, forKey: difficultySaveKey)
        }
    }
    
    private var flippedIndexPath: IndexPath?
    private var isProcessing = false
    private var movesCount = 0
    private var matchesCount = 0
    
    // Keys for persistence
    private let gameSaveKey = "Game7VC_progress_state"
    private var difficultySaveKey: String { gameSaveKey + "_difficulty" }
    private var movesSaveKey: String { gameSaveKey + "_moves" }
    
    // Emojis for memory matching
    private let availableSymbols = ["🍎", "🚀", "💎", "⭐", "🦄", "🎸", "🍀", "⚡️", "🔥", "🎯"]
    
    // UI Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let difficultyButton = UIButton(type: .system)
    
    private let scoreContainer = UIView()
    private let movesLabel = UILabel()
    private let matchesLabel = UILabel()
    
    private var collectionView: UICollectionView!
    private var restartButton: UIButton?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        loadSavedSettings()
        setupUI()
        setupCollectionView()
        
        if !restoreGameState() {
            startNewGame()
        }
    }
    
    private func loadSavedSettings() {
        if let savedDiffRaw = UserDefaults.standard.string(forKey: difficultySaveKey),
           let diff = Difficulty(rawValue: savedDiffRaw) {
            currentDifficulty = diff
        }
        movesCount = UserDefaults.standard.integer(forKey: movesSaveKey)
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
        
        titleLabel.text = "Memory Match"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = BasePalitColors.textPrimary
        titleLabel.textAlignment = .center
        customNavBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        difficultyButton.setTitle(currentDifficulty.rawValue, for: .normal)
        difficultyButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        difficultyButton.tintColor = BasePalitColors.primary
        difficultyButton.backgroundColor = BasePalitColors.cardBackground
        difficultyButton.layer.cornerRadius = 16
        difficultyButton.addTarget(self, action: #selector(changeDifficultyTapped), for: .touchUpInside)
        customNavBar.addSubview(difficultyButton)
        difficultyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.equalTo(110)
        }
        
        // Score Container
        view.addSubview(scoreContainer)
        scoreContainer.backgroundColor = BasePalitColors.cardBackground
        scoreContainer.layer.cornerRadius = 16
        scoreContainer.layer.borderWidth = 1
        scoreContainer.layer.borderColor = BasePalitColors.separator.cgColor
        scoreContainer.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        movesLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        movesLabel.textColor = BasePalitColors.textPrimary
        scoreContainer.addSubview(movesLabel)
        movesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        
        matchesLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        matchesLabel.textColor = BasePalitColors.primary
        scoreContainer.addSubview(matchesLabel)
        matchesLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        
        updateScoreLabels()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MemoryCardCell.self, forCellWithReuseIdentifier: "MemoryCardCell")
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(scoreContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }

    // MARK: - Game Logic
    private func startNewGame() {
        movesCount = 0
        matchesCount = 0
        flippedIndexPath = nil
        isProcessing = false
        restartButton?.removeFromSuperview()
        restartButton = nil
        
        let totalCards = currentDifficulty.rows * currentDifficulty.cols
        let pairsCount = totalCards / 2
        
        let selectedSymbols = Array(availableSymbols.shuffled().prefix(pairsCount))
        var tempCards: [Card] = []
        
        for (index, symbol) in selectedSymbols.enumerated() {
            tempCards.append(Card(id: index * 2, symbol: symbol))
            tempCards.append(Card(id: index * 2 + 1, symbol: symbol))
        }
        
        cards = tempCards.shuffled()
        saveGameState()
        updateScoreLabels()
        collectionView.reloadData()
    }

    private func updateScoreLabels() {
        movesLabel.text = "Moves: \(movesCount)"
        let totalPairs = (currentDifficulty.rows * currentDifficulty.cols) / 2
        matchesLabel.text = "Matches: \(matchesCount)/\(totalPairs)"
    }
    
    private func saveGameState() {
        UserDefaults.standard.set(movesCount, forKey: movesSaveKey)
    }
    
    private func restoreGameState() -> Bool {
        guard movesCount > 0 else { return false }
        startNewGame()
        return true
    }
    
    private func clearSavedState() {
        movesCount = 0
        UserDefaults.standard.removeObject(forKey: movesSaveKey)
    }

    // MARK: - Actions & Handlers
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
    
    @objc private func restartTapped() {
        clearSavedState()
        startNewGame()
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    private func checkWinCondition() {
        let totalPairs = (currentDifficulty.rows * currentDifficulty.cols) / 2
        if matchesCount == totalPairs {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            showRestartButton()
        }
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
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.width.equalTo(180)
            make.height.equalTo(48)
        }
        restartButton = btn
    }
}

// MARK: - CollectionView DataSource & Delegate
extension Game7VC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemoryCardCell", for: indexPath) as? MemoryCardCell else {
            return UICollectionViewCell()
        }
        let card = cards[indexPath.item]
        cell.configure(with: card)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let rows = CGFloat(currentDifficulty.rows)
        let cols = CGFloat(currentDifficulty.cols)
        let spacing: CGFloat = 10
        
        let totalWidthSpacing = (cols - 1) * spacing
        let totalHeightSpacing = (rows - 1) * spacing
        
        let availableWidth = collectionView.frame.width - totalWidthSpacing
        let availableHeight = collectionView.frame.height - totalHeightSpacing
        
        let width = availableWidth / cols
        let height = availableHeight / rows
        
        return CGSize(width: floor(width), height: floor(height))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isProcessing else { return }
        var selectedCard = cards[indexPath.item]
        
        if selectedCard.isFlipped || selectedCard.isMatched { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedCard.isFlipped = true
        cards[indexPath.item] = selectedCard
        
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCardCell {
            cell.flip(to: selectedCard)
        }
        
        if let firstPath = flippedIndexPath {
            // Вторая карточка открыта
            isProcessing = true
            movesCount += 1
            updateScoreLabels()
            saveGameState()
            
            let firstCard = cards[firstPath.item]
            
            if firstCard.symbol == selectedCard.symbol {
                // Совпадение
                cards[firstPath.item].isMatched = true
                cards[indexPath.item].isMatched = true
                matchesCount += 1
                isProcessing = false
                flippedIndexPath = nil
                updateScoreLabels()
                checkWinCondition()
            } else {
                // Не совпадение, переворачиваем обе карточки обратно
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    guard let self = self else { return }
                    
                    self.cards[firstPath.item].isFlipped = false
                    self.cards[indexPath.item].isFlipped = false
                    
                    if let cell1 = self.collectionView.cellForItem(at: firstPath) as? MemoryCardCell {
                        cell1.flip(to: self.cards[firstPath.item])
                    }
                    if let cell2 = self.collectionView.cellForItem(at: indexPath) as? MemoryCardCell {
                        cell2.flip(to: self.cards[indexPath.item])
                    }
                    
                    self.flippedIndexPath = nil
                    self.isProcessing = false
                }
            }
        } else {
            // Первая карточка открыта
            flippedIndexPath = indexPath
        }
    }
}

// MARK: - Custom Cell for Cards
final class MemoryCardCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.backgroundColor = BasePalitColors.cardBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = BasePalitColors.separator.cgColor
        contentView.clipsToBounds = true
        
        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with card: Game7VC.Card) {
        if card.isFlipped || card.isMatched {
            label.text = card.symbol
            contentView.backgroundColor = card.isMatched ? BasePalitColors.primary.withAlphaComponent(0.2) : BasePalitColors.bubbleBackground
        } else {
            label.text = ""
            contentView.backgroundColor = BasePalitColors.cardBackground
        }
    }
    
    func flip(to card: Game7VC.Card) {
        UIView.transition(with: contentView, duration: 0.3, options: .transitionFlipFromLeft, animations: {
            self.configure(with: card)
        }, completion: nil)
    }
}
