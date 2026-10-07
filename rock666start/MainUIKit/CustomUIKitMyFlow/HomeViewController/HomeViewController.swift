import UIKit
import SnapKit

enum PathBase {
    static let path = "HttpsNo"
}

final class HomeViewController: UIViewController {

    // MARK: - Categories Enum
    
    private enum CategoryType: Int, CaseIterable {
        case lifelike = 0
        case anime
        case experienced
        case drama
        
        var title: String {
            switch self {
            case .lifelike: return "Lifelike"
            case .anime: return "Anime"
            case .experienced: return "Experienced"
            case .drama: return "Drama"
            }
        }
        
        ///  ID ботов для каждой категории
        var allowedIDs: Set<Int> {
            switch self {
            case .lifelike:
                return [27, 1, 28, 2, 3, 4]
            case .anime:
                return [11, 29, 30, 12, 31, 32]
            case .experienced:
                return [34, 35, 36]
            case .drama:
                return [33]
            }
        }
        
        var allowedIDs2: Set<Int> {
            switch self {
            case .lifelike:
                return Set(0...10)
            case .anime:
                return Set(11...20)
            case .experienced:
                return Set(21...25)
            case .drama:
                return [26]
            }
        }
    }

    // MARK: - Constants
    
    private enum Constants {
        static let hasSeenSwipeHintKey = "hasSeenSwipeHintKey"
        static let hasCompletedOnboardingKey = "hasCompletedOnboardingKey"
    }

    // MARK: - Data
    
    private lazy var allRoles: [RoleModel] = getRandomAvatars()
    private var filteredRoles: [RoleModel] = []
    private var storedRightBarButtonItems: [UIBarButtonItem]?
    private var currentCategory: CategoryType = .lifelike
    
    // MARK: - UI Elements
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = BasePalitColors.background
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.register(InstagramFeedCell.self, forCellWithReuseIdentifier: InstagramFeedCell.reuseIdentifier)
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()

