import UIKit
import SnapKit

class RoleplayVC: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    
    // MARK: - Data
    private var roles: [RoleplayModel] = []
    
    private let rolesTest1: [RoleplayModel] = [ // меньше вариантов
        RoleplayModel(id: 1, name: "role.secretary.name".localize(), role: "role.secretary".localize(), image: "roleplay1", assistantInfo: "Roleplay.assistantInfo1".localize()),
        RoleplayModel(id: 2, name: "role.teacher.name".localize(), role: "role.teacher".localize(), image: "roleplay2", assistantInfo: "Roleplay.assistantInfo2".localize()),
        RoleplayModel(id: 4, name: "role.elf.name".localize(), role: "role.elf".localize(), image: "roleplay4", assistantInfo: "Roleplay.assistantInfo4".localize()),
        RoleplayModel(id: 6, name: "role.boss.name".localize(), role: "role.boss".localize(), image: "roleplay6", assistantInfo: "Roleplay.assistantInfo6".localize()),
        RoleplayModel(id: 7, name: "role.fitness.name".localize(), role: "role.fitness".localize(), image: "roleplay7", assistantInfo: "Roleplay.assistantInfo7".localize()),
        RoleplayModel(id: 9, name: "role.friendsGirl.name".localize(), role: "role.friendsGirl".localize(), image: "roleplay9", assistantInfo: "Roleplay.assistantInfo9".localize()),
        RoleplayModel(id: 10, name: "role.sistersFriend.name".localize(), role: "role.sistersFriend".localize(), image: "roleplay10", assistantInfo: "Roleplay.assistantInfo10".localize()),
        RoleplayModel(id: 12, name: "role.princess.name".localize(), role: "role.princess".localize(), image: "roleplay12", assistantInfo: "Roleplay.assistantInfo12".localize())
    ].shuffled()
    
    private var rolesTest2: [RoleplayModel] {
        if GEOService.shared.isAsionGeo {
            return [
                RoleplayModel(id: 1, name: "role.secretary.name".localize(), role: "role.secretary".localize(), image: "asion74", assistantInfo: "Roleplay.assistantInfo1".localize()),
                RoleplayModel(id: 2, name: "role.teacher.name".localize(), role: "role.teacher".localize(), image: "asion49", assistantInfo: "Roleplay.assistantInfo2".localize()),
                RoleplayModel(id: 3, name: "role.nurse.name".localize(), role: "role.nurse".localize(), image: "roleplay3", assistantInfo: "Roleplay.assistantInfo3".localize()),
                RoleplayModel(id: 4, name: "role.elf.name".localize(), role: "role.elf".localize(), image: "roleplay4", assistantInfo: "Roleplay.assistantInfo4".localize()),
                RoleplayModel(id: 5, name: "role.neighbor.name".localize(), role: "role.neighbor".localize(), image: "roleplay5", assistantInfo: "Roleplay.assistantInfo5".localize()),
                RoleplayModel(id: 6, name: "role.boss.name".localize(), role: "role.boss".localize(), image: "asion72", assistantInfo: "Roleplay.assistantInfo6".localize()),
                RoleplayModel(id: 7, name: "role.fitness.name".localize(), role: "role.fitness".localize(), image: "roleplay7", assistantInfo: "Roleplay.assistantInfo7".localize()),
                RoleplayModel(id: 8, name: "role.animeGirl.name".localize(), role: "role.animeGirl".localize(), image: "roleplay8", assistantInfo: "Roleplay.assistantInfo8".localize()),
                RoleplayModel(id: 9, name: "role.friendsGirl.name".localize(), role: "role.friendsGirl".localize(), image: "asion89", assistantInfo: "Roleplay.assistantInfo9".localize()),
                RoleplayModel(id: 10, name: "role.sistersFriend.name".localize(), role: "role.sistersFriend".localize(), image: "asion35", assistantInfo: "Roleplay.assistantInfo10".localize()),
                RoleplayModel(id: 11, name: "role.sensitive.name".localize(), role: "role.sensitive".localize(), image: "asion36", assistantInfo: "Roleplay.assistantInfo11".localize()),
                RoleplayModel(id: 12, name: "role.princess.name".localize(), role: "role.princess".localize(), image: "roleplay12", assistantInfo: "Roleplay.assistantInfo12".localize())
            ].shuffled()
        } else {
            return [
                RoleplayModel(id: 1, name: "role.secretary.name".localize(), role: "role.secretary".localize(), image: "roleplay1", assistantInfo: "Roleplay.assistantInfo1".localize()),
                RoleplayModel(id: 2, name: "role.teacher.name".localize(), role: "role.teacher".localize(), image: "roleplay2", assistantInfo: "Roleplay.assistantInfo2".localize()),
                RoleplayModel(id: 3, name: "role.nurse.name".localize(), role: "role.nurse".localize(), image: "roleplay3", assistantInfo: "Roleplay.assistantInfo3".localize()),
                RoleplayModel(id: 4, name: "role.elf.name".localize(), role: "role.elf".localize(), image: "roleplay4", assistantInfo: "Roleplay.assistantInfo4".localize()),
                RoleplayModel(id: 5, name: "role.neighbor.name".localize(), role: "role.neighbor".localize(), image: "roleplay5", assistantInfo: "Roleplay.assistantInfo5".localize()),
                RoleplayModel(id: 6, name: "role.boss.name".localize(), role: "role.boss".localize(), image: "roleplay6", assistantInfo: "Roleplay.assistantInfo6".localize()),
                RoleplayModel(id: 7, name: "role.fitness.name".localize(), role: "role.fitness".localize(), image: "roleplay7", assistantInfo: "Roleplay.assistantInfo7".localize()),
                RoleplayModel(id: 8, name: "role.animeGirl.name".localize(), role: "role.animeGirl".localize(), image: "roleplay8", assistantInfo: "Roleplay.assistantInfo8".localize()),
                RoleplayModel(id: 9, name: "role.friendsGirl.name".localize(), role: "role.friendsGirl".localize(), image: "roleplay9", assistantInfo: "Roleplay.assistantInfo9".localize()),
                RoleplayModel(id: 10, name: "role.sistersFriend.name".localize(), role: "role.sistersFriend".localize(), image: "roleplay10", assistantInfo: "Roleplay.assistantInfo10".localize()),
                RoleplayModel(id: 11, name: "role.sensitive.name".localize(), role: "role.sensitive".localize(), image: "roleplay11", assistantInfo: "Roleplay.assistantInfo11".localize()),
                RoleplayModel(id: 12, name: "role.princess.name".localize(), role: "role.princess".localize(), image: "roleplay12", assistantInfo: "Roleplay.assistantInfo12".localize())
            ].shuffled()
        }
    }
    
    // MARK: - Initializers
    init() {
        // Setup layout for collection view
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
        roles = MainHelper.shared.isMode ? rolesTest1 : rolesTest2
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        // Setup Title Label
        titleLabel.text = "roleplay.title".localize()
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
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
            make.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
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
        AnalyticService.shared.logEvent(name: "Roleplay selected", properties: ["index:":"\(indexPath.row)", "role:":" \(roles[indexPath.row].role)", "name:":"\(roles[indexPath.row].name)"])
        
//        guard IAPService.shared.hasActiveSubscription else { // todo убрал ролплей из премиум
//            tabBarController?.tabBar.isHidden = true
//            let customAlertView = CustomAlertView(type: .roleplay)
//            customAlertView.show(in: view.self)
//            customAlertView.onRateButtonTapped = { [weak self] in self?.showSubs() }
//            customAlertView.onLaterButtonTapped = { [weak self] in self?.showSubs() }
//            return
//        }
        
        MainHelper.shared.isCurrentAssistantPremium = false
        MainHelper.shared.isCurrentAssistantPremiumVoice = false
        MainHelper.shared.isVoiceChat = false

        var selectedAssistant = AssistantsService().getAllConfigs().first(where: { $0.avatarImageName == roles[indexPath.row].image })
        
        if selectedAssistant == nil {
            let selectedAssistantID = UUID().uuidString
            selectedAssistant = AssistantConfig(
                id: selectedAssistantID,
                assistantName: roles[indexPath.row].name,
                aiModel: .gemini15Flash,
                tone: .roleplay,
                style: .friendly,
                expertise: .roleplay,
                assistantInfo: roles[indexPath.row].assistantInfo,
                userInfo: "",
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

        // needUpdateProductsByTapYearlyButton:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subsView.scrollToBottom()
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RoleplayVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16 // Отступы с каждой стороны
        let spacing: CGFloat = 0 // Расстояние между ячейками
        let totalPadding = padding * 2 + spacing // Общий отступ
        let cellWidth = (collectionView.bounds.width - totalPadding) / 2
        
        // Соотношение сторон, чтобы ячейка выглядела как карточка
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
