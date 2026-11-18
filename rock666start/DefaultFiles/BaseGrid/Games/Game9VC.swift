import UIKit
import SnapKit

// MARK: - Private Models & Logic

private struct Board9Coord: Hashable {
    let layer: Int
    let row: Int
    let col: Int

    var hashKey: Int {
        Board9Coord.makeKey(layer: layer, row: row, col: col)
    }

    static func makeKey(layer: Int, row: Int, col: Int) -> Int {
        layer * 10_000 + row * 100 + col
    }
}

private struct Board9Piece {
    let coord: Board9Coord
    var glyphIndex: Int
    var isCleared = false
}

private struct Board9SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private enum Board9Solver {

    /// Pure Japanese Kanji pool (Nature, Elements, Directions, Traditional Concepts)
    static let glyphs: [String] = [
        "風", "林", "火", "山", "水", "空", "月", "星",
        "花", "雪", "雲", "雨", "霧", "雷", "光", "影",
        "東", "西", "南", "北", "春", "夏", "秋", "冬",
        "龍", "虎", "鶴", "亀", "狐", "桜", "竹", "松",
        "梅", "菊", "蓮", "楓", "波", "海", "川", "森",
        "心", "魂", "夢", "道", "誠", "静", "響", "雅",
        "縁", "絆", "和", "凛", "暁", "宵", "凪", "雫",
        "壱", "弐", "参", "肆", "伍", "陸", "漆", "捌"
    ]

    private static let maxLayers = 6

    static func glyphVariety(for stage: Int) -> Int {
        min(glyphs.count, 10 + (stage - 1) / 2)
    }

    static func isMovable(_ coord: Board9Coord, in occupied: Set<Int>) -> Bool {
        for layer in stride(from: coord.layer + 1, through: maxLayers, by: 1) {
            let key = Board9Coord.makeKey(layer: layer, row: coord.row, col: coord.col)
            if occupied.contains(key) { return false }
        }
        let leftBlocked = occupied.contains(Board9Coord.makeKey(layer: coord.layer, row: coord.row, col: coord.col - 1))
        let rightBlocked = occupied.contains(Board9Coord.makeKey(layer: coord.layer, row: coord.row, col: coord.col + 1))
        return !leftBlocked || !rightBlocked
    }

    static func generateStage(_ stage: Int) -> [Board9Piece] {
        var rng = Board9SeededRNG(seed: UInt64(max(1, stage)) &* 7919 &+ 17)
        let variety = glyphVariety(for: stage)

        for _ in 0..<100 {
            let coords = buildPyramid(stage: stage, using: &rng)
            if let assigned = assignGlyphs(coords: coords, variety: variety, attempts: 2, using: &rng) {
                return zip(coords, assigned).map { Board9Piece(coord: $0, glyphIndex: $1) }
            }
        }

        let fallbackCoords = buildGridStack(cols: 6, rows: 6, layers: 2)
        let assigned = assignGlyphs(coords: fallbackCoords, variety: variety, attempts: 50, using: &rng)
            ?? Array(repeating: 0, count: fallbackCoords.count)
        return zip(fallbackCoords, assigned).map { Board9Piece(coord: $0, glyphIndex: $1) }
    }

    static func assignGlyphs<G: RandomNumberGenerator>(
        coords: [Board9Coord],
        variety: Int,
        attempts: Int,
        using rng: inout G
    ) -> [Int]? {
        for _ in 0..<max(1, attempts) {
            if let result = tryReverseSolve(coords: coords, variety: variety, using: &rng) {
                return result
            }
        }
        return nil
    }

