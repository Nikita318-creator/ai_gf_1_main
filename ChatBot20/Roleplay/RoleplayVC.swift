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
        case .milf: return "MILF"
        case .ex: return "Ex"
        }
    }
}

class RoleplayVC: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
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
    
    // MARK: - Separate Data Arrays for Each Category
    private var realRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 1, name: "role.secretary.name".localize(), role: "role.secretary".localize(), image: "roleplay1", assistantInfo: "Roleplay.assistantInfo1".localize()),
            RoleplayModel(id: 2, name: "role.teacher.name".localize(), role: "role.teacher".localize(), image: "roleplay2", assistantInfo: "Roleplay.assistantInfo2".localize())
        ]
    }
    
    private var animeRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 3, name: "role.nurse.name".localize(), role: "role.nurse".localize(), image: "roleplay3", assistantInfo: "Roleplay.assistantInfo3".localize()),
            RoleplayModel(id: 4, name: "role.elf.name".localize(), role: "role.elf".localize(), image: "roleplay4", assistantInfo: "Roleplay.assistantInfo4".localize()),
            RoleplayModel(id: 8, name: "role.animeGirl.name".localize(), role: "role.animeGirl".localize(), image: "roleplay8", assistantInfo: "Roleplay.assistantInfo8".localize())
        ]
    }
    
    private var milfRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 5, name: "role.neighbor.name".localize(), role: "role.neighbor".localize(), image: "roleplay5", assistantInfo: "Roleplay.assistantInfo5".localize()),
            RoleplayModel(id: 6, name: "role.boss.name".localize(), role: "role.boss".localize(), image: "roleplay6", assistantInfo: "Roleplay.assistantInfo6".localize())
        ]
    }
    
    private var exRolesTest: [RoleplayModel] {
        return [
            RoleplayModel(id: 9, name: "role.friendsGirl.name".localize(), role: "role.friendsGirl".localize(), image: "roleplay9", assistantInfo: "Roleplay.assistantInfo9".localize()),
            RoleplayModel(id: 10, name: "role.sistersFriend.name".localize(), role: "role.sistersFriend".localize(), image: "roleplay10", assistantInfo: "Roleplay.assistantInfo10".localize())
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
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        // Setup Title Label
        titleLabel.text = "Dashbord".localize()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Setup Segmented Control
        setupSegmentedControl()
        view.addSubview(segmentedControl)
        
        // Setup Collection View
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RoleplayCell.self, forCellWithReuseIdentifier: RoleplayCell.identifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        view.addSubview(collectionView)
        
        // Setup Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        // Set initial data
        updateRolesForCurrentCategory()
    }
    
    private func setupSegmentedControl() {
        for (index, category) in RoleCategory.allCases.enumerated() {
            segmentedControl.insertSegment(withTitle: category.title, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = currentCategory.rawValue
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        // Visual Styling for SegmentedControl
        segmentedControl.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        segmentedControl.selectedSegmentTintColor = UIColor(red: 0.85, green: 0.2, blue: 0.45, alpha: 1.0) // Кастомный акцентный цвет
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightGray, .font: UIFont.systemFont(ofSize: 14, weight: .medium)]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .bold)]
        
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
    }
    
    // MARK: - Actions & Data Handling
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
extension RoleplayVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RoleplayCell.identifier, for: indexPath) as? RoleplayCell else {
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
            "role": roles[indexPath.row].role,
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
                Message(role: "assistant", content: "Roleplay.firstMessage\(roles[indexPath.row].id)".localize()),
                assistantId: selectedAssistantID
            )
        }
        
        MainHelper.shared.currentAssistant = selectedAssistant
        MainHelper.shared.isFirstMessageInChat = true
        
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
extension RoleplayVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let spacing: CGFloat = 0
        let totalPadding = padding * 2 + spacing
        let cellWidth = (collectionView.bounds.width - totalPadding) / 2
        
        let cellHeight = cellWidth * 1.5
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

extension RoleplayVC {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        
        titleLabel.font = .systemFont(ofSize: 38, weight: .bold)
    }
}
