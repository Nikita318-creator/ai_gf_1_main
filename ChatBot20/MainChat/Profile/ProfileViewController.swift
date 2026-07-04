import UIKit
import SnapKit

struct AssistantProfile {
    let id: String
    let avatarImageName: String
    let name: String
    let age: Int
    let country: String
    let city: String
    let bio: String
}

class ProfileViewController: UIViewController {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
        static let gradientStart = UIColor(red: 0.15, green: 0.15, blue: 0.16, alpha: 1.0)
        static let gradientEnd = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    }
    
    // MARK: - Constants
    private struct Constants {
        static let imageSize: CGFloat = UIScreen.main.bounds.width
        static let cornerRadius: CGFloat = 24
        static let buttonSize: CGFloat = 44
        static let callButtonSize: CGFloat = 64
        static let geoIconSize: CGFloat = 20
        static let padding: CGFloat = 20
        static let cardPadding: CGFloat = 24
        static let shadowRadius: CGFloat = 12
        static let shadowOpacity: Float = 0.25
    }
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    private let contentView = UIView()
    
    // Gradient background for the entire view
    private let gradientBackgroundLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [TelegramColors.gradientStart.cgColor, TelegramColors.gradientEnd.cgColor]
        gradient.locations = [0.0, 1.0]
        return gradient
    }()
    
    // Image container with shadow
    private let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = TelegramColors.cardBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = Constants.shadowRadius
        view.layer.shadowOpacity = Constants.shadowOpacity
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Constants.cornerRadius
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
        return imageView
    }()
    
    // Gradient overlay on image
    private let imageGradientOverlay: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.3).cgColor]
        gradient.locations = [0.6, 1.0]
        gradient.cornerRadius = Constants.cornerRadius
        return gradient
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = Constants.buttonSize / 2
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.layer.masksToBounds = false
        
        let image = UIImage(systemName: "chevron.backward")?.withConfiguration(UIImage.SymbolConfiguration(weight: .bold))
        button.setImage(image, for: .normal)
        
        return button
    }()
    
    private let clearChatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ClearChatHistory".localize(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left:16, bottom: 10, right: 16)
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = button.bounds
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false
        button.insertSubview(blurView, at: 0)
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3
        button.layer.masksToBounds = false
        
        return button
    }()
    
    // Info card with shadow
    private let infoCardView: UIView = {
        let view = UIView()
        view.backgroundColor = TelegramColors.cardBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = Constants.shadowRadius
        view.layer.shadowOpacity = Constants.shadowOpacity
        view.layer.masksToBounds = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = TelegramColors.textPrimary
        return label
    }()
    
    private let ageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = TelegramColors.textSecondary
        return label
    }()
    
    private let geoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = TelegramColors.messageBackground
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let geoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    private let geoIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.and.ellipse")
        imageView.tintColor = TelegramColors.primary
        imageView.snp.makeConstraints { make in
            make.size.equalTo(Constants.geoIconSize)
        }
        return imageView
    }()
    
    private let geoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = TelegramColors.textPrimary
        return label
    }()
    
    // Bio card with shadow
    private let bioCardView: UIView = {
        let view = UIView()
        view.backgroundColor = TelegramColors.cardBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = Constants.shadowRadius
        view.layer.shadowOpacity = Constants.shadowOpacity
        view.layer.masksToBounds = false
        return view
    }()
    
    private let bioHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Bio".localize()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = TelegramColors.textPrimary
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = TelegramColors.textSecondary
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    // Enhanced call button with gradient
    private let callButton: UIButton = {
        let button = UIButton(type: .system)
        
        let image = UIImage(systemName: "phone.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .bold))
        
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        button.backgroundColor = UIColor(red: 0.15, green: 0.50, blue: 0.75, alpha: 1.0)
        
        button.layer.cornerRadius = Constants.callButtonSize / 2
        
        button.layer.shadowColor = UIColor(red: 0.25, green: 0.80, blue: 0.95, alpha: 1.0).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 16
        button.layer.shadowOpacity = 0.4
        button.layer.masksToBounds = false
        
        return button
    }()
    
    // Добавляем иконку чата (по умолчанию скрыта, если не isFeed)
    private let chatButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "message.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .bold))
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = TelegramColors.primary
        button.layer.cornerRadius = Constants.callButtonSize / 2
        
        button.layer.shadowColor = TelegramColors.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 16
        button.layer.shadowOpacity = 0.4
        button.layer.masksToBounds = false
        return button
    }()
    
    // MARK: - Properties
    private let assistant: AssistantProfile
    private var giftsName: [String] = CoinsService.shared.getSentGifts(for: MainHelper.shared.currentAssistant?.id ?? "")
    
    // MARK: - Gifts Section UI Components
    private let giftsSeparator = UIView()
    private let giftsLabel = UILabel()
    private let giftsContainerView = UIView()
    private let emptyGiftsLabel = UILabel()
    private let sendGiftButton = UIButton(type: .system)
    private let giftsCollectionView: UICollectionView
    
    private var giftsCollectionViewHeightConstraint: Constraint?

    var sendGiftTappedHandler: (() -> Void)?
    
    private let isFeed: Bool
    private let notFriendProfileAvatar: UIImage?
    
    // MARK: - Init
    init(assistant: AssistantProfile, isFeed: Bool = false, notFriendProfileAvatar: UIImage? = nil) {
        self.isFeed = isFeed
        self.notFriendProfileAvatar = notFriendProfileAvatar

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        self.giftsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        self.assistant = assistant
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureProfile()
        setupActions()
        setupAnimations()
        updateTextForIPadIfNeeded()
        
        AnalyticService.shared.logEvent(name: "Profile opened", properties: ["":""])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientBackgroundLayer.frame = view.bounds
        
        if let blurView = clearChatButton.subviews.first(where: { $0 is UIVisualEffectView }) {
            blurView.frame = clearChatButton.bounds
        }
        
        imageGradientOverlay.frame = profileImageView.bounds
        
        if let gradientLayer = callButton.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = callButton.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateAppearance()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.layer.insertSublayer(gradientBackgroundLayer, at: 0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(profileImageView)
        profileImageView.layer.addSublayer(imageGradientOverlay)
        
        contentView.addSubview(infoCardView)
        infoCardView.addSubview(nameLabel)
        infoCardView.addSubview(ageLabel)
        infoCardView.addSubview(geoContainerView)
        geoContainerView.addSubview(geoStackView)
        
        contentView.addSubview(bioCardView)
        bioCardView.addSubview(bioHeaderLabel)
        bioCardView.addSubview(bioLabel)
        
        contentView.addSubview(callButton)
        contentView.addSubview(chatButton) // Добавляем на экран
        
        geoStackView.addArrangedSubview(geoIcon)
        geoStackView.addArrangedSubview(geoLabel)
        
        view.addSubview(backButton)
        view.addSubview(clearChatButton)
        
        // MARK: - Gifts Section
        contentView.addSubview(giftsSeparator)
        contentView.addSubview(giftsLabel)
        
        print(giftsName)
        if giftsName.isEmpty {
            contentView.addSubview(giftsContainerView)
            giftsContainerView.addSubview(emptyGiftsLabel)
            giftsContainerView.addSubview(sendGiftButton)
        } else {
            contentView.addSubview(giftsCollectionView)
            giftsCollectionView.backgroundColor = .clear
            giftsCollectionView.showsVerticalScrollIndicator = false
            giftsCollectionView.dataSource = self
            giftsCollectionView.delegate = self
            giftsCollectionView.register(GiftCell.self, forCellWithReuseIdentifier: "GiftCell")
        }
        
        setupGiftsUI()
        setupConstraints()
        
        if isFeed {
            clearChatButton.isHidden = true
            giftsContainerView.isHidden = true
            giftsLabel.isHidden = true
            giftsCollectionView.isHidden = true
            chatButton.isHidden = false
        } else {
            chatButton.isHidden = true
        }
    }
    
    private func setupGiftsUI() {
        giftsSeparator.backgroundColor = TelegramColors.separator
        
        giftsLabel.text = "gift.YourGifts".localize()
        giftsLabel.font = .systemFont(ofSize: 22, weight: .bold)
        giftsLabel.textColor = .white
        
        giftsContainerView.backgroundColor = TelegramColors.cardBackground
        giftsContainerView.layer.cornerRadius = Constants.cornerRadius
        giftsContainerView.layer.shadowColor = UIColor.black.cgColor
        giftsContainerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        giftsContainerView.layer.shadowRadius = Constants.shadowRadius
        giftsContainerView.layer.shadowOpacity = Constants.shadowOpacity
        giftsContainerView.layer.masksToBounds = false
        
        if giftsName.isEmpty {
            emptyGiftsLabel.text = "gift.doesntHaveGifts".localize()
            emptyGiftsLabel.textColor = TelegramColors.textSecondary
            emptyGiftsLabel.font = .systemFont(ofSize: 16, weight: .regular)
            emptyGiftsLabel.numberOfLines = 0
            emptyGiftsLabel.textAlignment = .center
            
            sendGiftButton.setTitle("SendGift".localize(), for: .normal)
            sendGiftButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
            sendGiftButton.backgroundColor = TelegramColors.primary
            sendGiftButton.setTitleColor(.white, for: .normal)
            sendGiftButton.layer.cornerRadius = 15
            
            sendGiftButton.layer.shadowColor = TelegramColors.primary.cgColor
            sendGiftButton.layer.shadowOffset = CGSize(width: 0, height: 4)
            sendGiftButton.layer.shadowRadius = 12
            sendGiftButton.layer.shadowOpacity = 0.4
            
            sendGiftButton.addTarget(self, action: #selector(sendGiftButtonTapped), for: .touchUpInside)
            addTouchAnimation(to: sendGiftButton)
        }
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        imageContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.padding)
            make.leading.trailing.equalToSuperview().inset(Constants.padding)
            make.height.equalTo(Constants.imageSize - Constants.padding * 2)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Constants.padding)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(Constants.padding)
            make.size.equalTo(Constants.buttonSize)
        }
        
        clearChatButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Constants.padding)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-Constants.padding)
        }
        
        // Перестраиваем констрейнты кнопок в зависимости от флага isFeed
        if isFeed {
            // Кнопка чата слева, кнопка звонка справа, центрированы относительно экрана
            chatButton.snp.makeConstraints { make in
                make.size.equalTo(Constants.callButtonSize)
                make.trailing.equalTo(contentView.snp.centerX).offset(-12)
                make.top.equalTo(imageContainerView.snp.bottom).offset(-Constants.callButtonSize / 2)
            }
            
            callButton.snp.makeConstraints { make in
                make.size.equalTo(Constants.callButtonSize)
                make.leading.equalTo(contentView.snp.centerX).offset(12)
                make.top.equalTo(imageContainerView.snp.bottom).offset(-Constants.callButtonSize / 2)
            }
        } else {
            // Оставляем дефолтное положение по центру
            callButton.snp.makeConstraints { make in
                make.size.equalTo(Constants.callButtonSize)
                make.centerX.equalToSuperview()
                make.top.equalTo(imageContainerView.snp.bottom).offset(-Constants.callButtonSize / 2)
            }
        }
        
        infoCardView.snp.makeConstraints { make in
            // infoCardView цепляется за callButton, так как обе кнопки на одном уровне по Y, это отлично сработает
            make.top.equalTo(callButton.snp.bottom).offset(Constants.padding)
            make.leading.trailing.equalToSuperview().inset(Constants.padding)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.cardPadding)
            make.leading.trailing.equalToSuperview().inset(Constants.cardPadding)
        }
        
        ageLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(Constants.cardPadding)
        }
        
        geoContainerView.snp.makeConstraints { make in
            make.top.equalTo(ageLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(Constants.cardPadding)
            make.bottom.equalToSuperview().offset(-Constants.cardPadding)
        }
        
        geoStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        bioCardView.snp.makeConstraints { make in
            make.top.equalTo(infoCardView.snp.bottom).offset(Constants.padding)
            make.leading.trailing.equalToSuperview().inset(Constants.padding)
        }
        
        bioHeaderLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Constants.cardPadding)
        }
        
        bioLabel.snp.makeConstraints { make in
            make.top.equalTo(bioHeaderLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(Constants.cardPadding)
        }
        
        giftsSeparator.snp.makeConstraints { make in
            make.top.equalTo(bioCardView.snp.bottom).offset(Constants.padding)
            make.leading.trailing.equalToSuperview().inset(Constants.padding)
            make.height.equalTo(1)
        }
        
        giftsLabel.snp.makeConstraints { make in
            make.top.equalTo(giftsSeparator.snp.bottom).offset(Constants.padding)
            make.leading.equalToSuperview().inset(Constants.padding)
        }
        
        if giftsName.isEmpty {
            giftsContainerView.snp.makeConstraints { make in
                make.top.equalTo(giftsLabel.snp.bottom).offset(Constants.padding)
                make.leading.trailing.equalToSuperview().inset(Constants.padding)
                make.bottom.equalToSuperview().inset(Constants.padding)
            }
            emptyGiftsLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(Constants.cardPadding)
            }
            sendGiftButton.snp.makeConstraints { make in
                make.top.equalTo(emptyGiftsLabel.snp.bottom).offset(20)
                make.leading.trailing.equalToSuperview().inset(Constants.cardPadding)
                make.height.equalTo(50)
                make.bottom.equalToSuperview().inset(Constants.cardPadding)
            }
        } else {
            giftsCollectionView.snp.makeConstraints { make in
                make.top.equalTo(giftsLabel.snp.bottom).offset(Constants.padding)
                make.leading.trailing.equalToSuperview().inset(Constants.padding)
                make.bottom.equalToSuperview().inset(Constants.padding)
                self.giftsCollectionViewHeightConstraint = make.height.equalTo(0).constraint
            }
            updateGiftsCollectionViewHeight()
        }
    }
    
    private func updateGiftsCollectionViewHeight() {
        giftsCollectionView.reloadData()
        giftsCollectionView.layoutIfNeeded() // Принудительно обновляем лейаут
        let contentHeight = giftsCollectionView.collectionViewLayout.collectionViewContentSize.height
        giftsCollectionViewHeightConstraint?.update(offset: contentHeight)

        // Обновляем констрейнты родительского ScrollView, чтобы контент прокручивался
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(giftsCollectionView.snp.bottom).offset(Constants.padding)
        }
    }
    
    // MARK: - Animations
    private func setupAnimations() {
        callButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: 20)
        callButton.alpha = 0
        
        chatButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: 20)
        chatButton.alpha = 0
        
        infoCardView.transform = CGAffineTransform(translationX: 0, y: 30)
        infoCardView.alpha = 0
        
        bioCardView.transform = CGAffineTransform(translationX: 0, y: 30)
        bioCardView.alpha = 0
    }
    
    private func animateAppearance() {
        UIView.animate(withDuration: 0.6, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.callButton.transform = .identity
            self.callButton.alpha = 1
            self.chatButton.transform = .identity
            self.chatButton.alpha = 1
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.3, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.infoCardView.transform = .identity
            self.infoCardView.alpha = 1
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.4, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
            self.bioCardView.transform = .identity
            self.bioCardView.alpha = 1
        }
    }
    
    // MARK: - Data Configuration
    private func configureProfile() {
        if MainHelper.shared.isMode {
            if assistant.avatarImageName.contains("ind1") {
                profileImageView.image = UIImage(named: "ind5")
            } else if assistant.avatarImageName.contains("latina16") {
                profileImageView.image = UIImage(named: "latina11")
            } else if assistant.avatarImageName == "1" {
                profileImageView.image = UIImage(named: "pic109")
            } else if assistant.avatarImageName == "5" {
                profileImageView.image = UIImage(named: "photo113")
            } else if assistant.avatarImageName == "6" {
                profileImageView.image = UIImage(named: "photo57")
            } else {
                profileImageView.image = UIImage(named: assistant.avatarImageName)
            }
        } else {
            profileImageView.image = UIImage(named: assistant.avatarImageName)
        }

        nameLabel.text = assistant.name
        ageLabel.text = "\(assistant.age) y.o."
        geoLabel.text = "\(assistant.city), \(assistant.country)"
        bioLabel.text = assistant.bio
        
        if isFeed, assistant.avatarImageName.isEmpty {
            profileImageView.image = notFriendProfileAvatar ?? UIImage(systemName: "person.circle.fill")
            profileImageView.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        clearChatButton.addTarget(self, action: #selector(clearChatButtonTapped), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside) // Добавляем таргет
        
        addTouchAnimation(to: backButton)
        addTouchAnimation(to: clearChatButton)
        addTouchAnimation(to: callButton, scale: 0.8)
        addTouchAnimation(to: chatButton, scale: 0.8) // Добавляем анимацию нажатия
    }
    
    private func addTouchAnimation(to button: UIButton, scale: CGFloat = 0.8) {
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func callButtonTapped() {
        MainHelper.shared.setIsCalledFirst(false)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        guard IAPService.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        let callVC = CallViewController(assistant: self.assistant, avatarImage: notFriendProfileAvatar)
        callVC.modalPresentationStyle = .fullScreen
        present(callVC, animated: true, completion: nil)
    }
    
    @objc private func chatButtonTapped() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        AnalyticService.shared.logEvent(name: "ProfileViewController chatButtonTapped", properties: ["":""])
        
        guard IAPService.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        
        MainHelper.shared.isCurrentAssistantPremium = false
        MainHelper.shared.isCurrentAssistantPremiumVoice = false
        MainHelper.shared.isVoiceChat = false
        MainHelper.shared.currentAssistant = AssistantConfig(
            id: assistant.id,
            assistantName: assistant.name,
            aiModel: .gemini2,
            tone: .neutral,
            style: .neutral,
            expertise: .casual,
            assistantInfo: "",
            userInfo: "",
            avatarImageName: ""
        )
        MainHelper.shared.currentAssistantImage = notFriendProfileAvatar
        MainHelper.shared.isFirstMessageInChat = true
        
        let aiChatViewController = MainChatVC()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
    
    @objc private func profileImageViewTapped() {
        let fullScreenView = FullScreenImageView(image: profileImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
    
    @objc private func clearChatButtonTapped() {
        AnalyticService.shared.logEvent(name: "Profile clearChatButtonTapped", properties: ["":""])

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        AnalyticService.shared.logEvent(name: "clearChatButtonTapped", properties: ["":""])
        
        let alertController = UIAlertController(
            title: "DeleteChatHistoryTitle".localize(),
            message: "DeleteChatHistoryMessage".localize(),
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel".localize(), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let deleteAction = UIAlertAction(title: "Delete".localize(), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            let assistantId = self.assistant.id
            MessageHistoryService().getAllMessages(forAssistantId: assistantId).forEach {
                MessageHistoryService().deleteMessage(id: $0.id ?? "")
            }
            
            print("История чата с ID \(assistantId) успешно удалена.")
        }
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func sendGiftButtonTapped() {
        AnalyticService.shared.logEvent(name: "Profile sendGiftButtonTapped", properties: ["":""])

        sendGiftTappedHandler?()
    }
    
    // MARK: - Helper
    private func showSubs() {
        let subsView = SubsView()
        subsView.vc = self
        
        AnalyticService.shared.logEvent(name: "showSubs from Profile", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            if self.view.isCurrentDeviceiPad() {
                subsView.scrollToBottom()
//            }
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return giftsName.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GiftCell", for: indexPath) as? GiftCell else {
            return UICollectionViewCell()
        }
        let giftImageName = giftsName[indexPath.row]
        cell.configure(with: GiftItem(imageName: giftImageName, price: 0), isProfile: true)
        cell.backgroundColor = .clear
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16 * 2) / 3
        let height = width * 1.2
        return CGSize(width: width, height: height)
    }
}

extension ProfileViewController {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        
        clearChatButton.titleLabel?.font = .systemFont(ofSize: 25, weight: .semibold)
        clearChatButton.layer.cornerRadius = 30
        nameLabel.font = .systemFont(ofSize: 42, weight: .bold)
        ageLabel.font = .systemFont(ofSize: 28, weight: .medium)
        geoLabel.font = .systemFont(ofSize: 26, weight: .medium)
        bioHeaderLabel.font = .systemFont(ofSize: 32, weight: .bold)
        bioLabel.font = .systemFont(ofSize: 26, weight: .regular)
        
        giftsLabel.font = .systemFont(ofSize: 32, weight: .bold)
        emptyGiftsLabel.font = .systemFont(ofSize: 26, weight: .regular)
        sendGiftButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        sendGiftButton.layer.cornerRadius = 20
        backButton.layer.cornerRadius = 30

        backButton.snp.updateConstraints { make in
            make.size.equalTo(60)
        }
        
        sendGiftButton.snp.updateConstraints { make in
            make.height.equalTo(60)
        }
    }
}
