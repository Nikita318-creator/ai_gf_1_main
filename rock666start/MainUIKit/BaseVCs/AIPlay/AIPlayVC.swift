import UIKit
import SnapKit

final class AIPlayVC: UIViewController {
    
    // MARK: - Models & Data
    private struct QuizTopic {
        let title: String
        let iconName: String
    }
    
    private let topics: [QuizTopic] = [
        QuizTopic(title: "Fashion Designer", iconName: "icon27"),
        QuizTopic(title: "Tattoo Artist", iconName: "icon1"),
        QuizTopic(title: "Indie Musician", iconName: "icon28"),
        QuizTopic(title: "Python Developer", iconName: "icon2"),
        QuizTopic(title: "Pastry Chef", iconName: "icon4"),
        QuizTopic(title: "Fitness Coach", iconName: "icon3"),
        QuizTopic(title: "Anime Illustrator", iconName: "icon11"),
        QuizTopic(title: "Pro eSports Gamer", iconName: "icon29"),
        QuizTopic(title: "Yoga & Mindfulness Guru", iconName: "icon30"),
        QuizTopic(title: "Cybersecurity Specialist", iconName: "icon12"),
        QuizTopic(title: "Manga Concept Artist", iconName: "icon31"),
        QuizTopic(title: "VTuber Streamer", iconName: "icon32"),
        QuizTopic(title: "Sommelier", iconName: "icon36"),
        QuizTopic(title: "Barista & Coffee Roaster", iconName: "icon34"),
        QuizTopic(title: "Art Historian", iconName: "icon35"),
        QuizTopic(title: "Sound Producer", iconName: "icon33")
    ]
    
    private var currentTopicIndex = 0
    private var gridSize = 3 // 3, 4, or 5
    