    private static func tryReverseSolve<G: RandomNumberGenerator>(
        coords: [Board9Coord],
        variety: Int,
        using rng: inout G
    ) -> [Int]? {
        let count = coords.count
        if count == 0 { return [] }
        guard count % 2 == 0, variety > 0 else { return nil }

        let actualVariety = min(variety, glyphs.count)
        let pairCount = count / 2

        var pool: [Int] = []
        pool.reserveCapacity(pairCount)
        for i in 0..<pairCount {
            pool.append(i % actualVariety)
        }
        pool.shuffle(using: &rng)

        var result = [Int](repeating: 0, count: count)
        var active = Set(0..<count)
        var occupied = Set(coords.map { $0.hashKey })
        var poolCursor = 0

        while !active.isEmpty {
            let free = active.sorted().filter { isMovable(coords[$0], in: occupied) }
            guard free.count >= 2 else { return nil }

            var chosen: (Int, Int)?
            for _ in 0..<15 {
                guard let first = free.randomElement(using: &rng) else { break }
                var second = first
                while second == first {
                    second = free.randomElement(using: &rng) ?? first
                }

                if active.count == 2 {
                    chosen = (first, second)
                    break
                }

                var nextOccupied = occupied
                nextOccupied.remove(coords[first].hashKey)
                nextOccupied.remove(coords[second].hashKey)
                let remainingFree = active.filter {
                    $0 != first && $0 != second && isMovable(coords[$0], in: nextOccupied)
                }.count

                if remainingFree >= 2 {
                    chosen = (first, second)
                    break
                }
            }

            guard let pair = chosen else { return nil }

            let glyph = pool[min(poolCursor, pool.count - 1)]
            result[pair.0] = glyph
            result[pair.1] = glyph
            poolCursor += 1

            active.remove(pair.0)
            active.remove(pair.1)
            occupied.remove(coords[pair.0].hashKey)
            occupied.remove(coords[pair.1].hashKey)
        }
        return result
    }

    private static func buildPyramid<G: RandomNumberGenerator>(stage: Int, using rng: inout G) -> [Board9Coord] {
        var targetCount = 48 + (stage * 4)
        if targetCount > 144 { targetCount = 144 }
        if targetCount % 2 != 0 { targetCount += 1 }

        let layerCap = min(maxLayers, 3 + (stage - 1) / 10)
        let dimensions = [(6, 6), (7, 6), (7, 7), (8, 7), (8, 8), (9, 8)]

        var coords = buildGridStack(
            cols: dimensions[dimensions.count - 1].0,
            rows: dimensions[dimensions.count - 1].1,
            layers: layerCap
        )
        for dim in dimensions {
            let candidate = buildGridStack(cols: dim.0, rows: dim.1, layers: layerCap)
            if candidate.count >= targetCount {
                coords = candidate
                break
            }
        }

        while coords.count > targetCount || coords.count % 2 != 0 {
            let topLayer = coords.map { $0.layer }.max() ?? 0
            let topIndices = coords.indices.filter { coords[$0].layer == topLayer }
            guard let removeIdx = topIndices.randomElement(using: &rng) else { break }
            coords.remove(at: removeIdx)
        }
        return coords
    }

    private static func buildGridStack(cols: Int, rows: Int, layers: Int) -> [Board9Coord] {
        var cells = Set<Int>()
        for r in 0..<rows {
            for c in 0..<cols {
                cells.insert(r * 100 + c)
            }
        }

        var output: [Board9Coord] = []
        for layer in 0..<layers {
            if cells.isEmpty { break }
            for cell in cells.sorted() {
                output.append(Board9Coord(layer: layer, row: cell / 100, col: cell % 100))
            }
            let snapshot = cells
            cells = snapshot.filter { cell in
                [cell - 100, cell + 100, cell - 1, cell + 1].allSatisfy { snapshot.contains($0) }
            }
        }
        return output
    }
}

// MARK: - Piece View

private final class Board9PieceView: UIView {

    enum VisualState {
        case available
        case locked
        case active
        case suggested
    }

    private let baseExtrusionView = UIView()
    private let cardFaceView = UIView()
    private let innerFrameView = UIView()
    private let kanjiLabel = UILabel()

    init(glyph: String, size: CGSize, extrusion: CGFloat) {
        super.init(frame: CGRect(origin: .zero, size: size))
        let cornerRadius = size.width * 0.2

        baseExtrusionView.frame = CGRect(
            x: extrusion * 0.65,
            y: extrusion,
            width: size.width,
            height: size.height
        )
        baseExtrusionView.layer.cornerRadius = cornerRadius
        baseExtrusionView.layer.shadowColor = BasePalitColors.pureBlack.cgColor
        baseExtrusionView.layer.shadowOpacity = 0.55
        baseExtrusionView.layer.shadowOffset = CGSize(width: 1, height: 3)
        baseExtrusionView.layer.shadowRadius = 4
        baseExtrusionView.layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(origin: .zero, size: size),
            cornerRadius: cornerRadius
        ).cgPath

