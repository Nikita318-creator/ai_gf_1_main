//
//  ChatRouletteVC.swift
//  ChatBot20
//
//  Created by Mikita on 14/06/2026.
//

import UIKit
import SnapKit

class ChatRouletteVC: UIViewController {

    struct Colors {
        static let primary          = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background       = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground   = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let textPrimary      = UIColor.white
        static let textSecondary    = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator        = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    // MARK: - Data Models
    private let communicationStyles = [
        "Bold & Sassy".localize(),
        "Flirty & Tender".localize(),
        "Neutral & Casual".localize()
    ]

    private let interests = [
        "Anime & Manga".localize(), "Gaming".localize(), "Sports".localize(), "Movies & TV".localize(), "Music".localize(),
        "Cosplay".localize(), "K-Pop".localize(), "Reading".localize(), "Coding & Tech".localize(), "Art & Design".localize(),
        "Cooking".localize(), "Travel".localize(), "Fitness".localize(), "History".localize(), "Fashion".localize(),
        "Memes".localize(), "Crypto".localize(), "Board Games".localize(), "Mythology".localize(), "ASMR".localize()
    ]

    private let adultThemes = [
        "Yes, keep it hot".localize(),
        "No, keep it clean".localize(),
        "Let's see how it goes...".localize()
    ]

    private let waifuImages: [String] = {
        var images = [String]()
        for i in 1...10 {
            for j in 1...10 {
                images.append("roleplay\(i)_\(j)")
            }
        }
        return images
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
    private let titleLabel       = UILabel()
    private let descriptionLabel = UILabel()
    private let startButton      = UIButton(type: .system)

    // Step 2
    private var collectionView: UICollectionView!
    private let launchMatchButton = UIButton(type: .system)

    // Step 3
    private var matchingAvatarImageName = ""
    private let matchingAvatarImageView = UIImageView()
    private let matchingStatusLabel     = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background

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
        resetToDefaultState()
    }
    
    // MARK: - Reset State
    private func resetToDefaultState() {
        // 1. Сбрасываем выбранные индексы в дефолт
        selectedStyleIndex = 0
        selectedInterestIndex = 0
        selectedAdultIndex = 0
        
        // Перезагружаем коллекцию, чтобы сбросить выделение в UI
        if collectionView != nil {
            collectionView.reloadData()
        }
        
        // 2. Сбрасываем таймеры симуляции, если они были активны
        matchTimer?.invalidate()
        matchDurationTimer?.invalidate()
        matchTimer = nil
        matchDurationTimer = nil
        
        // Восстанавливаем прозрачность лейбла после анимации
        matchingStatusLabel.alpha = 1.0
        matchingAvatarImageView.image = nil
        matchingAvatarImageName = ""
        
        // 3. Возвращаем видимость экранов к первому шагу
        welcomeContainerView.isHidden  = false
        pollContainerView.isHidden     = true
        matchingContainerView.isHidden = true
    }
    