    private var board: [Int] = []
    private var emptyIndex: Int = 0
    private var isSolved = false
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = BasePalitColors.background
        return sv
    }()
    
    private let contentView = UIView()
    
    private let headerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = BasePalitColors.cardBackground
        v.layer.cornerRadius = 16
        return v
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "AI Puzzle Challenge"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = BasePalitColors.textPrimary
        return lbl
    }()
    
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Slide adjacent tiles into the empty space or swipe anywhere on the board to move pieces. Arrange all slices in correct order to complete the pattern!"
        lbl.font = .systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = BasePalitColors.textSecondary
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let controlsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 12
        return sv
    }()
    
    private let topicSelectButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = BasePalitColors.unselectedOption
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    private let topicButtonImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    private let topicButtonLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13, weight: .semibold)
        lbl.textColor = BasePalitColors.textPrimary
        lbl.isUserInteractionEnabled = false
        return lbl
    }()
    
    private let topicChevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = BasePalitColors.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    private let gridSelectButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = BasePalitColors.unselectedOption
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    private let gridButtonLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13, weight: .semibold)
        lbl.textColor = BasePalitColors.textPrimary
        lbl.isUserInteractionEnabled = false
        return lbl
    }()
    
    private let gridChevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.down")
        iv.tintColor = BasePalitColors.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = false
        return iv
    }()
    
    private let puzzleContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = BasePalitColors.cardBackground
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        return v
    }()
    
    private var tileViews: [UIView] = []
    
    private let shuffleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Shuffle Puzzle", for: .normal)
        btn.setTitleColor(BasePalitColors.pureWhite, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = BasePalitColors.primary
        btn.layer.cornerRadius = 14
        return btn
    }()
    
    private var hasInited = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupGestures()
        updateTopicInfo()
        updateGridButtonInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTiles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasInited {
            hasInited = true
            setupNewGame()
        }
    }
    
    // MARK: - Setup UI
    private func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = "AI Puzzle"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = BasePalitColors.textPrimary
        titleLabel.sizeToFit()
        
        navigationItem.titleView = titleLabel
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BasePalitColors.background
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }
    
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerContainer)
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(subtitleLabel)
        headerContainer.addSubview(controlsStackView)
        
        // Topic Select Button Setup
        topicSelectButton.addSubview(topicButtonImageView)
        topicSelectButton.addSubview(topicButtonLabel)
        topicSelectButton.addSubview(topicChevronImageView)
        topicSelectButton.addTarget(self, action: #selector(didTapTopicSelector), for: .touchUpInside)
        
        // Grid Select Button Setup
        gridSelectButton.addSubview(gridButtonLabel)
        gridSelectButton.addSubview(gridChevronImageView)
        gridSelectButton.addTarget(self, action: #selector(didTapGridSelector), for: .touchUpInside)
        
        controlsStackView.addArrangedSubview(topicSelectButton)
        controlsStackView.addArrangedSubview(gridSelectButton)
        
        contentView.addSubview(puzzleContainerView)
        contentView.addSubview(shuffleButton)
        shuffleButton.addTarget(self, action: #selector(didTapShuffle), for: .touchUpInside)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        controlsStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        topicButtonImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }
        
        topicButtonLabel.snp.makeConstraints { make in
            make.leading.equalTo(topicButtonImageView.snp.trailing).offset(8)
            make.trailing.equalTo(topicChevronImageView.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }
        
        topicChevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
        
        gridButtonLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(gridChevronImageView.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
        }
        
        gridChevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
        
        puzzleContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(puzzleContainerView.snp.width)
        }
        
        shuffleButton.snp.makeConstraints { make in
            make.top.equalTo(puzzleContainerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.direction = .up
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        
        [swipeLeft, swipeRight, swipeUp, swipeDown].forEach {
            puzzleContainerView.addGestureRecognizer($0)
        }
        puzzleContainerView.isUserInteractionEnabled = true
    }
    
    // MARK: - Game Logic & Updates
    private func updateTopicInfo() {
        let topic = topics[currentTopicIndex]
        topicButtonLabel.text = topic.title
        let icon = UIImage(named: topic.iconName) ?? UIImage(systemName: "photo") ?? UIImage()
        topicButtonImageView.image = icon
    }
    
    private func updateGridButtonInfo() {
        gridButtonLabel.text = "Grid: \(gridSize)×\(gridSize)"
    }
    
    @objc private func didTapTopicSelector() {
        let mappedTopics = topics.map { ($0.title, $0.iconName) }
        let sheet = TopicSelectionSheet(topics: mappedTopics, currentIndex: currentTopicIndex) { [weak self] selectedIndex in
            guard let self = self else { return }
            self.currentTopicIndex = selectedIndex
            self.updateTopicInfo()
            self.setupNewGame()
        }
        sheet.modalPresentationStyle = .overFullScreen
        present(sheet, animated: false)
    }
    
    @objc private func didTapGridSelector() {
        let sheet = GridSizeSelectionSheet(currentSize: gridSize) { [weak self] selectedSize in
            guard let self = self else { return }
            self.gridSize = selectedSize
            self.updateGridButtonInfo()
            self.setupNewGame()
        }
        sheet.modalPresentationStyle = .overFullScreen
        present(sheet, animated: false)
    }
    
    private func setupNewGame() {
        isSolved = false
        let totalTiles = gridSize * gridSize
        board = Array(0..<totalTiles)
        emptyIndex = totalTiles - 1
        
        // Shuffle using valid moves
        for _ in 0..<(gridSize * 50) {
            let validMoves = getValidAdjacentIndices(to: emptyIndex)
            if let randomMove = validMoves.randomElement() {
                board.swapAt(emptyIndex, randomMove)
                emptyIndex = randomMove
            }
        }
        
        rebuildTileViews()
    }
    
    private func getValidAdjacentIndices(to index: Int) -> [Int] {
        let row = index / gridSize
        let col = index % gridSize
        var valid: [Int] = []
        
        if row > 0 { valid.append((row - 1) * gridSize + col) }
        if row < gridSize - 1 { valid.append((row + 1) * gridSize + col) }
        if col > 0 { valid.append(row * gridSize + (col - 1)) }
        if col < gridSize - 1 { valid.append(row * gridSize + (col + 1)) }
        
        return valid
    }
    
    private func rebuildTileViews() {
        tileViews.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        
        let totalTiles = gridSize * gridSize
        let baseImage = UIImage(named: topics[currentTopicIndex].iconName) ?? UIImage(systemName: "photo") ?? UIImage()
        
        for i in 0..<totalTiles {
            let tileView = UIView()
            tileView.backgroundColor = BasePalitColors.tile2
            tileView.layer.cornerRadius = 10
            tileView.clipsToBounds = true
            
            if i != totalTiles - 1 {
                let sliceView = UIImageView(image: cropImage(baseImage, at: i, total: gridSize))
                sliceView.contentMode = .scaleAspectFill
                tileView.addSubview(sliceView)
                sliceView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(handleTileTap(_:)))
                tileView.addGestureRecognizer(tap)
                tileView.isUserInteractionEnabled = true
            } else {
                tileView.backgroundColor = BasePalitColors.cardBackground
            }
            
            puzzleContainerView.addSubview(tileView)
            tileViews.append(tileView)
        }
        
        layoutTiles()
    }
    
    private func layoutTiles() {
        guard puzzleContainerView.bounds.width > 0 else { return }
        let containerSize = puzzleContainerView.bounds.width
        let tileSize = containerSize / CGFloat(gridSize)
        
        for (index, tileNumber) in board.enumerated() {
            let tileView = tileViews[tileNumber]
            let row = index / gridSize
            let col = index % gridSize
            
            tileView.frame = CGRect(
                x: CGFloat(col) * tileSize + 3,
                y: CGFloat(row) * tileSize + 3,
                width: tileSize - 6,
                height: tileSize - 6
            )
        }
    }
    
    private func cropImage(_ image: UIImage, at index: Int, total: Int) -> UIImage {
        let row = index / total
        let col = index % total
        let size = image.size
        let pieceWidth = size.width / CGFloat(total)
        let pieceHeight = size.height / CGFloat(total)
        
        let cropRect = CGRect(
            x: CGFloat(col) * pieceWidth,
            y: CGFloat(row) * pieceHeight,
            width: pieceWidth,
            height: pieceHeight
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Interactions & Animations
    @objc private func handleTileTap(_ gesture: UITapGestureRecognizer) {
        guard !isSolved, let tappedView = gesture.view else { return }
        guard let tileNumber = tileViews.firstIndex(of: tappedView),
              let currentIndex = board.firstIndex(of: tileNumber) else { return }
        
        if getValidAdjacentIndices(to: emptyIndex).contains(currentIndex) {
            moveTile(from: currentIndex, to: emptyIndex)
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !isSolved else { return }
        
        var targetIndex: Int? = nil
        let emptyRow = emptyIndex / gridSize
        let emptyCol = emptyIndex % gridSize
        
        switch gesture.direction {
        case .left:
            if emptyCol < gridSize - 1 { targetIndex = emptyIndex + 1 }
        case .right:
            if emptyCol > 0 { targetIndex = emptyIndex - 1 }
        case .up:
            if emptyRow < gridSize - 1 { targetIndex = emptyIndex + gridSize }
        case .down:
            if emptyRow > 0 { targetIndex = emptyIndex - gridSize }
        default:
            break
        }
        
        if let target = targetIndex {
            moveTile(from: target, to: emptyIndex)
        }
    }
    
    private func moveTile(from sourceIndex: Int, to destinationIndex: Int) {
        board.swapAt(sourceIndex, destinationIndex)
        emptyIndex = sourceIndex
        
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            self.layoutTiles()
        } completion: { _ in
            self.checkWinCondition()
        }
    }
    
    @objc private func didTapShuffle() {
        setupNewGame()
    }
    
    private func checkWinCondition() {
        let total = gridSize * gridSize
        for i in 0..<total {
            if board[i] != i { return }
        }
        
        isSolved = true
        showCongratsAlert()
    }
    
    private func showCongratsAlert() {
        let alert = UIAlertController(
            title: "🎉 Congratulations!",
            message: "You successfully solved the puzzle for \(topics[currentTopicIndex].title)!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Next Puzzle", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.currentTopicIndex = (self.currentTopicIndex + 1) % self.topics.count
            self.updateTopicInfo()
            self.setupNewGame()
        })
        present(alert, animated: true)
    }
}

// MARK: - Custom Bottom Sheet: Topic Selection

final class TopicSelectionSheet: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private struct TopicItem {
        let title: String
        let iconName: String
    }
    
    private let topics: [TopicItem]
    private let currentIndex: Int
    private let onSelect: (Int) -> Void
    
    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.alpha = 0
        return v
    }()
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = BasePalitColors.cardBackground
        v.layer.cornerRadius = 24
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Choose Puzzle Icon"
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = BasePalitColors.textPrimary
        return lbl
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = BasePalitColors.textSecondary
        btn.backgroundColor = BasePalitColors.unselectedOption
        btn.layer.cornerRadius = 16
        return btn
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(TopicCell.self, forCellWithReuseIdentifier: TopicCell.identifier)
        cv.showsVerticalScrollIndicator = false
        return cv
    }()
    
    init(topics: [(title: String, iconName: String)], currentIndex: Int, onSelect: @escaping (Int) -> Void) {
        self.topics = topics.map { TopicItem(title: $0.title, iconName: $0.iconName) }
        self.currentIndex = currentIndex
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(dimmingView)
        view.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(collectionView)
        
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.75)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(32)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview().inset(20)
        }
        
        closeButton.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        tap.delegate = self
        dimmingView.addGestureRecognizer(tap)
    }
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.dimmingView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    @objc private func dismissSheet() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
            self.dimmingView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.frame.height)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    // MARK: - CollectionView DataSource & Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TopicCell.identifier, for: indexPath) as? TopicCell else {
            return UICollectionViewCell()
        }
        let topic = topics[indexPath.item]
        cell.configure(with: topic.title, iconName: topic.iconName, isSelected: indexPath.item == currentIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        return CGSize(width: width, height: 72)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect(indexPath.item)
        dismissSheet()
    }
}

