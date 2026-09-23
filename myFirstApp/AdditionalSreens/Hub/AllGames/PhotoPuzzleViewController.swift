import UIKit
import SnapKit

class PhotoPuzzleViewController: MiniGameAbstractVC {
    
    // MARK: - State
    private var gridSize: Int {
        return userScore < 3 ? 3 : 4
    }
    
    private var tiles: [Int] = []
    private var tileButtons: [Int: UIButton] = [:]
    private var isShuffling = false
    
    // MARK: - UI Elements
    private let headerStack = UIStackView()
    private let gridBadgeLabel = UILabel()
    private let previewButton = UIButton(type: .system)
    private var boardContainerView: UIView?
    private var boardView: UIView?
    private var fullPreviewImageView: UIImageView?
    
    override var gameRules: String {
        "PhotoPuzzle.INSTRUCTIONS".localize()
    }

    override func didResetProgress() {
        // При полном сбросе очков — принудительно чистим и поле
        UserDefaults.standard.removeObject(forKey: boardSaveKey)
        setupGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProgress()
        setupGame()
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
        
        UIView.transition(with: waifuImageView, duration: 0.8, options: .transitionCrossDissolve, animations: {
            self.waifuImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: imageName)
        }, completion: nil)
    }
    
    // MARK: - Game Setup
    private func setupGame() {
        // Жесткая зачистка всех прошлых элементов
        gameContainerView.subviews.forEach { $0.removeFromSuperview() }
        headerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tileButtons.removeAll()
        fullPreviewImageView = nil
        boardView = nil
        boardContainerView = nil
        
        setupTopControls()
        
        let totalTiles = gridSize * gridSize
        let boardSize = min(view.frame.width - 32, 340)
        
        // --- Board Container Styling ---
        let container = UIView()
        container.backgroundColor = .clear
        gameContainerView.addSubview(container)
        self.boardContainerView = container
        
        container.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(boardSize)
        }
        
        let board = UIView()
        board.backgroundColor = MyColors.cardBackground
        board.layer.cornerRadius = 20
        board.layer.borderWidth = 3
        board.layer.borderColor = MyColors.primary.cgColor
        board.layer.shadowColor = MyColors.pureBlack.cgColor
        board.layer.shadowOffset = CGSize(width: 0, height: 8)
        board.layer.shadowOpacity = 0.4
        board.layer.shadowRadius = 12
        board.clipsToBounds = true
        container.addSubview(board)
        self.boardView = board
        
        board.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 1. Проверяем, есть ли сохраненное состояние поля в UserDefaults
        if let savedTiles = UserDefaults.standard.array(forKey: boardSaveKey) as? [Int],
           savedTiles.count == totalTiles {
            // Если сохраненный массив совпадает по размеру сетки — восстанавливаем его
            tiles = savedTiles
            createTiles(in: board)
            // Важно: shuffleTiles() НЕ вызываем, поле уже в актуальном состоянии!
        } else {
            // 2. Если сохранения нет (новый уровень или сброс) — генерим дефолт и мешаем
            tiles = Array(0..<totalTiles)
            createTiles(in: board)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.shuffleTiles()
            }
        }
    }
    
    private func setupTopControls() {
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        gameContainerView.addSubview(headerStack)
        
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        
        // --- Grid Badge ---
        let gridTextKey = gridSize == 3 ? "PhotoPuzzle.Grid3x3" : "PhotoPuzzle.Grid4x4"
        gridBadgeLabel.text = " " + gridTextKey.localize() + "      "
        gridBadgeLabel.font = .systemFont(ofSize: 14, weight: .bold)
        gridBadgeLabel.textColor = MyColors.primary
        gridBadgeLabel.backgroundColor = MyColors.selectedOption
        gridBadgeLabel.layer.cornerRadius = 12
        gridBadgeLabel.layer.borderWidth = 1
        gridBadgeLabel.layer.borderColor = MyColors.primary.cgColor
        gridBadgeLabel.clipsToBounds = true
        gridBadgeLabel.textAlignment = .center
        
        let badgeContainer = UIView()
        badgeContainer.addSubview(gridBadgeLabel)
        gridBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12))
        }
        headerStack.addArrangedSubview(badgeContainer)
        
        // --- Preview Button ---
        var config = UIButton.Configuration.filled()
        config.title = "PhotoPuzzle.Preview".localize()
        config.image = UIImage(systemName: "eye.fill")
        config.imagePadding = 6
        config.baseBackgroundColor = MyColors.cardBackground
        config.baseForegroundColor = MyColors.textPrimary
        config.cornerStyle = .capsule
        
        previewButton.configuration = config
        previewButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        previewButton.layer.borderWidth = 1
        previewButton.layer.borderColor = MyColors.separator.cgColor
        previewButton.layer.cornerRadius = 18
        previewButton.addTarget(self, action: #selector(previewPressed), for: [.touchDown, .touchUpInside, .touchUpOutside, .touchCancel])
        
        headerStack.addArrangedSubview(previewButton)
    }
    
    private func createTiles(in container: UIView) {
        let currentImageName = userScore < 8 ? "AvatarForGeme\(userScore + 1)" : "AvatarForGeme8"
        guard let fullImage = MiniGamesPhotoCacheService.shared.getImage(named: currentImageName) else { return }
        
        let tileSize = 1.0 / CGFloat(gridSize)
        let totalTiles = gridSize * gridSize
        
        for i in 0..<totalTiles {
            if i == totalTiles - 1 { continue }
            
            let button = UIButton()
            button.backgroundColor = MyColors.cardBackground
            button.tag = i
            button.layer.borderWidth = 1.5
            button.layer.borderColor = MyColors.background.cgColor
            button.layer.cornerRadius = 8
            button.clipsToBounds = true
            
            let row = i / gridSize
            let col = i % gridSize
            let rect = CGRect(x: CGFloat(col) * tileSize,
                             y: CGFloat(row) * tileSize,
                             width: tileSize,
                             height: tileSize)
            
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
    
    // MARK: - Actions
    @objc private func tileTapped(_ sender: UIButton) {
        if isShuffling { return }
        
        let tileIndex = sender.tag
        guard let currentPos = tiles.firstIndex(of: tileIndex),
              let emptyPos = tiles.firstIndex(of: gridSize * gridSize - 1) else { return }
        
        if isAdjacent(pos1: currentPos, pos2: emptyPos) {
            tiles.swapAt(currentPos, emptyPos)
            
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            
            // Сохраняем состояние массива после каждого успешного хода
            saveBoardState()
            
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            }) { _ in
                sender.transform = .identity
                self.updateTilePositions(animated: true)
                self.checkWinCondition()
            }
        }
    }
    
    @objc private func previewPressed(_ sender: UIButton) {
        guard let container = boardContainerView, let board = boardView else { return }
        let currentImageName = userScore < 8 ? "AvatarForGeme\(userScore + 1)" : "AvatarForGeme8"
        guard let fullImage = MiniGamesPhotoCacheService.shared.getImage(named: currentImageName) else { return }
        
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
        let boardSize = min(view.frame.width - 32, 340)
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
                UIView.animate(withDuration: 0.35,
                               delay: 0,
                               usingSpringWithDamping: 0.75,
                               initialSpringVelocity: 0.8,
                               options: [.beginFromCurrentState, .curveEaseInOut],
                               animations: {
                    button.frame = newFrame
                    button.transform = .identity
                })
            } else {
                button.frame = newFrame
            }
        }
    }
    
    private func shuffleTiles() {
        isShuffling = true
        let totalTilesCount = gridSize * gridSize
        let emptyValue = totalTilesCount - 1
        
        for _ in 0..<totalTilesCount * 15 {
            let emptyPos = tiles.firstIndex(of: emptyValue)!
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
        // После первоначального перемешивания тоже фиксируем состояние в памяти
        saveBoardState()
        isShuffling = false
    }
    
    private func checkWinCondition() {
        let win = tiles.enumerated().allSatisfy { $0.offset == $0.element }
        if win {
            // Если выиграл — затираем сохранение поля, чтобы следующий уровень начался с перемешивания
            UserDefaults.standard.removeObject(forKey: boardSaveKey)
            
            playWinAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.updateScore(waifu: self.waifuScore, user: self.userScore + 1)
                self.setWaifuMessage("mini.game.aigf.texts14".localize())
                self.showWinAlert()
            }
        }
    }

    private func playWinAnimation() {
        guard let board = boardView else { return }
        
        UIView.animate(withDuration: 0.4) {
            board.layer.borderColor = MyColors.gold.cgColor
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
        let alert = UIAlertController(title: "mini.game.aigf.texts15".localize(), message: "mini.game.aigf.texts16".localize(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mini.game.aigf.texts17".localize(), style: .default) { _ in
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
    
    // MARK: - Save Helpers
    private func saveBoardState() {
        UserDefaults.standard.set(tiles, forKey: boardSaveKey)
    }
}