    // MARK: - Step 1: Welcome Screen
    private func setupWelcomeScreen() {
        view.addSubview(welcomeContainerView)
        welcomeContainerView.backgroundColor = .clear
        welcomeContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        // Avatar placeholder / hero icon
        let heroContainer = UIView()
        heroContainer.backgroundColor = Colors.cardBackground
        heroContainer.layer.cornerRadius = 32
        heroContainer.layer.borderWidth = 1
        heroContainer.layer.borderColor = Colors.separator.cgColor

        let heroIcon = UILabel()
        heroIcon.text = "✨"
        heroIcon.font = .systemFont(ofSize: 52)
        heroIcon.textAlignment = .center

        heroContainer.addSubview(heroIcon)
        heroIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // Badge pill
        let badgePill = UIView()
        badgePill.backgroundColor = Colors.primary.withAlphaComponent(0.15)
        badgePill.layer.cornerRadius = 12

        let badgeLabel = UILabel()
        badgeLabel.text = "AI-POWERED MATCHING".localize()
        badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.textColor = Colors.primary
        badgeLabel.letterSpacing(1.2)

        badgePill.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14))
        }

        titleLabel.text = "Waifu Roulette".localize()
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = Colors.textPrimary
        titleLabel.textAlignment = .center

        descriptionLabel.text = "Set your preferences and get matched with a unique anime companion. Not feeling it? Skip instantly and find the next one.".localize()
        descriptionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descriptionLabel.textColor = Colors.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.lineSpacing(4)

        // Stats row
        let statsRow = makeStatsRow()

        // Divider
        let divider = UIView()
        divider.backgroundColor = Colors.separator

        startButton.setTitle("Start Matching".localize(), for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = Colors.primary
        startButton.layer.cornerRadius = 14
        startButton.addTarget(self, action: #selector(startBtnTapped), for: .touchUpInside)

        [heroContainer, badgePill, titleLabel, descriptionLabel, statsRow, divider, startButton].forEach {
            welcomeContainerView.addSubview($0)
        }

        heroContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(108)
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
            make.height.equalTo(60)
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(statsRow.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        startButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
    }

    private func makeStatsRow() -> UIView {
        let container = UIView()
        container.backgroundColor = Colors.cardBackground
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.layer.borderColor = Colors.separator.cgColor

        let items: [(String, String)] = [
            ("12K+", "Active".localize()),
            ("4.8★", "Rating".localize()),
            ("100+", "Types".localize())
        ]
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually

        for (idx, item) in items.enumerated() {
            let col = makeStatColumn(value: item.0, label: item.1)
            stack.addArrangedSubview(col)

            if idx < items.count - 1 {
                let sep = UIView()
                sep.backgroundColor = Colors.separator
                stack.addArrangedSubview(sep)
                sep.snp.makeConstraints { make in make.width.equalTo(1) }
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
        valLabel.textColor = Colors.primary
        valLabel.textAlignment = .center

        let lblLabel = UILabel()
        lblLabel.text = label
        lblLabel.font = .systemFont(ofSize: 12, weight: .regular)
        lblLabel.textColor = Colors.textSecondary
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
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }

        let navBar = makeNavBar(title: "Your Preferences".localize())
        pollContainerView.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }

        let layout = createCompositionalLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.register(SelectableTagCell.self, forCellWithReuseIdentifier: SelectableTagCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)

        launchMatchButton.setTitle("Find My Waifu".localize(), for: .normal)
        launchMatchButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        launchMatchButton.setTitleColor(.white, for: .normal)
        launchMatchButton.backgroundColor = Colors.primary
        launchMatchButton.layer.cornerRadius = 14
        launchMatchButton.addTarget(self, action: #selector(launchMatchTapped), for: .touchUpInside)

        let rocketLabel = UILabel()
        rocketLabel.text = "🚀"
        rocketLabel.font = .systemFont(ofSize: 16)
        launchMatchButton.addSubview(rocketLabel)
        rocketLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }

        pollContainerView.addSubview(collectionView)
        pollContainerView.addSubview(launchMatchButton)

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(launchMatchButton.snp.top).offset(-12)
        }

        launchMatchButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
    }

    private func makeNavBar(title: String) -> UIView {
        let container = UIView()
        let titleLbl  = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLbl.textColor = Colors.textPrimary
        container.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { make in make.center.equalToSuperview() }

        let sep = UIView()
        sep.backgroundColor = Colors.separator
        container.addSubview(sep)
        sep.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
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
        matchingContainerView.backgroundColor = Colors.background
        matchingContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        let topLabel = UILabel()
        topLabel.text = "Searching...".localize()
        topLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        topLabel.textColor = Colors.textPrimary
        topLabel.textAlignment = .center

        let cardView = UIView()
        cardView.backgroundColor = Colors.cardBackground
        cardView.layer.cornerRadius = 24
        cardView.layer.borderWidth  = 1
        cardView.layer.borderColor  = Colors.separator.cgColor

        matchingAvatarImageView.contentMode     = .scaleAspectFill
        matchingAvatarImageView.layer.cornerRadius = 16
        matchingAvatarImageView.clipsToBounds   = true
        matchingAvatarImageView.backgroundColor = Colors.messageBackground

        cardView.addSubview(matchingAvatarImageView)
        matchingAvatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        let statusPill = UIView()
        statusPill.backgroundColor = Colors.background.withAlphaComponent(0.85)
        statusPill.layer.cornerRadius = 12

        matchingStatusLabel.text          = "Looking for your ideal partner...".localize()
        matchingStatusLabel.font          = .systemFont(ofSize: 13, weight: .medium)
        matchingStatusLabel.textColor     = Colors.textSecondary
        matchingStatusLabel.textAlignment = .center
        matchingStatusLabel.numberOfLines = 1

        let dotIndicator = UIActivityIndicatorView(style: .medium)
        dotIndicator.color = Colors.primary
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

        let hints = ["Style Match".localize(), "Interest Align".localize(), "Vibe Check".localize()]
        for hint in hints {
            let chip = UIView()
            chip.backgroundColor = Colors.cardBackground
            chip.layer.cornerRadius = 10
            chip.layer.borderWidth  = 1
            chip.layer.borderColor  = Colors.separator.cgColor

            let chipLabel = UILabel()
            chipLabel.text      = hint
            chipLabel.font      = .systemFont(ofSize: 12, weight: .medium)
            chipLabel.textColor = Colors.textSecondary
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
            make.height.equalTo(300)
        }

        statusPill.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(20)
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
            if let randomImageName = self.waifuImages.randomElement() {
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
        let selectedAdult   = adultThemes[selectedAdultIndex]

        // Теперь пул включает все 60 имён
        let waifuNameKeys = (1...60).map { "waifu_name_\($0)" }

        // Вытягиваем рандом
        let randomWaifuName = (waifuNameKeys.randomElement() ?? "waifu_name_1").localize()
        
        print("🎯 Поиск завершен! Передаем в генератор: \(selectedStyle), \(selectedInterest), \(selectedAdult)")
        AnalyticService.shared.logEvent(
            name: "ChatRoulette waifu found",
            properties: [
                "selectedStyle":"\(selectedStyle)",
                "selectedInterest":"\(selectedInterest)",
                "selectedAdult":"\(selectedAdult)",
                "matchingAvatarImageName":"\(matchingAvatarImageName)",
                "randomWaifuName":"\(randomWaifuName)"
            ]
        )

        let promptForAI = " This is a chat roulette mode, you are randomly selected to communicate with the user because your profiles matched, you strictly use the \(selectedStyle) communication style in communication! All your topics one way or another come down to the discussion of \(selectedInterest), ask the user questions, talk about why it fascinates you, develop the thought -- involve the user in a conversation on this topic! The user was asked if he wants the conversation to be mostly focused on 18+ themes and discussions of adults topics and he answered \(selectedAdult) -- this was the most important condition for the current chat. "
        
        let selectedAssistantID = UUID().uuidString
        let selectedAssistant = AssistantConfig(
            id: selectedAssistantID,
            assistantName: randomWaifuName,
            assistantInfo: "ChatRoulette",
            avatarImageName: matchingAvatarImageName
        )
        
        AssistantsService().addConfig(selectedAssistant)

        let welcomeMessageKeys = (1...10).map { "waifu_welcome_\($0)" }
        let randomWelcomeMessage = (welcomeMessageKeys.randomElement() ?? "waifu_welcome_1").localize()

        let messageId = UUID().uuidString
        MessageHistoryService().addMessage(
            Message(
                role: "assistant",
                content: randomWelcomeMessage,
                id: messageId
            ),
            assistantId: selectedAssistantID,
            messageId: messageId
        )
        
        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true
        
        let aiChatViewController = MainChatVC()
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
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 24, trailing: 0)

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
extension ChatRouletteVC: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return communicationStyles.count
        case 1: return interests.count
        case 2: return adultThemes.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectableTagCell.identifier, for: indexPath) as? SelectableTagCell else {
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
            text = adultThemes[indexPath.item]
            isSelected = indexPath.item == selectedAdultIndex
        default:
            text = ""; isSelected = false
        }

        cell.configure(text: text, isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as? SectionHeaderView else {
            return UICollectionReusableView()
        }

        let title: String
        switch indexPath.section {
        case 0: title = "Communication Style".localize()
        case 1: title = "Her Main Interests".localize()
        case 2: title = "Allow 18+ Themes?".localize()
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