extension TopicSelectionSheet: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view === dimmingView
    }
}

final class TopicCell: UICollectionViewCell {
    static let identifier = "TopicCell"
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13, weight: .semibold)
        lbl.textColor = BasePalitColors.textPrimary
        lbl.numberOfLines = 2
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = BasePalitColors.unselectedOption
        layer.cornerRadius = 14
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with title: String, iconName: String, isSelected: Bool) {
        titleLabel.text = title
        iconImageView.image = UIImage(named: iconName) ?? UIImage(systemName: "photo")
        layer.borderWidth = isSelected ? 2 : 0
        layer.borderColor = isSelected ? BasePalitColors.primary.cgColor : UIColor.clear.cgColor
    }
}

// MARK: - Custom Bottom Sheet: Grid Size Selection

final class GridSizeSelectionSheet: UIViewController {
    
    private let currentSize: Int
    private let onSelect: (Int) -> Void
    
    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.alpha = 0
        return v
    }()
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = BasePalitColors.cardBackground
        v.layer.cornerRadius = 24
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return v
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Select Grid Difficulty"
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = BasePalitColors.textPrimary
        return lbl
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.distribution = .fillEqually
        return sv
    }()
    
    init(currentSize: Int, onSelect: @escaping (Int) -> Void) {
        self.currentSize = currentSize
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(dimmingView)
        view.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)
        
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(300)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview().inset(20)
        }
        
        let sizes = [(3, "3×3 (Easy)"), (4, "4×4 (Medium)"), (5, "5×5 (Expert)")]
        for (size, desc) in sizes {
            let btn = UIButton(type: .system)
            btn.setTitle(desc, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            btn.layer.cornerRadius = 14
            btn.tag = size
            
            if size == currentSize {
                btn.backgroundColor = BasePalitColors.primary
                btn.setTitleColor(BasePalitColors.pureWhite, for: .normal)
            } else {
                btn.backgroundColor = BasePalitColors.unselectedOption
                btn.setTitleColor(BasePalitColors.textPrimary, for: .normal)
            }
            
            btn.addTarget(self, action: #selector(didSelectSize(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(btn)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        tap.delegate = self
        dimmingView.addGestureRecognizer(tap)
    }
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.dimmingView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    @objc private func didSelectSize(_ sender: UIButton) {
        onSelect(sender.tag)
        dismissSheet()
    }
    
    @objc private func dismissSheet() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
            self.dimmingView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.frame.height)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
}

extension GridSizeSelectionSheet: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.value(forKey: "view") as? UIView === dimmingView || touch.view === dimmingView
    }
}
