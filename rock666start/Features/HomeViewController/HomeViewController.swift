import UIKit
import SnapKit

final class HomeViewController: UIViewController {

    // MARK: - Constants
    
    private enum Constants {
        static let hasSeenSwipeHintKey = "hasSeenSwipeHintKey"
    }

    // MARK: - Data
    
    private var roles: [RoleModel] = RoleModel.mockRoles
    
    // MARK: - UI Elements
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = MyColors.background
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
        view.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.9)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = MyColors.primary.cgColor
        view.clipsToBounds = true
        view.alpha = 0 // Спрятана по умолчанию для анимации
        return view
    }()
    
    private let hintIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iv.image = UIImage(systemName: "arrow.down", withConfiguration: config)?
            .withTintColor(MyColors.primary, renderingMode: .alwaysOriginal)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Swipe down to see more"
        label.textColor = MyColors.textPrimary
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    private var hintTopConstraint: Constraint?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTextForIPadIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showHintIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = MyColors.background
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

    // MARK: - Hint Logic
    
    private func showHintIfNeeded() {
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

    // MARK: - iPad Helpers
    
    private func updateTextForIPadIfNeeded() {
        guard view.isNeedBigTextForIPad() else { return }
        
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
        
        if view.isNeedBigTextForIPad() {
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
        
        var selectedAssistant = AIGirlfriendsManager().getAllConfigs().first(where: { $0.avatarImageName == roles[indexPath.row].image })

        if selectedAssistant == nil {
            let selectedAssistantID = UUID().uuidString
            selectedAssistant = AIGirlfriendsConfig(
                id: selectedAssistantID,
                assistantName: roles[indexPath.row].name,
                assistantInfo: roles[indexPath.row].assistantInfo,
                avatarImageName: roles[indexPath.row].image ?? ""
            )
            if let selectedAssistant {
                AIGirlfriendsManager().addConfig(selectedAssistant)
            }
            AIGirlfriendMessagesManager().addMessage(
                AIGFMessageModel(role: "assistant", content: "StartMessage\(roles[indexPath.row].id)".localize()),
                assistantId: selectedAssistantID
            )
        }

        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true

        let aiChatViewController = AIGFChatViewController()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
}
