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

final class AIProfileVC: UIViewController {
    
    // MARK: - Layout Constants
    private struct ViewStyleConfig {
        static let mainAvatarHeight: CGFloat = UIScreen.main.bounds.width * 0.9
        static let cardRadius: CGFloat = 20
        static let circularButtonDimension: CGFloat = 46
        static let callActionDimension: CGFloat = 62
        static let pinIconDimension: CGFloat = 18
        static let basePadding: CGFloat = 18
        static let internalCardInset: CGFloat = 20
        static let shadowBlurRadius: CGFloat = 14
        static let shadowAlpha: Float = 0.22
    }
    
    // MARK: - UI Components
    private let mainScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()
    
    private let scrollContentView = UIView()
    
    private let backgroundGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [MyColors.gradientStart.cgColor, MyColors.gradientEnd.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        return gradient
    }()
    
    private let avatarContainerCardView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = ViewStyleConfig.cardRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = ViewStyleConfig.shadowBlurRadius
        view.layer.shadowOpacity = ViewStyleConfig.shadowAlpha
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var mainProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = ViewStyleConfig.cardRadius
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAvatarImageView)))
        return imageView
    }()
    
    private let avatarBottomGradientOverlay: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor]
        gradient.locations = [0.55, 1.0]
        gradient.cornerRadius = ViewStyleConfig.cardRadius
        return gradient
    }()
    
    private let topBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.cardBackground.withAlphaComponent(0.85)
        button.layer.cornerRadius = ViewStyleConfig.circularButtonDimension / 2
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.25
        button.layer.masksToBounds = false
        
        let fontConfig = UIImage.SymbolConfiguration(weight: .semibold)
        let iconImage = UIImage(systemName: "chevron.backward", withConfiguration: fontConfig)
        button.setImage(iconImage, for: .normal)
        
        return button
    }()
    
    private let profileInfoCardView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = ViewStyleConfig.cardRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = ViewStyleConfig.shadowBlurRadius
        view.layer.shadowOpacity = ViewStyleConfig.shadowAlpha
        view.layer.masksToBounds = false
        return view
    }()
    
    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private let ageDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = MyColors.textSecondary
        return label
    }()
    
    private let locationBadgeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.messageBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let locationPinIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.and.ellipse")
        imageView.tintColor = MyColors.primary
        return imageView
    }()
    
    private let locationTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private let bioSectionCardView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = ViewStyleConfig.cardRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = ViewStyleConfig.shadowBlurRadius
        view.layer.shadowOpacity = ViewStyleConfig.shadowAlpha
        view.layer.masksToBounds = false
        return view
    }()
    
    private let bioTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Bio".localize()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private let bioContentTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = MyColors.textSecondary
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    // Вынесенная кнопка очистки чата с использованием палитры MyColors
    private let clearChatHistoryActionView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.cardBackground
        view.layer.cornerRadius = ViewStyleConfig.cardRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = ViewStyleConfig.shadowBlurRadius
        view.layer.shadowOpacity = ViewStyleConfig.shadowAlpha
        view.layer.masksToBounds = false
        return view
    }()
    
    private let clearChatTrashIconView: UIImageView = {
        let img = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        img.image = UIImage(systemName: "trash.fill", withConfiguration: config)
        img.tintColor = MyColors.accentRed
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    private let clearChatTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "ClearChatHistory".localize()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = MyColors.accentRed
        return label
    }()
    
    private let clearChatInteractiveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()
    
    private let startAudioCallButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let icon = UIImage(systemName: "phone.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = .white
        button.backgroundColor = MyColors.primary
        button.layer.cornerRadius = ViewStyleConfig.callActionDimension / 2
        
        button.layer.shadowColor = MyColors.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.4
        button.layer.masksToBounds = false
        
        return button
    }()
    
    private let startTextChatButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let icon = UIImage(systemName: "message.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = .white
        button.backgroundColor = MyColors.primary
        button.layer.cornerRadius = ViewStyleConfig.callActionDimension / 2
        
        button.layer.shadowColor = MyColors.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.4
        button.layer.masksToBounds = false
        return button
    }()
    
    // MARK: - Properties
    private let assistant: AssistantProfile
    private var giftsName: [String] = CoinsService.shared.getSentGifts(for: BaseManager.shared.currentAssistant?.id ?? "")
    
    // MARK: - Gifts Section UI Components
    private let giftsSectionSeparatorLine = UIView()
    private let giftsHeaderTitleLabel = UILabel()
    private let emptyGiftsContainerCardView = UIView()
    private let emptyGiftsNoticeLabel = UILabel()
    private let sendGiftActionButton = UIButton(type: .system)
    private let giftsGridCollectionView: UICollectionView
    
    private var giftsGridHeightConstraint: Constraint?

    var sendGiftTappedHandler: (() -> Void)?
    
    private let isFeed: Bool
    private let notFriendProfileAvatar: UIImage?
    
    // MARK: - Init
    init(assistant: AssistantProfile, isFeed: Bool = false, notFriendProfileAvatar: UIImage? = nil) {
        self.isFeed = isFeed
        self.notFriendProfileAvatar = notFriendProfileAvatar

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        self.giftsGridCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        self.assistant = assistant
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainSubviews()
        configureDataFields()
        bindInteractiveEvents()
        prepareAnimationStates()
        updateTextForIPadIfNeeded()
        
        AnalyticService.shared.logEvent(name: "Profile opened", properties: ["":""])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        avatarBottomGradientOverlay.frame = mainProfileImageView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playEntranceAnimations()
    }
    
    // MARK: - Setup
    private func setupMainSubviews() {
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(scrollContentView)
        
        scrollContentView.addSubview(avatarContainerCardView)
        avatarContainerCardView.addSubview(mainProfileImageView)
        mainProfileImageView.layer.addSublayer(avatarBottomGradientOverlay)
        
        scrollContentView.addSubview(profileInfoCardView)
        profileInfoCardView.addSubview(fullNameLabel)
        profileInfoCardView.addSubview(ageDescriptionLabel)
        profileInfoCardView.addSubview(locationBadgeContainer)
        locationBadgeContainer.addSubview(locationPinIconImageView)
        locationBadgeContainer.addSubview(locationTextLabel)
        
        scrollContentView.addSubview(bioSectionCardView)
        bioSectionCardView.addSubview(bioTitleLabel)
        bioSectionCardView.addSubview(bioContentTextLabel)
        
        // Кнопка очистки чата вынесена как отдельный блок
        scrollContentView.addSubview(clearChatHistoryActionView)
        clearChatHistoryActionView.addSubview(clearChatTrashIconView)
        clearChatHistoryActionView.addSubview(clearChatTitleLabel)
        clearChatHistoryActionView.addSubview(clearChatInteractiveButton)
        
        scrollContentView.addSubview(startAudioCallButton)
        scrollContentView.addSubview(startTextChatButton)
        
        view.addSubview(topBackButton)
        
        // Gifts Section
        scrollContentView.addSubview(giftsSectionSeparatorLine)
        scrollContentView.addSubview(giftsHeaderTitleLabel)
        
        if giftsName.isEmpty {
            scrollContentView.addSubview(emptyGiftsContainerCardView)
            emptyGiftsContainerCardView.addSubview(emptyGiftsNoticeLabel)
            emptyGiftsContainerCardView.addSubview(sendGiftActionButton)
        } else {
            scrollContentView.addSubview(giftsGridCollectionView)
            giftsGridCollectionView.backgroundColor = .clear
            giftsGridCollectionView.showsVerticalScrollIndicator = false
            giftsGridCollectionView.dataSource = self
            giftsGridCollectionView.delegate = self
            giftsGridCollectionView.register(GirlfriendGiftsCell.self, forCellWithReuseIdentifier: "GiftCell")
        }
        
        setupGiftsTheme()
        applyConstraintLayouts()
        
        if isFeed {
            clearChatHistoryActionView.isHidden = true
            emptyGiftsContainerCardView.isHidden = true
            giftsHeaderTitleLabel.isHidden = true
            giftsGridCollectionView.isHidden = true
            startTextChatButton.isHidden = false
        } else {
            startTextChatButton.isHidden = true
        }
    }
    
    private func setupGiftsTheme() {
        giftsSectionSeparatorLine.backgroundColor = MyColors.separator
        
        giftsHeaderTitleLabel.text = "gift.YourGifts".localize()
        giftsHeaderTitleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        giftsHeaderTitleLabel.textColor = MyColors.textPrimary
        
        emptyGiftsContainerCardView.backgroundColor = MyColors.cardBackground
        emptyGiftsContainerCardView.layer.cornerRadius = ViewStyleConfig.cardRadius
        emptyGiftsContainerCardView.layer.shadowColor = UIColor.black.cgColor
        emptyGiftsContainerCardView.layer.shadowOffset = CGSize(width: 0, height: 5)
        emptyGiftsContainerCardView.layer.shadowRadius = ViewStyleConfig.shadowBlurRadius
        emptyGiftsContainerCardView.layer.shadowOpacity = ViewStyleConfig.shadowAlpha
        emptyGiftsContainerCardView.layer.masksToBounds = false
        
        if giftsName.isEmpty {
            emptyGiftsNoticeLabel.text = "gift.doesntHaveGifts".localize()
            emptyGiftsNoticeLabel.textColor = MyColors.textSecondary
            emptyGiftsNoticeLabel.font = .systemFont(ofSize: 15, weight: .regular)
            emptyGiftsNoticeLabel.numberOfLines = 0
            emptyGiftsNoticeLabel.textAlignment = .center
            
            sendGiftActionButton.setTitle("SendGift".localize(), for: .normal)
            sendGiftActionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
            sendGiftActionButton.backgroundColor = MyColors.primary
            sendGiftActionButton.setTitleColor(.white, for: .normal)
            sendGiftActionButton.layer.cornerRadius = 16
            
            sendGiftActionButton.layer.shadowColor = MyColors.primary.cgColor
            sendGiftActionButton.layer.shadowOffset = CGSize(width: 0, height: 4)
            sendGiftActionButton.layer.shadowRadius = 10
            sendGiftActionButton.layer.shadowOpacity = 0.35
            
            sendGiftActionButton.addTarget(self, action: #selector(didTapSendGiftActionButton), for: .touchUpInside)
            attachButtonSpringEffect(to: sendGiftActionButton)
        }
    }
    
    private func applyConstraintLayouts() {
        mainScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollContentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        avatarContainerCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ViewStyleConfig.basePadding)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
            make.height.equalTo(ViewStyleConfig.mainAvatarHeight)
        }
        
        mainProfileImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        topBackButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ViewStyleConfig.basePadding)
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(ViewStyleConfig.basePadding)
            make.size.equalTo(ViewStyleConfig.circularButtonDimension)
        }
        
        if isFeed {
            startTextChatButton.snp.makeConstraints { make in
                make.size.equalTo(ViewStyleConfig.callActionDimension)
                make.trailing.equalTo(scrollContentView.snp.centerX).offset(-12)
                make.top.equalTo(avatarContainerCardView.snp.bottom).offset(-ViewStyleConfig.callActionDimension / 2)
            }
            
            startAudioCallButton.snp.makeConstraints { make in
                make.size.equalTo(ViewStyleConfig.callActionDimension)
                make.leading.equalTo(scrollContentView.snp.centerX).offset(12)
                make.top.equalTo(avatarContainerCardView.snp.bottom).offset(-ViewStyleConfig.callActionDimension / 2)
            }
        } else {
            startAudioCallButton.snp.makeConstraints { make in
                make.size.equalTo(ViewStyleConfig.callActionDimension)
                make.centerX.equalToSuperview()
                make.top.equalTo(avatarContainerCardView.snp.bottom).offset(-ViewStyleConfig.callActionDimension / 2)
            }
        }
        
        profileInfoCardView.snp.makeConstraints { make in
            make.top.equalTo(startAudioCallButton.snp.bottom).offset(ViewStyleConfig.basePadding)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
        }
        
        fullNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ViewStyleConfig.internalCardInset)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
        }
        
        ageDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(fullNameLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
        }
        
        locationBadgeContainer.snp.makeConstraints { make in
            make.top.equalTo(ageDescriptionLabel.snp.bottom).offset(14)
            make.leading.equalToSuperview().offset(ViewStyleConfig.internalCardInset)
            make.bottom.equalToSuperview().offset(-ViewStyleConfig.internalCardInset)
        }
        
        locationPinIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(ViewStyleConfig.pinIconDimension)
        }
        
        locationTextLabel.snp.makeConstraints { make in
            make.leading.equalTo(locationPinIconImageView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.top.bottom.equalToSuperview().inset(8)
        }
        
        bioSectionCardView.snp.makeConstraints { make in
            make.top.equalTo(profileInfoCardView.snp.bottom).offset(ViewStyleConfig.basePadding)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
        }
        
        bioTitleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
        }
        
        bioContentTextLabel.snp.makeConstraints { make in
            make.top.equalTo(bioTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
        }
        
        // Верстка кнопки очистки чата под блоком Bio
        clearChatHistoryActionView.snp.makeConstraints { make in
            make.top.equalTo(bioSectionCardView.snp.bottom).offset(ViewStyleConfig.basePadding)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
            make.height.equalTo(54)
        }
        
        clearChatTrashIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ViewStyleConfig.internalCardInset)
            make.centerY.equalToSuperview()
            make.size.equalTo(22) 
        }
        
        clearChatTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(clearChatTrashIconView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-ViewStyleConfig.internalCardInset)
        }
        
        clearChatInteractiveButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let anchorTopView = isFeed ? bioSectionCardView : clearChatHistoryActionView
        
        giftsSectionSeparatorLine.snp.makeConstraints { make in
            make.top.equalTo(anchorTopView.snp.bottom).offset(ViewStyleConfig.basePadding)
            make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
            make.height.equalTo(1)
        }
        
        giftsHeaderTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(giftsSectionSeparatorLine.snp.bottom).offset(ViewStyleConfig.basePadding)
            make.leading.equalToSuperview().inset(ViewStyleConfig.basePadding)
        }
        
        if giftsName.isEmpty {
            emptyGiftsContainerCardView.snp.makeConstraints { make in
                make.top.equalTo(giftsHeaderTitleLabel.snp.bottom).offset(ViewStyleConfig.basePadding)
                make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
                make.bottom.equalToSuperview().inset(ViewStyleConfig.basePadding)
            }
            emptyGiftsNoticeLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
            }
            sendGiftActionButton.snp.makeConstraints { make in
                make.top.equalTo(emptyGiftsNoticeLabel.snp.bottom).offset(18)
                make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
                make.height.equalTo(48)
                make.bottom.equalToSuperview().inset(ViewStyleConfig.internalCardInset)
            }
        } else {
            giftsGridCollectionView.snp.makeConstraints { make in
                make.top.equalTo(giftsHeaderTitleLabel.snp.bottom).offset(ViewStyleConfig.basePadding)
                make.leading.trailing.equalToSuperview().inset(ViewStyleConfig.basePadding)
                make.bottom.equalToSuperview().inset(ViewStyleConfig.basePadding)
                self.giftsGridHeightConstraint = make.height.equalTo(0).constraint
            }
            recalculateGiftsContentHeight()
        }
    }
    
    private func recalculateGiftsContentHeight() {
        giftsGridCollectionView.reloadData()
        giftsGridCollectionView.layoutIfNeeded()
        let contentHeight = giftsGridCollectionView.collectionViewLayout.collectionViewContentSize.height
        giftsGridHeightConstraint?.update(offset: contentHeight)

        scrollContentView.snp.makeConstraints { make in
            make.bottom.equalTo(giftsGridCollectionView.snp.bottom).offset(ViewStyleConfig.basePadding)
        }
    }
    
    // MARK: - Animations
    private func prepareAnimationStates() {
        startAudioCallButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: 20)
        startAudioCallButton.alpha = 0
        
        startTextChatButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8).translatedBy(x: 0, y: 20)
        startTextChatButton.alpha = 0
        
        profileInfoCardView.transform = CGAffineTransform(translationX: 0, y: 30)
        profileInfoCardView.alpha = 0
        
        bioSectionCardView.transform = CGAffineTransform(translationX: 0, y: 30)
        bioSectionCardView.alpha = 0
        
        clearChatHistoryActionView.transform = CGAffineTransform(translationX: 0, y: 30)
        clearChatHistoryActionView.alpha = 0
    }
    
    private func playEntranceAnimations() {
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.startAudioCallButton.transform = .identity
            self.startAudioCallButton.alpha = 1
            self.startTextChatButton.transform = .identity
            self.startTextChatButton.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3) {
            self.profileInfoCardView.transform = .identity
            self.profileInfoCardView.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3) {
            self.bioSectionCardView.transform = .identity
            self.bioSectionCardView.alpha = 1
            self.clearChatHistoryActionView.transform = .identity
            self.clearChatHistoryActionView.alpha = 1
        }
    }
    
    // MARK: - Data Configuration
    private func configureDataFields() {
        let avatarName = assistant.avatarImageName
        mainProfileImageView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (avatarName + "_") : avatarName)) ?? UIImage(named: avatarName)
        
        fullNameLabel.text = assistant.name
        ageDescriptionLabel.text = "\(assistant.age) y.o."
        locationTextLabel.text = "\(assistant.city), \(assistant.country)"
        bioContentTextLabel.text = assistant.bio
        
        if isFeed, assistant.avatarImageName.isEmpty {
            mainProfileImageView.image = notFriendProfileAvatar ?? UIImage(systemName: "person.circle.fill")
            mainProfileImageView.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - Actions
    private func bindInteractiveEvents() {
        topBackButton.addTarget(self, action: #selector(didTapTopBackButton), for: .touchUpInside)
        clearChatInteractiveButton.addTarget(self, action: #selector(didTapClearChatButton), for: .touchUpInside)
        startAudioCallButton.addTarget(self, action: #selector(didTapStartAudioCallButton), for: .touchUpInside)
        startTextChatButton.addTarget(self, action: #selector(didTapStartTextChatButton), for: .touchUpInside)
        
        attachButtonSpringEffect(to: topBackButton)
        attachButtonSpringEffect(to: clearChatInteractiveButton)
        attachButtonSpringEffect(to: startAudioCallButton, targetScale: 0.82)
        attachButtonSpringEffect(to: startTextChatButton, targetScale: 0.82)
    }
    
    private func attachButtonSpringEffect(to button: UIButton, targetScale: CGFloat = 0.94) {
        button.addTarget(self, action: #selector(handleButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(handleButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func handleButtonTouchDown(_ sender: UIButton) {
        let targetView = sender == clearChatInteractiveButton ? clearChatHistoryActionView : sender
        UIView.animate(withDuration: 0.1) {
            targetView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }
    
    @objc private func handleButtonTouchUp(_ sender: UIButton) {
        let targetView = sender == clearChatInteractiveButton ? clearChatHistoryActionView : sender
        UIView.animate(withDuration: 0.1) {
            targetView.transform = .identity
        }
    }
    
    @objc private func didTapTopBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapStartAudioCallButton() {
        BaseManager.shared.setIsCalledFirst(false)
        
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        guard SubscriptionManager.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        let callVC = AudioCallVC(assistant: self.assistant, avatarImage: notFriendProfileAvatar)
        callVC.modalPresentationStyle = .fullScreen
        present(callVC, animated: true, completion: nil)
    }
    
    @objc private func didTapStartTextChatButton() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        AnalyticService.shared.logEvent(name: "ProfileViewController chatButtonTapped", properties: ["":""])
        
        guard SubscriptionManager.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        
        BaseManager.shared.currentAssistant = AIGirlfriendsConfig(
            id: assistant.id,
            assistantName: assistant.name,
            assistantInfo: "",
            avatarImageName: ""
        )
        BaseManager.shared.currentAssistantImage = notFriendProfileAvatar
        BaseManager.shared.isFirstMessageInChat = true
        
        let aiChatViewController = AIGFChatViewController()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }
    
    @objc private func didTapAvatarImageView() {
        let fullScreenView = PreviewImageView(image: mainProfileImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
    
    @objc private func didTapClearChatButton() {
        AnalyticService.shared.logEvent(name: "Profile clearChatButtonTapped", properties: ["":""])

        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
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
            AIGirlfriendMessagesManager().getAllMessages(forAssistantId: assistantId).forEach {
                AIGirlfriendMessagesManager().deleteMessage(id: $0.id ?? "")
            }
        }
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func didTapSendGiftActionButton() {
        AnalyticService.shared.logEvent(name: "Profile sendGiftButtonTapped", properties: ["":""])
        sendGiftTappedHandler?()
    }
    
    // MARK: - Helper
    private func showSubs() {
        let subsView = PaywallView()
        subsView.vc = self
        
        AnalyticService.shared.logEvent(name: "showSubs from Profile", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension AIProfileVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return giftsName.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GiftCell", for: indexPath) as? GirlfriendGiftsCell else {
            return UICollectionViewCell()
        }
        let giftImageName = giftsName[indexPath.row]
        cell.configure(with: GirlfriendGiftModel(imageName: giftImageName, price: 0), isProfile: true)
        cell.backgroundColor = .clear
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 14 * 2) / 3
        let height = width * 1.2
        return CGSize(width: width, height: height)
    }
}

extension AIProfileVC {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        
        clearChatTitleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        clearChatHistoryActionView.layer.cornerRadius = 24
        clearChatHistoryActionView.snp.updateConstraints { make in
            make.height.equalTo(68)
        }
        
        fullNameLabel.font = .systemFont(ofSize: 38, weight: .bold)
        ageDescriptionLabel.font = .systemFont(ofSize: 24, weight: .medium)
        locationTextLabel.font = .systemFont(ofSize: 22, weight: .medium)
        bioTitleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        bioContentTextLabel.font = .systemFont(ofSize: 22, weight: .regular)
        
        giftsHeaderTitleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        emptyGiftsNoticeLabel.font = .systemFont(ofSize: 22, weight: .regular)
        sendGiftActionButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        sendGiftActionButton.layer.cornerRadius = 20
        topBackButton.layer.cornerRadius = 30

        topBackButton.snp.updateConstraints { make in
            make.size.equalTo(60)
        }
        
        sendGiftActionButton.snp.updateConstraints { make in
            make.height.equalTo(60)
        }
    }
}