        cardFaceView.frame = bounds
        cardFaceView.layer.cornerRadius = cornerRadius
        cardFaceView.clipsToBounds = true

        let inset = max(3, size.width * 0.08)
        innerFrameView.frame = bounds.insetBy(dx: inset, dy: inset)
        innerFrameView.layer.cornerRadius = max(4, cornerRadius - inset * 0.5)
        innerFrameView.layer.borderWidth = 1
        innerFrameView.isUserInteractionEnabled = false

        kanjiLabel.frame = bounds
        kanjiLabel.text = glyph
        kanjiLabel.textAlignment = .center
        kanjiLabel.font = UIFont(name: "HiraginoMinchoProN-W6", size: size.width * 0.52)
            ?? .systemFont(ofSize: size.width * 0.52, weight: .bold)

        addSubview(baseExtrusionView)
        addSubview(cardFaceView)
        cardFaceView.addSubview(innerFrameView)
        cardFaceView.addSubview(kanjiLabel)

        applyState(.locked, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateGlyph(_ glyph: String) {
        kanjiLabel.text = glyph
    }

    func applyState(_ state: VisualState, animated: Bool) {
        let faceBg: UIColor
        let baseBg: UIColor
        let outerBorder: UIColor
        let innerBorder: UIColor
        let textColor: UIColor
        let borderWidth: CGFloat
        let scale: CGFloat

        switch state {
        case .available:
            faceBg = BasePalitColors.tile4
            baseBg = BasePalitColors.cardBackground
            outerBorder = BasePalitColors.separator
            innerBorder = BasePalitColors.textPrimary.withAlphaComponent(0.08)
            textColor = BasePalitColors.textPrimary
            borderWidth = 1.2
            scale = 1.0
        case .locked:
            faceBg = BasePalitColors.messageBackground
            baseBg = BasePalitColors.background
            outerBorder = BasePalitColors.separator.withAlphaComponent(0.45)
            innerBorder = BasePalitColors.clearAccent
            textColor = BasePalitColors.textSecondary.withAlphaComponent(0.35)
            borderWidth = 1.0
            scale = 1.0
        case .active:
            faceBg = BasePalitColors.primary
            baseBg = BasePalitColors.primaryGradientEnd
            outerBorder = BasePalitColors.pureWhite
            innerBorder = BasePalitColors.pureWhite.withAlphaComponent(0.35)
            textColor = BasePalitColors.pureWhite
            borderWidth = 2.0
            scale = 1.08
        case .suggested:
            faceBg = BasePalitColors.tile4
            baseBg = BasePalitColors.primaryGradientEnd
            outerBorder = BasePalitColors.gold
            innerBorder = BasePalitColors.gold.withAlphaComponent(0.45)
            textColor = BasePalitColors.gold
            borderWidth = 2.2
            scale = 1.05
        }

        cardFaceView.layer.borderColor = outerBorder.cgColor
        cardFaceView.layer.borderWidth = borderWidth
        innerFrameView.layer.borderColor = innerBorder.cgColor

        let updates = {
            self.cardFaceView.backgroundColor = faceBg
            self.baseExtrusionView.backgroundColor = baseBg
            self.kanjiLabel.textColor = textColor
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }

        if animated {
            UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut], animations: updates)
        } else {
            updates()
        }
    }

    func playInvalidTap() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-5, 5, -4, 4, -2, 2, 0]
        animation.duration = 0.28
        layer.add(animation, forKey: "invalidTap")
    }

    func playMatchDisappear() {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn], animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.45, y: 0.45)
        }, completion: { _ in
            self.isHidden = true
        })
    }

    func playShuffleFlip() {
        UIView.transition(with: self, duration: 0.32, options: .transitionFlipFromLeft, animations: nil)
    }
}

private extension BasePalitColors {
    static var clearAccent: UIColor { .clear }
}

// MARK: - Stage Clear Overlay

private final class Board9ClearOverlay: UIView {

    var onAdvanceStage: (() -> Void)?
    var onReplayStage: (() -> Void)?

    private let panelView = UIView()

