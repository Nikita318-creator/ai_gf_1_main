import UIKit
import SnapKit

// MARK: - Role Category Enum
enum RoleCategory: Int, CaseIterable {
    case real
    case anime
    case milf
    case ex
    
    var title: String {
        switch self {
        case .real: return "Real"
        case .anime: return "Anime"
        case .milf: return "Mature"
        case .ex: return "Ex GF"
        }
    }
}

class ExploreVC: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let createGfButton = UIButton(type: .system)
    private let segmentedControl = UISegmentedControl()
    private let collectionView: UICollectionView
    
    // MARK: - Selected Category
    private var currentCategory: RoleCategory = .real {
        didSet {
            updateRolesForCurrentCategory()
        }
    }
    
    // MARK: - Data
    private var roles: [RoleplayModel] = []
    
    private var realRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 1, name: "character.name1".localize(), image: "mainAvatar1", assistantInfo: "GFBaseInfo1".localize()),
            RoleplayModel(id: 2, name: "character.name2".localize(), image: "mainAvatar2", assistantInfo: "GFBaseInfo2".localize()),
            RoleplayModel(id: 27, name: "character.name27".localize(), image: "mainAvatar27", assistantInfo: "GFBaseInfo27".localize()),
            RoleplayModel(id: 28, name: "character.name28".localize(), image: "mainAvatar28", assistantInfo: "GFBaseInfo28".localize()),
            RoleplayModel(id: 3, name: "character.name3".localize(), image: "mainAvatar3", assistantInfo: "GFBaseInfo3".localize()),
            RoleplayModel(id: 4, name: "character.name4".localize(), image: "mainAvatar4", assistantInfo: "GFBaseInfo4".localize()),
            RoleplayModel(id: 5, name: "character.name5".localize(), image: "mainAvatar5", assistantInfo: "GFBaseInfo5".localize()),
            RoleplayModel(id: 6, name: "character.name6".localize(), image: "mainAvatar6", assistantInfo: "GFBaseInfo6".localize()),
            RoleplayModel(id: 7, name: "character.name7".localize(), image: "mainAvatar7", assistantInfo: "GFBaseInfo7".localize()),
            RoleplayModel(id: 8, name: "character.name8".localize(), image: "mainAvatar8", assistantInfo: "GFBaseInfo8".localize()),
            RoleplayModel(id: 9, name: "character.name9".localize(), image: "mainAvatar9", assistantInfo: "GFBaseInfo9".localize()),
            RoleplayModel(id: 10, name: "character.name10".localize(), image: "mainAvatar10", assistantInfo: "GFBaseInfo10".localize()),
        ]
    }
    
    private var animeRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 11, name: "character.name11".localize(), image: "mainAvatar11", assistantInfo: "GFBaseInfo11".localize()),
            RoleplayModel(id: 12, name: "character.name12".localize(), image: "mainAvatar12", assistantInfo: "GFBaseInfo12".localize()),
            RoleplayModel(id: 13, name: "character.name13".localize(), image: "mainAvatar13", assistantInfo: "GFBaseInfo13".localize()),
            RoleplayModel(id: 14, name: "character.name14".localize(), image: "mainAvatar14", assistantInfo: "GFBaseInfo14".localize()),
            RoleplayModel(id: 15, name: "character.name15".localize(), image: "mainAvatar15", assistantInfo: "GFBaseInfo15".localize()),
            RoleplayModel(id: 16, name: "character.name16".localize(), image: "mainAvatar16", assistantInfo: "GFBaseInfo16".localize()),
            RoleplayModel(id: 17, name: "character.name17".localize(), image: "mainAvatar17", assistantInfo: "GFBaseInfo17".localize()),
            RoleplayModel(id: 18, name: "character.name18".localize(), image: "mainAvatar18", assistantInfo: "GFBaseInfo18".localize()),
            RoleplayModel(id: 19, name: "character.name19".localize(), image: "mainAvatar19", assistantInfo: "GFBaseInfo19".localize()),
            RoleplayModel(id: 20, name: "character.name20".localize(), image: "mainAvatar20", assistantInfo: "GFBaseInfo20".localize())
        ]
    }
    
    private var milfRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 21, name: "character.name21".localize(), image: "mainAvatar21", assistantInfo: "GFBaseInfo21".localize()),
            RoleplayModel(id: 22, name: "character.name22".localize(), image: "mainAvatar22", assistantInfo: "GFBaseInfo22".localize()),
            RoleplayModel(id: 23, name: "character.name23".localize(), image: "mainAvatar23", assistantInfo: "GFBaseInfo23".localize()),
            RoleplayModel(id: 24, name: "character.name24".localize(), image: "mainAvatar24", assistantInfo: "GFBaseInfo24".localize()),
            RoleplayModel(id: 25, name: "character.name25".localize(), image: "mainAvatar25", assistantInfo: "GFBaseInfo25".localize()),
        ]
    }
    
    private var exRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 26, name: "character.name26".localize(), image: "mainAvatar26", assistantInfo: "GFBaseInfo26".localize()),
        ]
    }
    
    // MARK: - Initializers
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTextForIPadIfNeeded()
        startPulsingAndFlashingAnimation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем фрейм градиентного слоя кнопки после просчета автолайаута
        if let gradientLayer = createGfButton.layer.sublayers?.first(where: { $0 is CAGradientLayer }) {
            gradientLayer.frame = createGfButton.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if BaseManager.shared.needOpenChatWithId != nil {
            BaseManager.shared.needOpenChatWithId = nil
            tabBarController?.selectedIndex = 0
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = MyColors.background
        
        titleLabel.text = "Explore".localize()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        setupCreateGfButton()
        view.addSubview(createGfButton)
        
        setupSegmentedControl()
        view.addSubview(segmentedControl)
        
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ExploreCell.self, forCellWithReuseIdentifier: ExploreCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        view.addSubview(collectionView)
        
        // MARK: - Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        createGfButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(createGfButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        updateRolesForCurrentCategory()
    }
    
    // MARK: - Create GF Button Setup
    private func setupCreateGfButton() {
        createGfButton.setTitle("CreateMyGF".localize(), for: .normal)
        createGfButton.setTitleColor(MyColors.textPrimary, for: .normal)
        createGfButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        
        // Иконка плюсика / магической палочки (опционально)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        let icon = UIImage(systemName: "sparkles", withConfiguration: config)
        createGfButton.setImage(icon, for: .normal)
        createGfButton.tintColor = MyColors.textPrimary
        createGfButton.semanticContentAttribute = .forceLeftToRight
        createGfButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        
        // Скруглитель
        createGfButton.layer.cornerRadius = 16
        createGfButton.layer.masksToBounds = false
        
        // Бордер
        createGfButton.layer.borderWidth = 1.0
        createGfButton.layer.borderColor = MyColors.progressBackground.cgColor

        // Градиентный фон в голубой гамме
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            MyColors.primary.cgColor,
            MyColors.primaryGradientEnd.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 16
        createGfButton.layer.insertSublayer(gradientLayer, at: 0)

        // Тень в тон голубому градиенту
        createGfButton.layer.shadowColor = MyColors.primary.withAlphaComponent(0.4).cgColor
        createGfButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        createGfButton.layer.shadowRadius = 12
        createGfButton.layer.shadowOpacity = 0.8
        
        // Экшен
        createGfButton.addTarget(self, action: #selector(createGfButtonTapped), for: .touchUpInside)
    }

    private func startPulsingAndFlashingAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.6
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.03
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 1

        let flashAnimation = CABasicAnimation(keyPath: "opacity")
        flashAnimation.duration = 0.6
        flashAnimation.fromValue = 1.0
        flashAnimation.toValue = 0.85
        flashAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        flashAnimation.autoreverses = true
        flashAnimation.repeatCount = 1

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [pulseAnimation, flashAnimation]
        animationGroup.duration = 2.0
        animationGroup.repeatCount = .infinity

        createGfButton.layer.add(animationGroup, forKey: "pulseAndFlash")
    }
    
    private func setupSegmentedControl() {
        for (index, category) in RoleCategory.allCases.enumerated() {
            segmentedControl.insertSegment(withTitle: category.title, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = currentCategory.rawValue
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        // Visual Styling for SegmentedControl
        segmentedControl.backgroundColor = MyColors.cardBackground
        segmentedControl.selectedSegmentTintColor = MyColors.primary
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: MyColors.textSecondary,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: MyColors.textPrimary,
            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
        ]
        
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
    }
    
    // MARK: - Actions & Data Handling
    @objc private func createGfButtonTapped() {
        AnalyticService.shared.logEvent(name: "Create My GF Tapped", properties: ["from": "ExploreVC"])
        
        let createGFVC = CreateDreamWaifuVC()
        createGFVC.modalPresentationStyle = .fullScreen
        createGFVC.isModalInPresentation = true
        present(createGFVC, animated: true)
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        guard let category = RoleCategory(rawValue: sender.selectedSegmentIndex) else { return }
        currentCategory = category
    }
    
    private func updateRolesForCurrentCategory() {
        switch currentCategory {
        case .real:
            roles = realRolesTest
        case .anime:
            roles = animeRolesTest
        case .milf:
            roles = milfRolesTest
        case .ex:
            roles = exRolesTest
        }
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension ExploreVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExploreCell.identifier, for: indexPath) as? ExploreCell else {
            return UICollectionViewCell()
        }
        
        let roleplay = roles[indexPath.row]
        cell.configure(with: roleplay)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AnalyticService.shared.logEvent(name: "Roleplay selected", properties: [
            "category": currentCategory.title,
            "index": "\(indexPath.row)",
            "name": roles[indexPath.row].name
        ])

        var selectedAssistant = AssistantsService().getAllConfigs().first(where: { $0.avatarImageName == roles[indexPath.row].image })
        
        if selectedAssistant == nil {
            let selectedAssistantID = UUID().uuidString
            selectedAssistant = AssistantConfig(
                id: selectedAssistantID,
                assistantName: roles[indexPath.row].name,
                assistantInfo: roles[indexPath.row].assistantInfo,
                avatarImageName: roles[indexPath.row].image ?? ""
            )
            if let selectedAssistant {
                AssistantsService().addConfig(selectedAssistant)
            }
            MessageHistoryService().addMessage(
                Message(role: "assistant", content: "StartMessage\(roles[indexPath.row].id)".localize()),
                assistantId: selectedAssistantID
            )
        }
        
        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true
        
        let aiChatViewController = MainChatVC()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
    
    private func showSubs() {
        let subsView = SubsView()
        subsView.vc = self
        subsView.onPaywallClosedHandler = { [weak self] in
            self?.tabBarController?.tabBar.isHidden = false
        }
        
        AnalyticService.shared.logEvent(name: "showSubs from Roleplay", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subsView.scrollToBottom()
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ExploreVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let spacing: CGFloat = 0
        let totalPadding = padding * 2 + spacing
        let cellWidth = (collectionView.bounds.width - totalPadding) / 2
        
        let cellHeight = cellWidth * 1.5
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

extension ExploreVC {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        
        titleLabel.font = .systemFont(ofSize: 38, weight: .bold)
    }
}
