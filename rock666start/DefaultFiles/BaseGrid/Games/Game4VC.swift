import UIKit
import SnapKit

final class Game4VC: UIViewController, GameCompletionProtocol {
    var onGameCompleted: (() -> Void)? 
    // MARK: - State
    private let selectedGridSizeKey = "Game4VC_SelectedGridSize"
    private let selectedImageKey = "Game4VC_SelectedImageName"
    
    // Сохраняем сетку в UserDefaults, чтобы она не сбрасывалась при перезапуске
    private var gridSize: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: selectedGridSizeKey)
            return saved == 0 ? 3 : saved
        }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedGridSizeKey)
            tiles.removeAll()
            tileButtons.removeAll()
        }
    }
    
    private var tiles: [Int] = []
    private var tileButtons: [Int: UIButton] = [:]
    private var isShuffling = false
    
    // Сохраняем выбранную картинку в UserDefaults
    private var currentImageName: String {
        get {
            return UserDefaults.standard.string(forKey: selectedImageKey) ?? "Preview1"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedImageKey)
        }
    }
    
    private var currentImage: UIImage? {
        return UIImage(named: currentImageName) ?? UIImage.gradientImage(
            colors: [BasePalitColors.primary, BasePalitColors.primaryGradientEnd, BasePalitColors.gold],
            size: CGSize(width: 600, height: 600)
        )
    }
    
    private var gameSaveKey: String {
        return String(describing: type(of: self)) + "_progress"
    }
    
    // Ключ завязан и на картинку, и на размер сетки
    private var boardSaveKey: String {
        return gameSaveKey + "_board_state_\(currentImageName)_\(gridSize)"
    }
    
    // MARK: - UI Elements
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    
    private let headerStack = UIStackView()
    private let difficultySegment = UISegmentedControl(items: ["3x3", "4x4", "5x5"])
    private let selectImageButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system)
    
    private let gameContainerView = UIView()
    private var boardContainerView: UIView?
    private var boardView: UIView?
    private var fullPreviewImageView: UIImageView?
    
    // Кастомный селектор картинок
    private let imagePickerOverlay = UIView()
    private let imagePickerCard = UIView()
    private let imagePickerCollectionView: UICollectionView

    // MARK: - Init
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        imagePickerCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        
        setupCustomNavigationBar()
        setupBaseUI()
        setupImagePickerOverlay()
        setupGame()
    }

    // MARK: - Setup UI
    private func setupCustomNavigationBar() {
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
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: backConfig)
        backButton.setImage(backImage, for: .normal)
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
    }
    
    private func setupBaseUI() {
        view.backgroundColor = BasePalitColors.background
        
        view.addSubview(gameContainerView)
        gameContainerView.backgroundColor = .clear
        gameContainerView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    private func setupTopControls() {
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        gameContainerView.addSubview(headerStack)
        
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(40)
        }
        
        difficultySegment.selectedSegmentIndex = gridSize == 3 ? 0 : (gridSize == 4 ? 1 : 2)
        difficultySegment.selectedSegmentTintColor = BasePalitColors.primary
        difficultySegment.setTitleTextAttributes([.foregroundColor: BasePalitColors.pureWhite], for: .selected)
        difficultySegment.setTitleTextAttributes([.foregroundColor: BasePalitColors.textSecondary], for: .normal)
        difficultySegment.backgroundColor = BasePalitColors.cardBackground
        difficultySegment.addTarget(self, action: #selector(difficultyChanged(_:)), for: .valueChanged)
        
        headerStack.addArrangedSubview(difficultySegment)
        difficultySegment.snp.makeConstraints { make in
            make.width.equalTo(130)
            make.height.equalTo(34)
        }
        
        var imgConfig = UIButton.Configuration.filled()
        imgConfig.title = "Image"
        imgConfig.image = UIImage(systemName: "photo.stack")
        imgConfig.imagePadding = 4
        imgConfig.baseBackgroundColor = BasePalitColors.cardBackground
        imgConfig.baseForegroundColor = BasePalitColors.textPrimary
        imgConfig.cornerStyle = .capsule
        
        selectImageButton.configuration = imgConfig
        selectImageButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        selectImageButton.layer.borderWidth = 1
        selectImageButton.layer.borderColor = BasePalitColors.separator.cgColor
        selectImageButton.layer.cornerRadius = 18
        selectImageButton.addTarget(self, action: #selector(openImagePicker), for: .touchUpInside)
        
        headerStack.addArrangedSubview(selectImageButton)
        selectImageButton.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        
        var previewConfig = UIButton.Configuration.filled()
        previewConfig.title = "Preview"
        previewConfig.image = UIImage(systemName: "eye.fill")
        previewConfig.imagePadding = 4
        previewConfig.baseBackgroundColor = BasePalitColors.cardBackground
        previewConfig.baseForegroundColor = BasePalitColors.textPrimary
        previewConfig.cornerStyle = .capsule
        
        previewButton.configuration = previewConfig
        previewButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        previewButton.layer.borderWidth = 1
        previewButton.layer.borderColor = BasePalitColors.separator.cgColor
        previewButton.layer.cornerRadius = 18
        previewButton.addTarget(self, action: #selector(previewPressed(_:)), for: [.touchDown, .touchUpInside, .touchUpOutside, .touchCancel])
        
        headerStack.addArrangedSubview(previewButton)
        previewButton.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
    }
    
    // MARK: - Custom Image Picker Overlay Setup
    private func setupImagePickerOverlay() {
        imagePickerOverlay.backgroundColor = BasePalitColors.pureBlack.withAlphaComponent(0.6)
        imagePickerOverlay.alpha = 0
        imagePickerOverlay.isHidden = true
        view.addSubview(imagePickerOverlay)
        
        imagePickerOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeImagePicker))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        imagePickerOverlay.addGestureRecognizer(tap)
        
        imagePickerCard.backgroundColor = BasePalitColors.cardBackground
        imagePickerCard.layer.cornerRadius = 24
        imagePickerCard.layer.borderWidth = 1
        imagePickerCard.layer.borderColor = BasePalitColors.separator.cgColor
        imagePickerOverlay.addSubview(imagePickerCard)
        
        imagePickerCard.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(380)
        }
        
        let titleLbl = UILabel()
        titleLbl.text = "Select Puzzle Image"
        titleLbl.font = .systemFont(ofSize: 18, weight: .bold)
        titleLbl.textColor = BasePalitColors.textPrimary
        titleLbl.textAlignment = .center
        imagePickerCard.addSubview(titleLbl)
        
        titleLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        imagePickerCollectionView.backgroundColor = .clear
        imagePickerCollectionView.dataSource = self
        imagePickerCollectionView.delegate = self
        imagePickerCollectionView.register(PuzzleImageCell.self, forCellWithReuseIdentifier: "PuzzleImageCell")
        imagePickerCard.addSubview(imagePickerCollectionView)
        
        imagePickerCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }
    
    @objc private func openImagePicker() {
        imagePickerCollectionView.reloadData()
        imagePickerOverlay.isHidden = false
        imagePickerCard.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut]) {
            self.imagePickerOverlay.alpha = 1.0
            self.imagePickerCard.transform = .identity
        }
    }
    
    @objc private func closeImagePicker() {
        UIView.animate(withDuration: 0.2, animations: {
            self.imagePickerOverlay.alpha = 0
            self.imagePickerCard.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.imagePickerOverlay.isHidden = true
            self.imagePickerCard.transform = .identity
        }
    }

    // MARK: - Game Logic Setup
    private func setupGame() {
        gameContainerView.subviews.forEach { $0.removeFromSuperview() }
        headerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tileButtons.removeAll()
        fullPreviewImageView = nil
        boardView = nil
        boardContainerView = nil
        
        setupTopControls()
        
        let totalTiles = gridSize * gridSize
        let boardSize = min(view.frame.width - 32, 380)
        
        let container = UIView()
        container.backgroundColor = .clear
        gameContainerView.addSubview(container)
        self.boardContainerView = container
        
        container.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(boardSize)
        }
        
        let board = UIView()
        board.backgroundColor = BasePalitColors.cardBackground
        board.layer.cornerRadius = 20
        board.layer.borderWidth = 3
        board.layer.borderColor = BasePalitColors.primary.cgColor
        board.layer.shadowColor = BasePalitColors.pureBlack.cgColor
        board.layer.shadowOffset = CGSize(width: 0, height: 8)
        board.layer.shadowOpacity = 0.4
        board.layer.shadowRadius = 12
        board.clipsToBounds = true
        container.addSubview(board)
        self.boardView = board
        
        board.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupSwipeGestures(on: container)
        
        // Восстанавливаем прогресс для текущей картинки и сетки
        if let savedTiles = UserDefaults.standard.array(forKey: boardSaveKey) as? [Int],
           savedTiles.count == totalTiles {
            tiles = savedTiles
            createTiles(in: board)
        } else {
            tiles = Array(0..<totalTiles)
            createTiles(in: board)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.shuffleTiles()
            }
        }
    }
    
    private func setupSwipeGestures(on targetView: UIView) {
        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right, .up, .down]
        for direction in directions {
            let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleBoardSwipe(_:)))
            recognizer.direction = direction
            targetView.addGestureRecognizer(recognizer)
        }
    }
    
    private func createTiles(in container: UIView) {
        guard let fullImage = currentImage else { return }
        
        let tileSize = 1.0 / CGFloat(gridSize)
        let totalTiles = gridSize * gridSize
        
        for i in 0..<totalTiles {
            if i == totalTiles - 1 { continue }
            
            let button = UIButton()
            button.backgroundColor = BasePalitColors.cardBackground
            button.tag = i
            button.layer.borderWidth = 1.5
            button.layer.borderColor = BasePalitColors.background.cgColor
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            
            let row = i / gridSize
            let col = i % gridSize
            let rect = CGRect(
                x: CGFloat(col) * tileSize,
                y: CGFloat(row) * tileSize,
                width: tileSize,
                height: tileSize
            )
            
            if let cropped = cropImage(fullImage, toRect: rect) {
                button.setImage(cropped, for: .normal)
                button.imageView?.contentMode = .scaleAspectFill
            }
            
            button.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
            container.addSubview(button)
            tileButtons[i] = button
        }
        
        updateTilePositions(animated: false)
    }
    
    // MARK: - Actions & Interactions
    @objc private func difficultyChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: gridSize = 3
        case 1: gridSize = 4
        case 2: gridSize = 5
        default: gridSize = 3
        }
        setupGame()
    }
    
    @objc private func tileTapped(_ sender: UIButton) {
        if isShuffling { return }
        moveTile(withIndex: sender.tag)
    }
    
    @objc private func handleBoardSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !isShuffling,
              let emptyPos = tiles.firstIndex(of: gridSize * gridSize - 1) else { return }
        
        let emptyRow = emptyPos / gridSize
        let emptyCol = emptyPos % gridSize
        
        var targetRow = emptyRow
        var targetCol = emptyCol
        
        switch gesture.direction {
        case .left:  targetCol = emptyCol + 1
        case .right: targetCol = emptyCol - 1
        case .up:    targetRow = emptyRow + 1
        case .down:  targetRow = emptyRow - 1
        default: break
        }
        
        if targetRow >= 0 && targetRow < gridSize && targetCol >= 0 && targetCol < gridSize {
            let targetPos = targetRow * gridSize + targetCol
            let tileIndex = tiles[targetPos]
            moveTile(withIndex: tileIndex)
        }
    }
    
    private func moveTile(withIndex tileIndex: Int) {
        guard let currentPos = tiles.firstIndex(of: tileIndex),
              let emptyPos = tiles.firstIndex(of: gridSize * gridSize - 1) else { return }
        
        if isAdjacent(pos1: currentPos, pos2: emptyPos) {
            tiles.swapAt(currentPos, emptyPos)
            
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            
            saveBoardState()
            
            if let button = tileButtons[tileIndex] {
                UIView.animate(withDuration: 0.1, animations: {
                    button.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
                }) { _ in
                    button.transform = .identity
                    self.updateTilePositions(animated: true)
                    self.checkWinCondition()
                }
            } else {
                updateTilePositions(animated: true)
                checkWinCondition()
            }
        }
    }
    
    @objc private func previewPressed(_ sender: UIButton) {
        guard let container = boardContainerView, let board = boardView, let fullImage = currentImage else { return }
        
        if fullPreviewImageView == nil {
            let imgView = UIImageView(image: fullImage)
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            imgView.layer.cornerRadius = 20
            imgView.alpha = 0
            container.addSubview(imgView)
            imgView.snp.makeConstraints { make in
                make.edges.equalTo(board)
            }
            fullPreviewImageView = imgView
        }
        
        let isHolding = (sender.isTracking && sender.isTouchInside)
        UIView.animate(withDuration: 0.25) {
            self.fullPreviewImageView?.alpha = isHolding ? 0.95 : 0.0
        }
    }
    
    private func isAdjacent(pos1: Int, pos2: Int) -> Bool {
        let row1 = pos1 / gridSize, col1 = pos1 % gridSize
        let row2 = pos2 / gridSize, col2 = pos2 % gridSize
        return abs(row1 - row2) + abs(col1 - col2) == 1
    }
    
    private func updateTilePositions(animated: Bool) {
        let boardSize = min(view.frame.width - 32, 380)
        let spacing: CGFloat = 2.0
        let effectiveSide = boardSize - spacing * CGFloat(gridSize + 1)
        let tileSide = effectiveSide / CGFloat(gridSize)
        
        for (pos, tileIndex) in tiles.enumerated() {
            guard let button = tileButtons[tileIndex] else { continue }
            
            let row = pos / gridSize
            let col = pos % gridSize
            
            let x = spacing + CGFloat(col) * (tileSide + spacing)
            let y = spacing + CGFloat(row) * (tileSide + spacing)
            
            let newFrame = CGRect(x: x, y: y, width: tileSide, height: tileSide)
            
            if animated {
                UIView.animate(
                    withDuration: 0.35,
                    delay: 0,
                    usingSpringWithDamping: 0.75,
                    initialSpringVelocity: 0.8,
                    options: [.beginFromCurrentState, .curveEaseInOut],
                    animations: {
                        button.frame = newFrame
                        button.transform = .identity
                    }
                )
            } else {
                button.frame = newFrame
            }
        }
    }
    
    private func shuffleTiles() {
        isShuffling = true
        let totalTilesCount = gridSize * gridSize
        let emptyValue = totalTilesCount - 1
        
        for _ in 0..<totalTilesCount * 20 {
            guard let emptyPos = tiles.firstIndex(of: emptyValue) else { break }
            var possibleMoves: [Int] = []
            
            let candidates = [emptyPos - gridSize, emptyPos + gridSize, emptyPos - 1, emptyPos + 1]
            for c in candidates {
                if c >= 0 && c < totalTilesCount {
                    if abs(c / gridSize - emptyPos / gridSize) + abs(c % gridSize - emptyPos % gridSize) == 1 {
                        possibleMoves.append(c)
                    }
                }
            }
            if let move = possibleMoves.randomElement() {
                tiles.swapAt(emptyPos, move)
            }
        }
        
        updateTilePositions(animated: true)
        saveBoardState()
        isShuffling = false
    }
    
    private func checkWinCondition() {
        let win = tiles.enumerated().allSatisfy { $0.offset == $0.element }
        if win {
            UserDefaults.standard.removeObject(forKey: boardSaveKey)
            playWinAnimation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.showWinAlert()
            }
        }
    }

    private func playWinAnimation() {
        guard let board = boardView else { return }
        
        UIView.animate(withDuration: 0.4) {
            board.layer.borderColor = BasePalitColors.gold.cgColor
            board.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                board.transform = .identity
            }
        }
        
        for (_, button) in tileButtons {
            UIView.animate(withDuration: 0.4) {
                button.layer.borderWidth = 0
                button.layer.cornerRadius = 0
            }
        }
    }
    
    private func showWinAlert() {
        if let onGameCompleted {
            onGameCompleted()
            return
        }
        
        let alert = UIAlertController(title: "Puzzle Solved!", message: "Congratulations! You completed the puzzle successfully.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: .default) { _ in
            self.setupGame()
        })
        present(alert, animated: true)
    }
    
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        let width = image.size.width * rect.width
        let height = image.size.height * rect.height
        let x = image.size.width * rect.origin.x
        let y = image.size.height * rect.origin.y
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return nil
    }
    
    private func saveBoardState() {
        UserDefaults.standard.set(tiles, forKey: boardSaveKey)
    }
    
    @objc private func dismissGame() {
        dismiss(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension Game4VC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let touchedView = touch.view, touchedView.isDescendant(of: imagePickerCard) {
            return false
        }
        return true
    }
}

// MARK: - UICollectionView DataSource & Delegate for Image Selection
extension Game4VC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9 // Preview1 - Preview9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PuzzleImageCell", for: indexPath) as! PuzzleImageCell
        let imageName = "Preview\(indexPath.row + 1)"
        let img = UIImage(named: imageName) ?? UIImage.gradientImage(colors: [BasePalitColors.primary, BasePalitColors.cardBackground], size: CGSize(width: 100, height: 100))
        cell.configure(with: img, isSelected: currentImageName == imageName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedName = "Preview\(indexPath.row + 1)"
        
        imagePickerOverlay.isHidden = true
        imagePickerOverlay.alpha = 0
        imagePickerCard.transform = .identity
        
        currentImageName = selectedName
        collectionView.reloadData()
        setupGame()
    }
}

// MARK: - Custom Cell for Image Preview Picker
private final class PuzzleImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = BasePalitColors.background
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with image: UIImage?, isSelected: Bool) {
        imageView.image = image
        contentView.layer.borderWidth = isSelected ? 3 : 1
        contentView.layer.borderColor = isSelected ? BasePalitColors.primary.cgColor : BasePalitColors.separator.cgColor
    }
}
