import UIKit
import SnapKit

class RandomAIGFViewController: UIViewController {
    
    // MARK: - Data Models
    private let communicationStyles = [
        "Roulette_Style_Option1".localize(),
        "Roulette_Style_Option2".localize(),
        "Roulette_Style_Option3".localize()
    ]

    private let interests = [
        "Roulette_Interest_Anime".localize(),
        "Roulette_Interest_Gaming".localize(),
        "Roulette_Interest_Sports".localize(),
        "Roulette_Interest_Movies".localize(),
        "Roulette_Interest_Music".localize(),
        "Roulette_Interest_Cosplay".localize(),
        "Roulette_Interest_KPop".localize(),
        "Roulette_Interest_Reading".localize(),
        "Roulette_Interest_Tech".localize(),
        "Roulette_Interest_Art".localize(),
        "Roulette_Interest_Cooking".localize(),
        "Roulette_Interest_Travel".localize(),
        "Roulette_Interest_Fitness".localize(),
        "Roulette_Interest_History".localize(),
        "Roulette_Interest_Fashion".localize(),
        "Roulette_Interest_Memes".localize(),
        "Roulette_Interest_Crypto".localize(),
        "Roulette_Interest_BoardGames".localize(),
        "Roulette_Interest_Mythology".localize(),
        "Roulette_Interest_ASMR".localize()
    ]

    private let ageThemes = [
        "Roulette_Age_Option2".localize(),
        "Roulette_Age_Option1".localize(),
        "Roulette_Age_Option3".localize()
    ]

    private let gfImages: [String] = {
        let combined: [String] = APIManager.shared.isTestB ? (1...87).map { "swipeModeAvatar\($0)" } : SearchAIGFFeatureViewModel.avatarsA
        return combined
    }()

    private var selectedStyleIndex = 0
    private var selectedInterestIndex = 0
    private var selectedAdultIndex = 0

    private var matchTimer: Timer?
    private var matchDurationTimer: Timer?

    // MARK: - UI Elements
    private let welcomeContainerView = UIView()
    private let pollContainerView    = UIView()
    private let matchingContainerView = UIView()

    // Step 1
    private let welcomeBackButton = UIButton(type: .system)
    private let titleLabel       = UILabel()
    private let descriptionLabel = UILabel()
    private let startButton      = AnimatedButton(type: .system)

    // Step 2
    private let pollBackButton   = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private let launchMatchButton = AnimatedButton(type: .system)

    // Step 3
    private var matchingAvatarImageName = ""
    private let matchingAvatarImageView = UIImageView()
    private let matchingStatusLabel     = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MyColors.background

        setupWelcomeScreen()
        setupPollScreen()
        setupMatchingScreen()

        welcomeContainerView.isHidden  = false
        pollContainerView.isHidden     = true
        matchingContainerView.isHidden = true
        
