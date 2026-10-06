import UIKit
import SnapKit

enum PathBase {
    static let path = "HttpsNo"
}

final class HomeViewController: UIViewController {

    // MARK: - Constants
    
    private enum Constants {
        static let hasSeenSwipeHintKey = "hasSeenSwipeHintKey"
        static let hasCompletedOnboardingKey = "hasCompletedOnboardingKey"
    }

    // MARK: - Data
    
    private var roles: [RoleModel] = RoleModel.mockRoles
    private var storedRightBarButtonItems: [UIBarButtonItem]?
    
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

    // Ненавязчивая всплывашка с подсказкой
    private let hintToastView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground.withAlphaComponent(0.9)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.primary.cgColor
        view.clipsToBounds = true
        view.alpha = 0 // Спрятана по умолчанию для анимации
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

    // MARK: - Onboarding & Paywall Logic

    private func checkFirstLaunchAndShowOnboarding() {
        guard !UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey) else { return }
        
        let onboardingVC = OnboardingVC()
        onboardingVC.modalPresentationStyle = .fullScreen
        onboardingVC.isModalInPresentation = true
        
        onboardingVC.onbordingFinishedHandler = { [weak self] in
            guard let self = self else { return }
            onboardingVC.dismiss(animated: true)
            UserDefaults.standard.set(true, forKey: Constants.hasCompletedOnboardingKey)
//            self.presentPaywall() // test111
        }
        
        present(onboardingVC, animated: false)
    }

    private func presentPaywall() {
        // Скрываем кнопки
        setNavigationBarButtonsHidden(true)
        
        let paywallView = PaywallView()
        paywallView.vc = self
        
        // Когда пейволл закрылся — возвращаем кнопки
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
        // Если онбординг ещё не пройден, подсказку пока не показываем
        guard UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey) else { return }
        // Проверяем, показывали ли уже подсказку
        guard !UserDefaults.standard.bool(forKey: Constants.hasSeenSwipeHintKey) else { return }
        
        // Показываем плавно сверху
        hintTopConstraint?.update(offset: 16)
        UIView.animate(withDuration: 0.6, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.hintToastView.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }
    
    private func dismissHint() {
        guard hintToastView.alpha > 0 else { return }
        
        // Запоминаем в UserDefaults, что юзер уже свайпал
        UserDefaults.standard.set(true, forKey: Constants.hasSeenSwipeHintKey)
        
        // Анимированно скрываем
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
        
        let buttons = [settingsButton, chatButton]
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
        return roles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InstagramFeedCell.reuseIdentifier,
            for: indexPath
        ) as? InstagramFeedCell else {
            return UICollectionViewCell()
        }
        
        let role = roles[indexPath.row]
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
        dismissHint() // Скрываем подказку, если юзер сразу тапнул по ячейке
        
        var selectedAssistant = CharactersUseCase().getAllConfigs().first(where: { $0.authorIcon == roles[indexPath.row].image })

        if selectedAssistant == nil {
            let selectedAssistantID = UUID().uuidString
            selectedAssistant = CharactersDataModel(
                id: selectedAssistantID,
                name: roles[indexPath.row].name,
                baseInfo: roles[indexPath.row].assistantInfo,
                authorIcon: roles[indexPath.row].image
            )
            if let selectedAssistant {
                CharactersUseCase().addConfig(selectedAssistant)
            }
            CharactersChatUseCase().addMessage(
                ChatRockStarDataModel(authoreRole: "assistant", theMessage: roles[indexPath.row].greetingMessage),
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
