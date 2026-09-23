import UIKit
import SnapKit

class DressUpVC: UIViewController {
    private let outfitOptions = (1...19).map { "outfit_\($0)" }
    private let waifuImages   = (1...19).map { "waifuInOutfit_\($0)" }
    private let outfitPrice = 5
    private var currentAvatarImageName = ""
    
    private var userBalance: Int = CoinsService.shared.getCoins()
    
    // UI Elements: Стандартный кастомный Навбар
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let scorePillView = UIView()
    private let titleLabel = UILabel()
    
    private let waifuImageView = UIImageView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    private let balanceView = UIView()
    private let coinIcon = UIImageView()
    private let balanceLabel = UILabel()
    
    private let chatButton = UIButton(type: .system)
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 140)
        layout.minimumLineSpacing = 12
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(OutfitCell.self, forCellWithReuseIdentifier: "OutfitCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateBalanceLabel()
        updateChatButtonState(for: "")
        
        AmplitudeManager.shared.logEvent(name: "wardrobe opened", properties: ["":""])
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = MyColors.background
        
        // --- Единый Кастомный Навбар ---
        setupCustomNavigationBar()
        
        // --- Остальные элементы ---
        balanceView.backgroundColor = MyColors.cardBackground
        balanceView.layer.cornerRadius = 15
        balanceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openCoins)))
        
        coinIcon.image = UIImage(systemName: "circle.fill")
        coinIcon.tintColor = .systemYellow
        balanceView.addSubview(coinIcon)
        
        balanceLabel.font = .systemFont(ofSize: 14, weight: .bold)
        balanceLabel.textColor = .white
        balanceView.addSubview(balanceLabel)
        
        waifuImageView.contentMode = .scaleAspectFill
        waifuImageView.clipsToBounds = true
        waifuImageView.layer.cornerRadius = 30
        waifuImageView.backgroundColor = MyColors.cardBackground
        waifuImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: "waifuInOutfit_start")
        waifuImageView.isUserInteractionEnabled = true
        waifuImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(waifuImageTapped)))
        view.addSubview(waifuImageView)
        view.addSubview(balanceView)

        blurEffectView.layer.cornerRadius = 30
        blurEffectView.clipsToBounds = true
        blurEffectView.alpha = 0
        waifuImageView.addSubview(blurEffectView)
        
        view.addSubview(collectionView)
        
        chatButton.setTitle("LET'S START CHATTING", for: .normal)
        chatButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .black)
        chatButton.backgroundColor = MyColors.primary
        chatButton.setTitleColor(.white, for: .normal)
        chatButton.layer.cornerRadius = 20
        chatButton.addTarget(self, action: #selector(chatTapped), for: .touchUpInside)
        view.addSubview(chatButton)
    }

    private func setupCustomNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = MyColors.background
        
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Тонкий разделитель
        navSeparator.backgroundColor = MyColors.separator
        customNavBar.addSubview(navSeparator)
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // Кнопка Назад
        let backConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let backImage = UIImage(systemName: "chevron.left", withConfiguration: backConfig)
        
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = MyColors.textPrimary
        backButton.backgroundColor = MyColors.cardBackground
        backButton.layer.cornerRadius = 20
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // Кнопка Инфо
        let infoConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let infoImage = UIImage(systemName: "info.circle", withConfiguration: infoConfig)
        
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = MyColors.primary
        infoButton.backgroundColor = MyColors.cardBackground
        infoButton.layer.cornerRadius = 20
        infoButton.addTarget(self, action: #selector(showRules), for: .touchUpInside)
        customNavBar.addSubview(infoButton)
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // "Пилл" под заголовок
        scorePillView.backgroundColor = MyColors.cardBackground
        scorePillView.layer.cornerRadius = 18
        scorePillView.layer.borderWidth = 1
        scorePillView.layer.borderColor = MyColors.separator.cgColor
        customNavBar.addSubview(scorePillView)
        
        scorePillView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(36)
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(infoButton.snp.leading).offset(-8)
        }
        
        titleLabel.text = "Wardrobe".localize().uppercased()
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center
        scorePillView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }
    }
    
    private func setupConstraints() {
        balanceView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(70)
        }
        
        coinIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }
        
        chatButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(30)
            make.height.equalTo(54)
        }
        
        waifuImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
            make.height.equalToSuperview().multipliedBy(0.45)
        }
        
        blurEffectView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(waifuImageView.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(chatButton.snp.top).offset(-15)
        }
    }
    
    // MARK: - Actions
    private func updateBalanceLabel() {
        balanceLabel.text = "\(userBalance)"
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func chatTapped() {
        AmplitudeManager.shared.logEvent(name: "wardrobe chatTapped", properties: ["":""])

        let userDefaultsKey = "wardrobe_assistant_id"
        let selectedAssistantID: String
        
        if let savedID = UserDefaults.standard.string(forKey: userDefaultsKey) {
            selectedAssistantID = savedID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: userDefaultsKey)
            selectedAssistantID = newID
        }

        let selectedAssistant = AIGirlfriendsConfig(
            id: selectedAssistantID,
            assistantName: "mini.game.aigf.mainname".localize(),
            assistantInfo: "",
            avatarImageName: currentAvatarImageName
        )
        
        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true
        
        let aiChatViewController = AIGFChatViewController()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
    
    @objc private func openCoins() {
        let coinsView = CoinPaywall(isDressUp: true)
        coinsView.coinsAddedHandler = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.userBalance = CoinsService.shared.getCoins()
                self?.updateBalanceLabel()
            }
        }
        view.addSubview(coinsView)
        coinsView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    @objc private func showRules() {
        let alert = UIAlertController(title: "Outfits.INSTRUCTIONS".localize(), message: "Apparel.INSTRUCTIONS".localize(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Understand".localize(), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func waifuImageTapped() {
        guard blurEffectView.alpha == 0 else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let fullScreenView = PreviewImageView(image: waifuImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
    
    private func isOutfitPurchased(id: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "purchased_outfit_\(id)")
    }
    
    private func purchaseOutfit(id: String) {
        UserDefaults.standard.set(true, forKey: "purchased_outfit_\(id)")
        collectionView.reloadData()
    }
}

// MARK: - CollectionView Logic
extension DressUpVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return outfitOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutfitCell", for: indexPath) as? OutfitCell else { return UICollectionViewCell() }
        let outfitId = outfitOptions[indexPath.item]
        let isBought = isOutfitPurchased(id: outfitId)
        cell.configure(imageName: outfitId, price: outfitPrice, isPurchased: isBought)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let outfitId = outfitOptions[indexPath.item]
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        
        waifuImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: waifuImages[indexPath.item])
        currentAvatarImageName = waifuImages[indexPath.item]
        
        AmplitudeManager.shared.logEvent(name: "wardrobe cell tapped", properties: ["isOutfitPurchased":"\(isOutfitPurchased(id: outfitId))"])

        if isOutfitPurchased(id: outfitId) {
            blurEffectView.alpha = 0
        } else {
            blurEffectView.alpha = 1
            showPurchaseAlert(for: outfitId)
        }
        
        updateChatButtonState(for: outfitId)
    }
    
    private func showPurchaseAlert(for outfitId: String) {
        let alert = UIAlertController(title: "New Outfit", message: "Do you want to buy this outfit for your waifu?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Buy for 5 coins", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
            if self.userBalance >= self.outfitPrice {
                AmplitudeManager.shared.logEvent(name: "outfit purchased", properties: ["":""])

                if CoinsService.shared.spendCoins(self.outfitPrice) {
                    self.userBalance -= self.outfitPrice
                    self.updateBalanceLabel()
                    self.purchaseOutfit(id: outfitId)
                    self.blurEffectView.alpha = 0
                    self.updateChatButtonState(for: outfitId)
                }
            } else {
                let enoughAlert = NotEnoughCoinsAlert()
                enoughAlert.okButtonTappedHandler = { [weak self] in
                    self?.openCoins()
                    enoughAlert.removeFromSuperview()
                }
                enoughAlert.show(on: self)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateChatButtonState(for outfitId: String) {
        let isBought = isOutfitPurchased(id: outfitId)
        let isAvailable = !outfitId.isEmpty && isBought
        chatButton.isEnabled = isAvailable
        UIView.animate(withDuration: 0.2) {
            self.chatButton.backgroundColor = isAvailable ? MyColors.primary : MyColors.textSecondary
            self.chatButton.alpha = isAvailable ? 1.0 : 0.5
        }
    }
}
