import UIKit
import SnapKit

class RandomAIGFViewController: UIViewController {

    private let viewModel = RandomAIGFViewModel()

    // MARK: - Subviews
    private let welcomeView = RandomAIGFWelcomeView()
    private let matchingView = RandomAIGFMatchingView()

    // Step 2 elements
    private let pollContainerView = UIView()
    private let pollBackButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    private let launchMatchButton = AnimatedButton(type: .system)
    private let rocketLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MyColors.background

        setupViews()
        bindViewModel()
        
        AmplitudeManager.shared.logEvent(name: "ChatRoulette opened", properties: ["":""])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.resetState()
    }

    // MARK: - Setup
    private func setupViews() {
        setupWelcomeStep()
        setupPollStep()
        setupMatchingStep()
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] step in
            guard let self = self else { return }
            self.welcomeView.isHidden = (step != .welcome)
            self.pollContainerView.isHidden = (step != .poll)
            self.matchingView.isHidden = (step != .matching)

            if step == .matching {
                self.matchingView.startStatusAnimation()
            } else {
                self.matchingView.stopStatusAnimation()
            }
        }

        viewModel.onAvatarUpdated = { [weak self] avatarName in
            self?.matchingView.updateAvatar(named: avatarName)
        }

        viewModel.onMatchCompleted = { [weak self] config in
            let aiChatViewController = AIGFChatViewController()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
            self?.present(aiChatViewController, animated: false)
        }
    }
    
    private func setupWelcomeStep() {
        view.addSubview(welcomeView)
        welcomeView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 8, left: 20, bottom: 16, right: 20))
        }

        welcomeView.onStartTapped = { [weak self] in
            self?.viewModel.startPoll()
        }

        welcomeView.onBackTapped = { [weak self] in
            self?.didTapCloseOrBack()
        }
    }

    private func setupPollStep() {
        view.addSubview(pollContainerView)
        pollContainerView.backgroundColor = .clear
        pollContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 8, left: 20, bottom: 12, right: 20))
        }

        let navBar = makeNavBar(title: "Roulette_Step2_NavTitle".localize(), backButton: pollBackButton)
        pollContainerView.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(isCurrentDeviceiPad() ? 64 : 44)
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCompositionalLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RandomAIGFTagCell.self, forCellWithReuseIdentifier: RandomAIGFTagCell.identifier)
        collectionView.register(RandomAIGFHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: RandomAIGFHeaderView.identifier)

        launchMatchButton.setTitle("Roulette_Step2_LaunchButton".localize(), for: .normal)
        launchMatchButton.titleLabel?.font = isCurrentDeviceiPad() ? .systemFont(ofSize: 24, weight: .bold) : .systemFont(ofSize: 16, weight: .semibold)
        launchMatchButton.setTitleColor(MyColors.textPrimary, for: .normal)
        launchMatchButton.backgroundColor = MyColors.primary
        launchMatchButton.layer.cornerRadius = isCurrentDeviceiPad() ? 24 : 16
        launchMatchButton.addTarget(self, action: #selector(launchMatchTapped), for: .touchUpInside)

        rocketLabel.text = "⚡️"
        rocketLabel.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 24 : 16)
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
            make.height.equalTo(isCurrentDeviceiPad() ? 72 : 54)
        }
    }

    private func setupMatchingStep() {
        view.addSubview(matchingView)
        matchingView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func makeNavBar(title: String, backButton: UIButton) -> UIView {
        let container = UIView()
        
        let config = UIImage.SymbolConfiguration(pointSize: isCurrentDeviceiPad() ? 22 : 15, weight: .bold)
        backButton.setImage(UIImage(systemName: "chevron.backward", withConfiguration: config), for: .normal)
        backButton.tintColor = MyColors.textPrimary
        backButton.backgroundColor = MyColors.cardBackground
        backButton.layer.cornerRadius = isCurrentDeviceiPad() ? 30 : 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = MyColors.separator.cgColor
        backButton.addTarget(self, action: #selector(didTapCloseOrBack), for: .touchUpInside)

        container.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.size.equalTo(isCurrentDeviceiPad() ? 60 : 40)
        }

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: isCurrentDeviceiPad() ? 28 : 18, weight: .bold)
        titleLbl.textColor = MyColors.textPrimary
        container.addSubview(titleLbl)
        titleLbl.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        return container
    }

    @objc private func didTapCloseOrBack() {
        let shouldDismiss = viewModel.handleBackNavigation()
        if shouldDismiss {
            if let nav = navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
    }

    @objc private func launchMatchTapped() {
        viewModel.launchMatch()
    }

    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            let isInterestsSection = sectionIndex == 1
            let isiPad = self.isCurrentDeviceiPad()

            let itemHeight: CGFloat = isiPad ? 58 : 40
            let rowHeight: CGFloat = isiPad ? 68 : 48
            let headerHeight: CGFloat = isiPad ? 55 : 35

            let itemSize = isInterestsSection
                ? NSCollectionLayoutSize(widthDimension: .estimated(120), heightDimension: .absolute(itemHeight))
                : NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(rowHeight))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = isInterestsSection
                ? NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight))
                : NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(rowHeight))

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            if isInterestsSection {
                group.interItemSpacing = .fixed(isiPad ? 14 : 8)
            }

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = isiPad ? 14 : 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: isiPad ? 30 : 20, trailing: 0)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(headerHeight))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }
    
    private func isCurrentDeviceiPad() -> Bool {
        return view.isNeedBigTextForIPad()
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension RandomAIGFViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return APIManager.shared.isABTestRandom ? 3 : 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return viewModel.communicationStyles.count
        case 1: return viewModel.interests.count
        case 2: return APIManager.shared.isABTestRandom ? viewModel.ageThemes.count : 0
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
            text = viewModel.communicationStyles[indexPath.item]
            isSelected = indexPath.item == viewModel.selectedStyleIndex
        case 1:
            text = viewModel.interests[indexPath.item]
            isSelected = indexPath.item == viewModel.selectedInterestIndex
        case 2:
            text = viewModel.ageThemes[indexPath.item]
            isSelected = indexPath.item == viewModel.selectedAdultIndex
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

        header.configure(title: title, step: indexPath.section + 1)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0: viewModel.selectedStyleIndex = indexPath.item
        case 1: viewModel.selectedInterestIndex = indexPath.item
        case 2: viewModel.selectedAdultIndex = indexPath.item
        default: break
        }
        collectionView.reloadSections(IndexSet(integer: indexPath.section))
    }
}