    // Кнопка переключения категорий
    private lazy var categoryMenuButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.baseBackgroundColor = BasePalitColors.primary
        config.baseForegroundColor = BasePalitColors.primary
        config.cornerStyle = .capsule
        config.buttonSize = .small
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: 12,
            bottom: 4,
            trailing: 10
        )
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        
        // Запрещаем перенос текста на две строки
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        
        // Задаем жесткий размер: 135 pt хватит даже для "Experienced" с запасом
        button.frame = CGRect(x: 0, y: 0, width: 135, height: 32)
        button.snp.makeConstraints { make in
            make.width.equalTo(135)
            make.height.equalTo(32)
        }
        
        return button
    }()

    // Ненавязчивая всплывашка с подсказкой
    private let hintToastView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.9)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.primary.cgColor
        view.clipsToBounds = true
        view.alpha = 0
        return view
    }()
    
    private let hintIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iv.image = UIImage(systemName: "arrow.down", withConfiguration: config)?
            .withTintColor(BasePalitColors.primary, renderingMode: .alwaysOriginal)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Swipe down to see more"
        label.textColor = BasePalitColors.textPrimary
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    private var hintTopConstraint: Constraint?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filterRoles(for: .lifelike, animated: false)
        setupUI()
        setupNavigationBar()
        iPadCheck()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkFirstLaunchAndShowOnboarding()
        showHintIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func getRandomAvatars() -> [RoleModel] {
        let random = Bool.random()
        //        if random {
        if BackendService.shared.currentData.aiText.isEmpty {
            return RoleModel.mockRoles
        } else if random {
            return RoleModel.mockRoles2
        } else {
            return RoleModel.mockRoles2 // test it
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        setupHintToast()
    }
    
    private func setupHintToast() {
        view.addSubview(hintToastView)
        hintToastView.addSubview(hintIconImageView)
        hintToastView.addSubview(hintLabel)
        
        hintToastView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            self.hintTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide).offset(-60).constraint
            make.height.equalTo(40)
        }
        
        hintIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        
        hintLabel.snp.makeConstraints { make in
            make.leading.equalTo(hintIconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Category Filtering & Menu Logic

    private func updateCategoryMenu() {
        let actions = CategoryType.allCases.map { category in
            UIAction(
                title: category.title,
                state: category == currentCategory ? .on : .off
            ) { [weak self] _ in
                self?.dismissHint()
                self?.filterRoles(for: category, animated: true)
            }
        }
        
        categoryMenuButton.menu = UIMenu(title: "Select Category", children: actions)
        
        // Обновляем текст, сохраняя конфигурацию
        var config = categoryMenuButton.configuration
        var attributedTitle = AttributedString(currentCategory.title)
        attributedTitle.font = .systemFont(ofSize: 13, weight: .bold)
        config?.attributedTitle = attributedTitle
        categoryMenuButton.configuration = config
    }

    private func filterRoles(for category: CategoryType, animated: Bool = true) {
        currentCategory = category
        let targetIDs = BackendService.shared.currentData.aiText.isEmpty ? category.allowedIDs : category.allowedIDs2
        filteredRoles = allRoles.filter { targetIDs.contains($0.id) }
        
        updateCategoryMenu()
        collectionView.reloadData()
        
        if !filteredRoles.isEmpty {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: animated)
        }
    }

    // MARK: - Onboarding & Paywall Logic

    private func checkFirstLaunchAndShowOnboarding() {
        guard !UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey) else { return }
        
        let onboardingVC = OnboardingVC()
        onboardingVC.modalPresentationStyle = .fullScreen
        onboardingVC.isModalInPresentation = true
        
        onboardingVC.onbordingFinishedHandler = {
            onboardingVC.dismiss(animated: true)
            UserDefaults.standard.set(true, forKey: Constants.hasCompletedOnboardingKey)
        }
        
        present(onboardingVC, animated: false)
    }

    private func presentPaywall() {
        setNavigationBarButtonsHidden(true)
        
        let paywallView = PaywallView()
        paywallView.vc = self
        
        paywallView.onPaywallClosedHandler = { [weak self] in
            guard let self = self else { return }
            self.setNavigationBarButtonsHidden(false)
            paywallView.removeFromSuperview()
        }
        
        view.addSubview(paywallView)

        paywallView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Hint Logic
    
    private func showHintIfNeeded() {
        guard UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey) else { return }
        guard !UserDefaults.standard.bool(forKey: Constants.hasSeenSwipeHintKey) else { return }
        
        hintTopConstraint?.update(offset: 16)
        UIView.animate(withDuration: 0.6, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.hintToastView.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }
    
    private func dismissHint() {
        guard hintToastView.alpha > 0 else { return }
        
        UserDefaults.standard.set(true, forKey: Constants.hasSeenSwipeHintKey)
        
        hintTopConstraint?.update(offset: -60)
        UIView.animate(withDuration: 0.4, animations: {
            self.hintToastView.alpha = 0.0
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Navigation Bar Setup

    private func setupNavigationBar() {
        let chatImage = UIImage(systemName: "bubble.right")
        let settingsImage = UIImage(systemName: "line.3.horizontal")
        
        // Контейнер гарантирует, что NavigationBar не сожмет кнопку
        let categoryContainer = UIView(frame: CGRect(x: 0, y: 0, width: 135, height: 32))
        categoryContainer.addSubview(categoryMenuButton)
        categoryMenuButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let categoryItem = UIBarButtonItem(customView: categoryContainer)
        
        let chatButton = UIBarButtonItem(
            image: chatImage,
            style: .plain,
            target: self,
            action: #selector(didTapChatButton)
        )
        
        let settingsButton = UIBarButtonItem(
            image: settingsImage,
            style: .plain,
            target: self,
            action: #selector(didTapSettingsButton)
        )
        
        chatButton.tintColor = BasePalitColors.textPrimary
        settingsButton.tintColor = BasePalitColors.textPrimary
        
        let buttons = [settingsButton, chatButton, categoryItem]
        storedRightBarButtonItems = buttons
        navigationItem.rightBarButtonItems = buttons
    }

    private func setNavigationBarButtonsHidden(_ isHidden: Bool) {
        if isHidden {
            if navigationItem.rightBarButtonItems != nil {
                storedRightBarButtonItems = navigationItem.rightBarButtonItems
            }
            navigationItem.setRightBarButtonItems(nil, animated: false)
        } else {
            navigationItem.setRightBarButtonItems(storedRightBarButtonItems, animated: false)
        }
    }

    // MARK: - Actions

    @objc private func didTapChatButton() {
        let chatListVC = InstChatListViewController()
        navigationController?.pushViewController(chatListVC, animated: true)
    }

    @objc private func didTapSettingsButton() {
        let settingsVC = SettingsVC()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // MARK: - iPad Helpers
    
    private func iPadCheck() {
        guard view.isIPad() else { return }
        
        hintLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        hintToastView.layer.cornerRadius = 24
        
        hintToastView.snp.updateConstraints { make in
            make.height.equalTo(48)
        }
        
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredRoles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InstagramFeedCell.reuseIdentifier,
            for: indexPath
        ) as? InstagramFeedCell else {
            return UICollectionViewCell()
        }
        
        let role = filteredRoles[indexPath.row]
        cell.configure(with: role)
        
        if view.isIPad() {
            cell.adaptForIPad()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
        return CGSize(width: collectionView.bounds.width, height: safeAreaHeight)
    }

    // MARK: - UIScrollViewDelegate (Детект свайпа для скрытия подсказки)
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissHint()
    }

    // MARK: - Action on Tap
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismissHint()
        
        let role = filteredRoles[indexPath.row]
        var selectedAssistant = CharactersUseCase().getAllConfigs().first(where: { $0.authorIcon == role.image })

        if selectedAssistant == nil {
            let selectedAssistantID = UUID().uuidString
            selectedAssistant = CharactersDataModel(
                id: selectedAssistantID,
                name: role.name,
                baseInfo: role.assistantInfo,
                authorIcon: role.image
            )
            if let selectedAssistant {
                CharactersUseCase().addConfig(selectedAssistant)
            }
            CharactersChatUseCase().addMessage(
                ChatRockStarDataModel(authoreRole: "bot", theMessage: BackendService.shared.currentData.aiText.isEmpty ? role.greetingMessage : role.greetingMessage2),
                assistantId: selectedAssistantID
            )
        }
        
        MyGovnoSingltone.shared.selectedAICompanion = selectedAssistant
        MyGovnoSingltone.shared.currentMessageFirst = true

        let aiChatViewController = RockStarChatVC()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
}