    init(stage: Int, isMaxStage: Bool) {
        super.init(frame: .zero)
        backgroundColor = BasePalitColors.background.withAlphaComponent(0.86)

        panelView.backgroundColor = BasePalitColors.cardBackground
        panelView.layer.cornerRadius = 24
        panelView.layer.borderWidth = 1
        panelView.layer.borderColor = BasePalitColors.separator.cgColor
        addSubview(panelView)

        let emblemContainer = UIView()
        emblemContainer.backgroundColor = BasePalitColors.selectedOption
        emblemContainer.layer.cornerRadius = 34
        emblemContainer.layer.borderWidth = 1
        emblemContainer.layer.borderColor = BasePalitColors.primary.withAlphaComponent(0.5).cgColor

        let emblemLabel = UILabel()
        emblemLabel.text = "勝"
        emblemLabel.font = UIFont(name: "HiraginoMinchoProN-W6", size: 32)
            ?? .systemFont(ofSize: 32, weight: .bold)
        emblemLabel.textColor = BasePalitColors.primary
        emblemLabel.textAlignment = .center
        emblemContainer.addSubview(emblemLabel)

        let headingLabel = UILabel()
        headingLabel.text = isMaxStage ? "Mastery Achieved" : "Board Cleared"
        headingLabel.font = .systemFont(ofSize: 24, weight: .bold)
        headingLabel.textColor = BasePalitColors.textPrimary
        headingLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.text = isMaxStage
            ? "You have completed the highest difficulty stage."
            : "Stage \(stage) solved. Ready to increase the difficulty?"
        descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = BasePalitColors.textSecondary
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        let nextStageButton = UIButton(type: .system)
        nextStageButton.setTitle(isMaxStage ? "Play Again" : "Next Stage (\(stage + 1))", for: .normal)
        nextStageButton.setTitleColor(BasePalitColors.pureWhite, for: .normal)
        nextStageButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        nextStageButton.backgroundColor = BasePalitColors.primaryButtonBackground
        nextStageButton.layer.cornerRadius = 14
        nextStageButton.addTarget(self, action: #selector(handlePrimaryTap), for: .touchUpInside)

        let replayButton = UIButton(type: .system)
        replayButton.setTitle("Replay Stage \(stage)", for: .normal)
        replayButton.setTitleColor(BasePalitColors.textPrimary, for: .normal)
        replayButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        replayButton.backgroundColor = BasePalitColors.unselectedOption
        replayButton.layer.cornerRadius = 14
        replayButton.layer.borderWidth = 1
        replayButton.layer.borderColor = BasePalitColors.separator.cgColor
        replayButton.addTarget(self, action: #selector(handleSecondaryTap), for: .touchUpInside)

        let emblemWrapper = UIView()
        emblemWrapper.addSubview(emblemContainer)
        emblemContainer.snp.makeConstraints { make in
            make.center.top.bottom.equalToSuperview()
            make.size.equalTo(68)
        }
        emblemLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let stack = UIStackView(arrangedSubviews: [
            emblemWrapper,
            headingLabel,
            descriptionLabel,
            nextStageButton,
            replayButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(16, after: emblemWrapper)
        stack.setCustomSpacing(6, after: headingLabel)
        stack.setCustomSpacing(20, after: descriptionLabel)
        panelView.addSubview(stack)

        panelView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(28)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(22)
        }
        nextStageButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        replayButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentAnimated() {
        alpha = 0
        panelView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0) {
            self.alpha = 1
            self.panelView.transform = .identity
        }
    }

    @objc private func handlePrimaryTap() { onAdvanceStage?() }
    @objc private func handleSecondaryTap() { onReplayStage?() }
}

// MARK: - Main Game View Controller

final class Game9VC: UIViewController {

    // MARK: Configuration & State
    private let minStage = 1
    private let maxStage = 100
    private var currentStage: Int = 1

    private var pieces: [Board9Piece] = []
    private var pieceViews: [Board9PieceView] = []
    private var selectedPieceIndex: Int?
    private var suggestedIndices: Set<Int> = []
    private var suggestionWorkItem: DispatchWorkItem?
    private var isStageCompleted = false
    private var renderedViewportWidth: CGFloat = 0
    private var clearOverlay: Board9ClearOverlay?

    // MARK: UI Components
    private let topBarCard: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.separator.cgColor
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = BasePalitColors.textPrimary
        button.backgroundColor = BasePalitColors.unselectedOption
        button.layer.cornerRadius = 18
        button.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        return button
    }()

    private lazy var decreaseStageButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = BasePalitColors.textPrimary
        button.backgroundColor = BasePalitColors.unselectedOption
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(handleDecreaseStage), for: .touchUpInside)
        return button
    }()