        AnalyticService.shared.logEvent(name: "ChatRoulette opened", properties: ["":""])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        resetToDefaultState()
    }
    
    // MARK: - Reset State
    private func resetToDefaultState() {
        selectedStyleIndex = 0
        selectedInterestIndex = 0
        selectedAdultIndex = 0
        
        if collectionView != nil {
            collectionView.reloadData()
        }
        
        matchTimer?.invalidate()
        matchDurationTimer?.invalidate()
        matchTimer = nil
        matchDurationTimer = nil
        
        matchingStatusLabel.alpha = 1.0
        matchingAvatarImageView.image = nil
        matchingAvatarImageName = ""
        
        welcomeContainerView.isHidden  = false
        pollContainerView.isHidden     = true
        matchingContainerView.isHidden = true
    }

    // MARK: - Navigation Back Action
    @objc private func didTapCloseOrBack() {
        if !welcomeContainerView.isHidden {
            if let nav = navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        } else if !pollContainerView.isHidden {
            pollContainerView.isHidden = true
            welcomeContainerView.isHidden = false
        } else if !matchingContainerView.isHidden {
            matchTimer?.invalidate()
            matchDurationTimer?.invalidate()
            matchTimer = nil
            matchDurationTimer = nil
            
            matchingContainerView.isHidden = true
            pollContainerView.isHidden = false
        }
    }
    
    // MARK: - Step 1: Welcome Screen
    private func setupWelcomeScreen() {
        view.addSubview(welcomeContainerView)
        welcomeContainerView.backgroundColor = .clear
        welcomeContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 8, left: 20, bottom: 16, right: 20))
        }

        setupBackButton(welcomeBackButton, in: welcomeContainerView)

        let heroContainer = UIView()
        heroContainer.backgroundColor = MyColors.cardBackground
        heroContainer.layer.cornerRadius = 36
        heroContainer.layer.borderWidth = 1
        heroContainer.layer.borderColor = MyColors.separator.cgColor

        let heroIcon = UILabel()
        heroIcon.text = "💖"
        heroIcon.font = .systemFont(ofSize: 48)
        heroIcon.textAlignment = .center

        heroContainer.addSubview(heroIcon)
        heroIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let badgePill = UIView()
        badgePill.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        badgePill.layer.cornerRadius = 12

        let badgeLabel = UILabel()
        badgeLabel.text = "Roulette_Step1_Badge".localize()
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = MyColors.primary

        badgePill.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14))
        }

        titleLabel.text = "Roulette_Step1_Title".localize()
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center

        descriptionLabel.text = "Roulette_Step1_Description".localize()
        descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = MyColors.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        let statsRow = makeStatsRow()

        let divider = UIView()
        divider.backgroundColor = MyColors.separator

        startButton.setTitle("Roulette_Step1_StartButton".localize(), for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        startButton.setTitleColor(MyColors.textPrimary, for: .normal)
        startButton.backgroundColor = MyColors.primary
        startButton.layer.cornerRadius = 16
        startButton.addTarget(self, action: #selector(startBtnTapped), for: .touchUpInside)

        [heroContainer, badgePill, titleLabel, descriptionLabel, statsRow, divider, startButton].forEach {
            welcomeContainerView.addSubview($0)
        }

        heroContainer.snp.makeConstraints { make in
            make.top.equalTo(welcomeBackButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }

        badgePill.snp.makeConstraints { make in
            make.top.equalTo(heroContainer.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badgePill.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        statsRow.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(statsRow.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        startButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }
    }

    private func makeStatsRow() -> UIView {
        let container = UIView()
        container.backgroundColor = MyColors.cardBackground
        container.layer.cornerRadius = 18
        container.layer.borderWidth = 1
        container.layer.borderColor = MyColors.separator.cgColor

        let items: [(String, String)] = [
            ("Roulette_Stat1_Value".localize(), "Roulette_Stat1_Label".localize()),
            ("Roulette_Stat2_Value".localize(), "Roulette_Stat2_Label".localize()),
            ("Roulette_Stat3_Value".localize(), "Roulette_Stat3_Label".localize())
        ]
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill

        for (idx, item) in items.enumerated() {
            let col = makeStatColumn(value: item.0, label: item.1)
            stack.addArrangedSubview(col)

            if idx < items.count - 1 {
                let sepContainer = UIView()
                let sepLine = UIView()
                sepLine.backgroundColor = MyColors.separator
                
                sepContainer.addSubview(sepLine)
                sepLine.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview().inset(4)
                    make.centerX.equalToSuperview()
                    make.width.equalTo(1)
                }
                
                sepContainer.snp.makeConstraints { make in
                    make.width.equalTo(1)
                }
                
                stack.addArrangedSubview(sepContainer)
            }
        }

        let columns = stack.arrangedSubviews.filter { !($0.subviews.first?.backgroundColor == MyColors.separator) }
        if let firstCol = columns.first {
            for col in columns.dropFirst() {
                col.snp.makeConstraints { make in
                    make.width.equalTo(firstCol)
                }
            }
        }

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        return container
    }

    private func makeStatColumn(value: String, label: String) -> UIView {
        let col = UIView()
        let valLabel = UILabel()
        valLabel.text = value
        valLabel.font = .systemFont(ofSize: 17, weight: .bold)
        valLabel.textColor = MyColors.primary
        valLabel.textAlignment = .center

        let lblLabel = UILabel()
        lblLabel.text = label
        lblLabel.font = .systemFont(ofSize: 12, weight: .regular)
        lblLabel.textColor = MyColors.textSecondary
        lblLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valLabel, lblLabel])
        stack.axis = .vertical
        stack.spacing = 2
        col.addSubview(stack)
        stack.snp.makeConstraints { make in make.center.equalToSuperview() }
        return col
    }

    @objc private func startBtnTapped() {
        welcomeContainerView.isHidden = true
        pollContainerView.isHidden    = false
    }

    // MARK: - Step 2: Poll Screen
    private func setupPollScreen() {
        view.addSubview(pollContainerView)
        pollContainerView.backgroundColor = .clear
        pollContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 8, left: 20, bottom: 12, right: 20))
        }

        let navBar = makeNavBar(title: "Roulette_Step2_NavTitle".localize(), backButton: pollBackButton)
        pollContainerView.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        let layout = createCompositionalLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.register(RandomAIGFTagCell.self, forCellWithReuseIdentifier: RandomAIGFTagCell.identifier)
        collectionView.register(RandomAIGFHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: RandomAIGFHeaderView.identifier)

        launchMatchButton.setTitle("Roulette_Step2_LaunchButton".localize(), for: .normal)
        launchMatchButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        launchMatchButton.setTitleColor(MyColors.textPrimary, for: .normal)
        launchMatchButton.backgroundColor = MyColors.primary
        launchMatchButton.layer.cornerRadius = 16
        launchMatchButton.addTarget(self, action: #selector(launchMatchTapped), for: .touchUpInside)

        let rocketLabel = UILabel()
        rocketLabel.text = "⚡️"
        rocketLabel.font = .systemFont(ofSize: 16)
        launchMatchButton.addSubview(rocketLabel)
        rocketLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }

        pollContainerView.addSubview(collectionView)
        pollContainerView.addSubview(launchMatchButton)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(launchMatchButton.snp.top).offset(-12)
        }

        launchMatchButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }
    }

    private func setupBackButton(_ button: UIButton, in parentView: UIView) {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.cardBackground
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = MyColors.separator.cgColor
        button.addTarget(self, action: #selector(didTapCloseOrBack), for: .touchUpInside)

        parentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(40)
        }
    }

    private func makeNavBar(title: String, backButton: UIButton) -> UIView {
        let container = UIView()
        setupBackButton(backButton, in: container)

        let titleLbl  = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 18, weight: .bold)
        titleLbl.textColor = MyColors.textPrimary
        container.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        return container
    }

    @objc private func launchMatchTapped() {
        pollContainerView.isHidden    = true
        matchingContainerView.isHidden = false
        startSimulation()
    }

    // MARK: - Step 3: Simulation Screen
    private func setupMatchingScreen() {
        view.addSubview(matchingContainerView)
        matchingContainerView.backgroundColor = MyColors.background
        matchingContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        let topLabel = UILabel()
        topLabel.text = "Roulette_Step3_SearchingTitle".localize()
        topLabel.font = .systemFont(ofSize: 18, weight: .bold)
        topLabel.textColor = MyColors.textPrimary
        topLabel.textAlignment = .center

        let cardView = UIView()
        cardView.backgroundColor = MyColors.cardBackground
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth  = 1
        cardView.layer.borderColor  = MyColors.separator.cgColor

        matchingAvatarImageView.contentMode     = .scaleAspectFill
        matchingAvatarImageView.layer.cornerRadius = 18
        matchingAvatarImageView.clipsToBounds   = true
        matchingAvatarImageView.backgroundColor = MyColors.messageBackground

        cardView.addSubview(matchingAvatarImageView)
        matchingAvatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        let statusPill = UIView()
        statusPill.backgroundColor = MyColors.cardBackground
        statusPill.layer.cornerRadius = 14
        statusPill.layer.borderWidth = 1
        statusPill.layer.borderColor = MyColors.separator.cgColor

        matchingStatusLabel.text          = "Roulette_Step3_StatusText".localize()
        matchingStatusLabel.font          = .systemFont(ofSize: 13, weight: .medium)
        matchingStatusLabel.textColor     = MyColors.textSecondary
        matchingStatusLabel.textAlignment = .center
        matchingStatusLabel.numberOfLines = 1

        let dotIndicator = UIActivityIndicatorView(style: .medium)
        dotIndicator.color = MyColors.primary
        dotIndicator.startAnimating()

        let pillStack = UIStackView(arrangedSubviews: [dotIndicator, matchingStatusLabel])
        pillStack.axis    = .horizontal
        pillStack.spacing = 8
        pillStack.alignment = .center

        statusPill.addSubview(pillStack)
        pillStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }

        let hintsStack = UIStackView()
        hintsStack.axis    = .horizontal
        hintsStack.spacing = 8
        hintsStack.distribution = .fillProportionally

        let hints = [
            "Roulette_Chip_Style".localize(),
            "Roulette_Chip_Interest".localize(),
            "Roulette_Chip_Vibe".localize()
        ]
        
        for hint in hints {
            let chip = UIView()
            chip.backgroundColor = MyColors.cardBackground
            chip.layer.cornerRadius = 10
            chip.layer.borderWidth  = 1
            chip.layer.borderColor  = MyColors.separator.cgColor

            let chipLabel = UILabel()
            chipLabel.text      = hint
            chipLabel.font      = .systemFont(ofSize: 12, weight: .medium)
            chipLabel.textColor = MyColors.textSecondary
            chip.addSubview(chipLabel)
            chipLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
            }
            hintsStack.addArrangedSubview(chip)
        }

        [topLabel, cardView, statusPill, hintsStack].forEach {
            matchingContainerView.addSubview($0)
        }

        topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview()
        }

        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(260)
            make.height.equalTo(320)
        }

        statusPill.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        hintsStack.snp.makeConstraints { make in
            make.top.equalTo(statusPill.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
    }

    private func startSimulation() {
        matchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let randomImageName = self.gfImages.randomElement() {
                self.matchingAvatarImageView.image = UIImage(named: randomImageName)
                self.matchingAvatarImageName = randomImageName
            }
        }

        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.matchingStatusLabel.alpha = 0.4
        }, completion: nil)

        matchDurationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.stopSimulationAndProceed()
        }
    }

    private func stopSimulationAndProceed() {
        matchTimer?.invalidate()
        matchDurationTimer?.invalidate()
        matchTimer        = nil
        matchDurationTimer = nil

        matchingStatusLabel.alpha = 1.0

        let selectedStyle   = communicationStyles[selectedStyleIndex]
        let selectedInterest = interests[selectedInterestIndex]
        
        // Для теста А берем по дефолту Roulette_Age_Option2, в Тесте Б — то, что выбрал юзер
        let selectedAge = APIManager.shared.isTestB ? ageThemes[selectedAdultIndex] : "Roulette_Age_Option2".localize()

        let gfNameKeys = (1...87).map { "swipeModeName\($0)" }
        let randomGfName = (gfNameKeys.randomElement() ?? "swipeModeName2").localize()
        
        AnalyticService.shared.logEvent(
            name: "ChatRoulette gf found",
            properties: [
                "selectedStyle":"\(selectedStyle)",
                "selectedInterest":"\(selectedInterest)",
                "selectedAge":"\(selectedAge)",
                "matchingAvatarImageName":"\(matchingAvatarImageName)",
                "randomGfName":"\(randomGfName)"
            ]
        )

        let promptForAI = " This is a chat roulette mode, you are randomly selected to communicate with the user because your profiles matched, you strictly use the \(selectedStyle) communication style in communication! All your topics one way or another come down to the discussion of \(selectedInterest), ask the user questions, talk about why it fascinates you, develop the thought -- involve the user in a conversation on this topic! The user was asked if he wants the conversation to be mostly focused on 18+ themes and discussions of adults topics and he answered \(selectedAge) -- this was the most important condition for the current chat. "

        let selectedAssistantID = UUID().uuidString
        let selectedAssistant = AIGirlfriendsConfig(
            id: selectedAssistantID,
            assistantName: randomGfName,
            assistantInfo: promptForAI,
            avatarImageName: matchingAvatarImageName
        )
        
        AIGirlfriendsManager().addConfig(selectedAssistant)

        let welcomeMessageKeys = (1...10).map { "Roulette_Welcome_\($0)" }
        let randomWelcomeMessage = (welcomeMessageKeys.randomElement() ?? "Roulette_Welcome_1").localize()

        let messageId = UUID().uuidString
        AIGirlfriendMessagesManager().addMessage(
            AIGFMessageModel(
                role: "assistant",
                content: randomWelcomeMessage,
                id: messageId
            ),
            assistantId: selectedAssistantID,
            messageId: messageId
        )
        
        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true
        
        let aiChatViewController = AIGFChatViewController()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }

    // MARK: - Compositional Layout Setup
    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            let isInterestsSection = sectionIndex == 1

            let itemSize = isInterestsSection
                ? NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(40))
                : NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(48))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = isInterestsSection
                ? NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
                : NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(48))

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            if isInterestsSection {
                group.interItemSpacing = .fixed(8)
            }

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 20, trailing: 0)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension RandomAIGFViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return APIManager.shared.isTestB ? 3 : 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return communicationStyles.count
        case 1: return interests.count
        case 2: return APIManager.shared.isTestB ? ageThemes.count : 0
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RandomAIGFTagCell.identifier, for: indexPath) as? RandomAIGFTagCell else {
            return UICollectionViewCell()
        }

        let text: String
        let isSelected: Bool

        switch indexPath.section {
        case 0:
            text = communicationStyles[indexPath.item]
            isSelected = indexPath.item == selectedStyleIndex
        case 1:
            text = interests[indexPath.item]
            isSelected = indexPath.item == selectedInterestIndex
        case 2:
            text = ageThemes[indexPath.item]
            isSelected = indexPath.item == selectedAdultIndex
        default:
            text = ""; isSelected = false
        }

        cell.configure(text: text, isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RandomAIGFHeaderView.identifier, for: indexPath) as? RandomAIGFHeaderView else {
            return UICollectionReusableView()
        }

        let title: String
        switch indexPath.section {
        case 0: title = "Roulette_Section1_Title".localize()
        case 1: title = "Roulette_Section2_Title".localize()
        case 2: title = "Roulette_Section3_Title".localize()
        default: title = ""
        }

        let stepNum = indexPath.section + 1
        header.configure(title: title, step: stepNum)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0: selectedStyleIndex    = indexPath.item
        case 1: selectedInterestIndex = indexPath.item
        case 2: selectedAdultIndex    = indexPath.item
        default: break
        }
        collectionView.reloadSections(IndexSet(integer: indexPath.section))
    }
}