    private lazy var increaseStageButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = BasePalitColors.textPrimary
        button.backgroundColor = BasePalitColors.unselectedOption
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(handleIncreaseStage), for: .touchUpInside)
        return button
    }()

    private let stageTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = BasePalitColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let difficultyTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = BasePalitColors.primary
        label.textAlignment = .center
        return label
    }()

    private let infoDivider: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.separator
        return view
    }()

    private let remainingCountLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = BasePalitColors.textSecondary
        label.textAlignment = .left
        return label
    }()

    private let availablePairsLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        label.textColor = BasePalitColors.textSecondary
        label.textAlignment = .right
        return label
    }()

    private let progressTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.progressBackground
        view.layer.cornerRadius = 2.5
        view.clipsToBounds = true
        return view
    }()

    private let progressFillView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.progressForeground
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let boardScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()

    private let boardCanvasView = UIView()

    private lazy var hintActionButton = createBottomAction(
        title: "Hint",
        iconName: "sparkles",
        action: #selector(handleHintTap)
    )

    private lazy var shuffleActionButton = createBottomAction(
        title: "Shuffle",
        iconName: "shuffle",
        action: #selector(handleShuffleTap)
    )

    private lazy var resetActionButton = createBottomAction(
        title: "Reset",
        iconName: "arrow.counterclockwise",
        action: #selector(handleResetTap)
    )

    // MARK: Lifecycle
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BasePalitColors.background
        configureHierarchy()
        loadStage(currentStage)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = boardScrollView.bounds.width
        if width > 0, abs(width - renderedViewportWidth) > 0.5 {
            layoutBoardPieces()
        }
    }

    // MARK: Layout Setup
    private func configureHierarchy() {
        view.addSubview(topBarCard)
        topBarCard.addSubview(closeButton)
        topBarCard.addSubview(decreaseStageButton)
        topBarCard.addSubview(stageTitleLabel)
        topBarCard.addSubview(difficultyTagLabel)
        topBarCard.addSubview(increaseStageButton)
        topBarCard.addSubview(infoDivider)
        topBarCard.addSubview(remainingCountLabel)
        topBarCard.addSubview(availablePairsLabel)
        topBarCard.addSubview(progressTrackView)
        progressTrackView.addSubview(progressFillView)

        view.addSubview(boardScrollView)
        boardScrollView.addSubview(boardCanvasView)

        let controlsStack = UIStackView(arrangedSubviews: [
            hintActionButton,
            shuffleActionButton,
            resetActionButton
        ])
        controlsStack.axis = .horizontal
        controlsStack.spacing = 10
        controlsStack.distribution = .fillEqually
        view.addSubview(controlsStack)

        topBarCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(36)
        }

        increaseStageButton.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(32)
        }

        decreaseStageButton.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.leading.equalTo(closeButton.snp.trailing).offset(12)
            make.size.equalTo(32)
        }

        stageTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.leading.equalTo(decreaseStageButton.snp.trailing).offset(8)
            make.trailing.equalTo(increaseStageButton.snp.leading).offset(-8)
        }

        difficultyTagLabel.snp.makeConstraints { make in
            make.top.equalTo(stageTitleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(stageTitleLabel)
        }

        infoDivider.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(1)
        }

        remainingCountLabel.snp.makeConstraints { make in
            make.top.equalTo(infoDivider.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(14)
        }

        availablePairsLabel.snp.makeConstraints { make in
            make.centerY.equalTo(remainingCountLabel)
            make.trailing.equalToSuperview().inset(14)
            make.leading.greaterThanOrEqualTo(remainingCountLabel.snp.trailing).offset(8)
        }

        progressTrackView.snp.makeConstraints { make in
            make.top.equalTo(remainingCountLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(5)
            make.bottom.equalToSuperview().inset(12)
        }

        progressFillView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        controlsStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(12)
            make.height.equalTo(50)
        }

        boardScrollView.snp.makeConstraints { make in
            make.top.equalTo(topBarCard.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(controlsStack.snp.top).offset(-10)
        }

        boardCanvasView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(1)
        }
    }

    private func createBottomAction(title: String, iconName: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: iconName)
        config.imagePadding = 6
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        config.baseBackgroundColor = BasePalitColors.cardBackground
        config.baseForegroundColor = BasePalitColors.textPrimary
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = BasePalitColors.separator.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: Stage Lifecycle
    private func loadStage(_ stage: Int) {
        currentStage = min(max(minStage, stage), maxStage)
        clearOverlay?.removeFromSuperview()
        clearOverlay = nil
        isStageCompleted = false
        selectedPieceIndex = nil
        suggestionWorkItem?.cancel()
        suggestedIndices = []

        pieces = Board9Solver.generateStage(currentStage)
        boardScrollView.setContentOffset(.zero, animated: false)
        layoutBoardPieces()
        updateHeaderMetrics()
    }

    private func layoutBoardPieces() {
        pieceViews.forEach { $0.removeFromSuperview() }
        pieceViews.removeAll()
        suggestedIndices = []

        let viewport = boardScrollView.bounds.size
        guard viewport.width > 0, !pieces.isEmpty else { return }
        renderedViewportWidth = viewport.width

        let coords = pieces.map { $0.coord }
        let minCol = coords.map { $0.col }.min() ?? 0
        let maxCol = coords.map { $0.col }.max() ?? 0
        let minRow = coords.map { $0.row }.min() ?? 0
        let maxRow = coords.map { $0.row }.max() ?? 0
        let maxLayer = coords.map { $0.layer }.max() ?? 0

        let colSpan = CGFloat(maxCol - minCol + 1)
        let rowSpan = CGFloat(maxRow - minRow + 1)

        let extrusion: CGFloat = 5
        let layerOffset: CGFloat = 5
        let spacing: CGFloat = 2.5
        let margin: CGFloat = 16
        let stackShift = CGFloat(maxLayer) * layerOffset

        let availableWidth = viewport.width - margin * 2 - stackShift - extrusion
        let pieceWidth = min(56, floor((availableWidth - spacing * (colSpan - 1)) / colSpan))
        let pieceHeight = floor(pieceWidth * 1.28)
        let stepX = pieceWidth + spacing
        let stepY = pieceHeight + spacing + 2

        let totalBoardWidth = margin * 2 + stackShift + extrusion + (colSpan - 1) * stepX + pieceWidth
        let totalBoardHeight = margin * 2 + stackShift + extrusion + (rowSpan - 1) * stepY + pieceHeight
        let canvasWidth = max(totalBoardWidth, viewport.width)
        let canvasHeight = max(totalBoardHeight, viewport.height)

        let startX = (canvasWidth - totalBoardWidth) / 2 + margin + stackShift
        let startY = (canvasHeight - totalBoardHeight) / 2 + margin + stackShift

        boardCanvasView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(canvasWidth)
            make.height.equalTo(canvasHeight)
        }

        let sortedIndices = pieces.indices.sorted { a, b in
            let p1 = pieces[a].coord
            let p2 = pieces[b].coord
            if p1.layer != p2.layer { return p1.layer < p2.layer }
            if p1.row != p2.row { return p1.row < p2.row }
            return p1.col < p2.col
        }

        var buffer = [Board9PieceView?](repeating: nil, count: pieces.count)
        for index in sortedIndices {
            let item = pieces[index]
            let pieceView = Board9PieceView(
                glyph: Board9Solver.glyphs[item.glyphIndex],
                size: CGSize(width: pieceWidth, height: pieceHeight),
                extrusion: extrusion
            )
            pieceView.frame = CGRect(
                x: startX + CGFloat(item.coord.col - minCol) * stepX - CGFloat(item.coord.layer) * layerOffset,
                y: startY + CGFloat(item.coord.row - minRow) * stepY - CGFloat(item.coord.layer) * layerOffset,
                width: pieceWidth,
                height: pieceHeight
            )
            pieceView.tag = index
            pieceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePieceTap(_:))))
            pieceView.isHidden = item.isCleared
            boardCanvasView.addSubview(pieceView)
            buffer[index] = pieceView
        }

        pieceViews = buffer.compactMap { $0 }
        syncPieceStates()
    }

    // MARK: Board Queries & Updates
    private func occupiedHashSet() -> Set<Int> {
        Set(pieces.filter { !$0.isCleared }.map { $0.coord.hashKey })
    }

    private func movablePieceIndices() -> [Int] {
        let occupied = occupiedHashSet()
        return pieces.indices.filter {
            !pieces[$0].isCleared && Board9Solver.isMovable(pieces[$0].coord, in: occupied)
        }
    }

    private func validMatchPairs() -> [[Int]] {
        Dictionary(grouping: movablePieceIndices(), by: { pieces[$0].glyphIndex })
            .values
            .filter { $0.count >= 2 }
            .map { $0.sorted() }
    }

    private func syncPieceStates() {
        guard pieceViews.count == pieces.count else { return }
        let occupied = occupiedHashSet()
        for (index, item) in pieces.enumerated() where !item.isCleared {
            let state: Board9PieceView.VisualState
            if selectedPieceIndex == index {
                state = .active
            } else if suggestedIndices.contains(index) {
                state = .suggested
            } else if Board9Solver.isMovable(item.coord, in: occupied) {
                state = .available
            } else {
                state = .locked
            }
            pieceViews[index].applyState(state, animated: true)
        }
    }

    private func difficultyDescription(for stage: Int) -> String {
        switch stage {
        case 1...5: return "NOVICE • \(Board9Solver.glyphVariety(for: stage)) KANJI"
        case 6...15: return "ADEPT • \(Board9Solver.glyphVariety(for: stage)) KANJI"
        case 16...35: return "MASTER • \(Board9Solver.glyphVariety(for: stage)) KANJI"
        default: return "GRANDMASTER • \(Board9Solver.glyphVariety(for: stage)) KANJI"
        }
    }

    private func updateHeaderMetrics() {
        let totalCount = max(1, pieces.count)
        let remaining = pieces.filter { !$0.isCleared }.count
        let cleared = totalCount - remaining
        let pairCombinations = validMatchPairs().reduce(0) { $0 + $1.count * ($1.count - 1) / 2 }

        stageTitleLabel.text = "Stage \(currentStage)"
        difficultyTagLabel.text = difficultyDescription(for: currentStage)
        remainingCountLabel.text = "Tiles: \(remaining)/\(totalCount)"
        availablePairsLabel.text = "Moves: \(pairCombinations)"

        decreaseStageButton.isEnabled = currentStage > minStage
        decreaseStageButton.alpha = currentStage > minStage ? 1.0 : 0.4
        increaseStageButton.isEnabled = currentStage < maxStage
        increaseStageButton.alpha = currentStage < maxStage ? 1.0 : 0.4

        let ratio = CGFloat(cleared) / CGFloat(totalCount)
        progressFillView.snp.remakeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(progressTrackView.snp.width).multipliedBy(ratio)
        }
        UIView.animate(withDuration: 0.25) {
            self.topBarCard.layoutIfNeeded()
        }
    }

    private func dismissSuggestion() {
        suggestionWorkItem?.cancel()
        if !suggestedIndices.isEmpty {
            suggestedIndices = []
            syncPieceStates()
        }
    }

    // MARK: Gameplay Interaction
    @objc private func handlePieceTap(_ gesture: UITapGestureRecognizer) {
        guard !isStageCompleted, let tappedView = gesture.view as? Board9PieceView else { return }
        let idx = tappedView.tag
        guard pieces.indices.contains(idx), !pieces[idx].isCleared else { return }

        dismissSuggestion()

        guard Board9Solver.isMovable(pieces[idx].coord, in: occupiedHashSet()) else {
            tappedView.playInvalidTap()
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard let currentSelected = selectedPieceIndex else {
            selectedPieceIndex = idx
            syncPieceStates()
            return
        }

        if currentSelected == idx {
            selectedPieceIndex = nil
            syncPieceStates()
            return
        }

        if pieces[currentSelected].glyphIndex == pieces[idx].glyphIndex {
            pieces[currentSelected].isCleared = true
            pieces[idx].isCleared = true
            pieceViews[currentSelected].playMatchDisappear()
            pieceViews[idx].playMatchDisappear()
            selectedPieceIndex = nil
            syncPieceStates()
            updateHeaderMetrics()
            checkBoardStatus()
        } else {
            selectedPieceIndex = idx
            syncPieceStates()
        }
    }

    private func checkBoardStatus() {
        if pieces.allSatisfy({ $0.isCleared }) {
            completeCurrentStage()
        } else if validMatchPairs().isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.showNoMovesPrompt()
            }
        }
    }

    private func completeCurrentStage() {
        isStageCompleted = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            let overlay = Board9ClearOverlay(
                stage: self.currentStage,
                isMaxStage: self.currentStage >= self.maxStage
            )
            overlay.onAdvanceStage = { [weak self] in
                guard let self = self else { return }
                let next = self.currentStage < self.maxStage ? self.currentStage + 1 : 1
                self.loadStage(next)
            }
            overlay.onReplayStage = { [weak self] in
                guard let self = self else { return }
                self.loadStage(self.currentStage)
            }
            self.view.addSubview(overlay)
            overlay.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.view.layoutIfNeeded()
            overlay.presentAnimated()
            self.clearOverlay = overlay
        }
    }

    @discardableResult
    private func reshuffleRemainingPieces() -> Bool {
        let activeIndices = pieces.indices.filter { !pieces[$0].isCleared }
        let activeCoords = activeIndices.map { pieces[$0].coord }
        var rng = SystemRandomNumberGenerator()

        guard let reassigned = Board9Solver.assignGlyphs(
            coords: activeCoords,
            variety: Board9Solver.glyphVariety(for: currentStage),
            attempts: 300,
            using: &rng
        ) else {
            showDeadlockPrompt()
            return false
        }

        for (offset, index) in activeIndices.enumerated() {
            pieces[index].glyphIndex = reassigned[offset]
            pieceViews[index].updateGlyph(Board9Solver.glyphs[reassigned[offset]])
            pieceViews[index].playShuffleFlip()
        }
        selectedPieceIndex = nil
        suggestedIndices = []
        syncPieceStates()
        updateHeaderMetrics()
        return true
    }

    // MARK: Alerts
    private func presentDarkAlert(_ alert: UIAlertController) {
        alert.overrideUserInterfaceStyle = .dark
        alert.view.tintColor = BasePalitColors.primary
        present(alert, animated: true)
    }

    private func showNoMovesPrompt() {
        guard presentedViewController == nil, !isStageCompleted else { return }
        let alert = UIAlertController(
            title: "No Available Pairs",
            message: "No matching free tiles remain. Shuffle the board to continue playing.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Shuffle Tiles", style: .default) { [weak self] _ in
            self?.reshuffleRemainingPieces()
        })
        alert.addAction(UIAlertAction(title: "Reset Stage", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.loadStage(self.currentStage)
        })
        presentDarkAlert(alert)
    }

    private func showDeadlockPrompt() {
        guard presentedViewController == nil, !isStageCompleted else { return }
        let alert = UIAlertController(
            title: "Board Locked",
            message: "The remaining stack cannot be resolved. Reset the stage to try a fresh layout.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Reset Stage", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.loadStage(self.currentStage)
        })
        presentDarkAlert(alert)
    }

    // MARK: Control Actions
    @objc private func handleDecreaseStage() {
        guard currentStage > minStage else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        loadStage(currentStage - 1)
    }

    @objc private func handleIncreaseStage() {
        guard currentStage < maxStage else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        loadStage(currentStage + 1)
    }

    @objc private func handleHintTap() {
        guard !isStageCompleted else { return }
        dismissSuggestion()

        var targetPair: [Int]?
        if let selected = selectedPieceIndex,
           let partner = movablePieceIndices().first(where: { $0 != selected && pieces[$0].glyphIndex == pieces[selected].glyphIndex }) {
            targetPair = [selected, partner]
        } else if let group = validMatchPairs().first {
            targetPair = Array(group.prefix(2))
        }

        guard let pair = targetPair else {
            showNoMovesPrompt()
            return
        }

        suggestedIndices = Set(pair)
        syncPieceStates()

        let work = DispatchWorkItem { [weak self] in
            self?.suggestedIndices = []
            self?.syncPieceStates()
        }
        suggestionWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    @objc private func handleShuffleTap() {
        guard !isStageCompleted else { return }
        dismissSuggestion()
        reshuffleRemainingPieces()
    }

    @objc private func handleResetTap() {
        loadStage(currentStage)
    }

    @objc private func handleCloseTap() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
