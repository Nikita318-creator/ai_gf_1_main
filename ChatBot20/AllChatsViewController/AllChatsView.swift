import UIKit
import SnapKit

enum ChatFilterType: String, CaseIterable {
    case allChats = "FilterChat1"
    case voiceChats = "FilterChat5"
    case ex = "FilterChat6"
    case createdByUser = "FilterChat2"
    case premium = "FilterChat3"
    case roleplay = "FilterChat7"
    case milf = "Milf"
    case defaultChats = "FilterChat4"
}

class AllChatsView: UIView {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    let tableView = UITableView()
    private let titleLabel = UILabel()
    private let navigationBar = UIView()
    private let gradientLayer = CAGradientLayer()
    private let storiesView = StoriesView()
    private var storyDetailView = StoryDetailView()

    // BUTTONS
    let newChatButton = UIButton(type: .system) // Right button
    let feedbackButton = UIButton(type: .system) // NEW: Left button

    // FEATURE HIGHLIGHT (Right side - New Chat)
    private let featureHighlightOverlayView = UIView()
    private let featureHighlightDimmingLayer = CAShapeLayer()
    private let featureHighlightBubbleView = UIView()
    private let featureHighlightBubbleLabel = UILabel()

    // FEEDBACK HIGHLIGHT (NEW: Left side - Feedback)
    private let feedbackHighlightOverlayView = UIView()
    private let feedbackHighlightDimmingLayer = CAShapeLayer()
    private let feedbackHighlightBubbleView = UIView()
    private let feedbackHighlightBubbleLabel = UILabel()

    // FILTERS
    private let filterScrollView = UIScrollView()
    private let filterStackView = UIStackView()
    private var filterButtons: [UIButton] = []
    var currentFilter: ChatFilterType = .allChats {
        didSet {
            updateFilterButtonStates()
            filterChatsHandler?(currentFilter)
            UnreadMessagesService.shared.currentFilter = currentFilter
            tableView.reloadData() // <- Добавлено для обновления структуры секций при переключении табов
            print("Selected filter: \(currentFilter.rawValue.localize())")
        }
    }

    private var needScrollTotTheEnd: Bool = true
    
    var goToChatHandler: ((String) -> Void)?
    var filterChatsHandler: ((ChatFilterType) -> Void)?
    var storyOpenedHandler: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        setupBackground()
        setupNavigationBar()
        setupStoriesView()
        setupChatFilters()
        setupTableView()
        setupConstraints()
        
        // Setup Highlights
        setupFeatureHighlightOverlay()
        setupFeedbackHighlightOverlay() // NEW
        
        DispatchQueue.main.async {
            self.showFeatureHighlightIfNeeded()
            // Try showing feedback highlight only if feature highlight is NOT showing
            // to avoid double overlays.
            if self.featureHighlightOverlayView.isHidden {
                self.showFeedbackHighlightIfNeeded()
            }
        }
        
        currentFilter = .allChats
        updateTextForIPadIfNeeded()
    }

    func updateForRLTIfNeeded() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        if isRTL, needScrollTotTheEnd {
            let rightOffset = CGPoint(x: filterScrollView.contentSize.width - filterScrollView.bounds.width + filterScrollView.contentInset.right, y: 0)
            filterScrollView.setContentOffset(rightOffset, animated: false)
            storiesView.updateForRLTIfNeeded()
        }
    }
    
    private func setupBackground() {
        backgroundColor = TelegramColors.background

        gradientLayer.colors = [
            TelegramColors.background.cgColor,
            UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupNavigationBar() {
        navigationBar.backgroundColor = TelegramColors.cardBackground
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOpacity = 0.1
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navigationBar.layer.shadowRadius = 3
        addSubview(navigationBar)

        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = TelegramColors.textPrimary
        titleLabel.text = "Chats".localize()
        navigationBar.addSubview(titleLabel)

        // Right Button (New Chat)
        newChatButton.setImage(UIImage(systemName: "square.and.pencil")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        ), for: .normal)
        newChatButton.tintColor = TelegramColors.primary
        newChatButton.layer.cornerRadius = 20
        navigationBar.addSubview(newChatButton)
        
        // Left Button (Feedback) - NEW
        feedbackButton.setImage(UIImage(systemName: "envelope")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        ), for: .normal)
        feedbackButton.tintColor = TelegramColors.primary
        feedbackButton.layer.cornerRadius = 20
        feedbackButton.addTarget(self, action: #selector(feedbackButtonTapped), for: .touchUpInside)
        navigationBar.addSubview(feedbackButton)
    }

    private func setupStoriesView() {
        addSubview(storiesView)
        storiesView.setupMockStories()

        storiesView.onStoryTapped = { [weak self] story in
            self?.presentStoryDetail(story: story)
        }
    }
    
    private func setupChatFilters() {
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.alwaysBounceHorizontal = true
        filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        addSubview(filterScrollView)

        filterStackView.axis = .horizontal
        filterStackView.spacing = 8
        filterStackView.alignment = .center
        filterStackView.distribution = .fill
        filterScrollView.addSubview(filterStackView)

        for filterType in ChatFilterType.allCases {
            let button = UIButton(type: .system)
            if !MainHelper.shared.isMode && filterType.rawValue.contains("Milf") {
                
            } else {
                button.setTitle(filterType.rawValue.localize(), for: .normal)
            }
            let filterFontSize: CGFloat = isCurrentDeviceiPad() ? 25 : 15
            let filterCornerRadius: CGFloat = isCurrentDeviceiPad() ? 22 : 16
            button.titleLabel?.font = UIFont.systemFont(ofSize: filterFontSize, weight: .medium)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            button.layer.cornerRadius = filterCornerRadius
            button.clipsToBounds = true
            button.tag = filterType.hashValue
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            
            filterStackView.addArrangedSubview(button)
            filterButtons.append(button)
        }
        updateFilterButtonStates()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 70, right: 0)
        tableView.register(ChatListItemCell.self, forCellReuseIdentifier: ChatListItemCell.identifier)
        addSubview(tableView)
    }

    private func setupConstraints() {
        storiesView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(30)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(storiesView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(60)
        }

        // Right
        newChatButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        
        // Left (NEW)
        feedbackButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }

        filterScrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        filterStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateFeatureHighlightCutout()
        updateFeedbackHighlightCutout() // NEW
    }
    
    private func presentStoryDetail(story: StoryModel) {
        storyOpenedHandler?(false)
        storyDetailView.invalidateAllTimers()
        storyDetailView.removeFromSuperview()
        storyDetailView.delegate = nil
        storyDetailView = StoryDetailView()
        storyDetailView.configure(with: story)
        storyDetailView.show(in: self)
        storyDetailView.delegate = self
    }

    // MARK: - FEEDBACK ACTION
    
    @objc private func feedbackButtonTapped() {
        AnalyticService.shared.logEvent(name: "feedback", properties: ["type":"feedback Button Tapped"])

        UserDefaults.standard.set(true, forKey: "hasAlreadyShownFeedbackHighlight")

        let alert = FeedbackAlertView(frame: self.bounds)
        alert.onSendTapped = { text in
            guard !text.isEmpty else { return }
                        
            WebHookAnaliticksService.shared.sendErrorReport(messageText: "Feedback Sent: \(text)\nfor user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")")
            
            AnalyticService.shared.logEvent(
                name: "Feedback Sent",
                properties: [
                    "text":"\(text)"
                ]
            )
        }
        alert.show(in: self)
    }

    // MARK: - FEATURE HIGHLIGHT (NEW CHAT - RIGHT)

    private func setupFeatureHighlightOverlay() {
        featureHighlightOverlayView.backgroundColor = .clear
        featureHighlightOverlayView.isHidden = true
        addSubview(featureHighlightOverlayView)
        
        featureHighlightOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        featureHighlightDimmingLayer.fillColor = UIColor.black.withAlphaComponent(0.7).cgColor
        featureHighlightDimmingLayer.fillRule = .evenOdd
        featureHighlightOverlayView.layer.addSublayer(featureHighlightDimmingLayer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFeatureHighlight))
        featureHighlightOverlayView.addGestureRecognizer(tapGesture)
        
        featureHighlightBubbleView.backgroundColor = TelegramColors.messageBackground
        featureHighlightBubbleView.layer.cornerRadius = 12
        featureHighlightBubbleView.alpha = 0
        featureHighlightOverlayView.addSubview(featureHighlightBubbleView)
        
        featureHighlightBubbleLabel.text = "NewFriendFeature.Text".localize()
        featureHighlightBubbleLabel.textColor = TelegramColors.textPrimary
        featureHighlightBubbleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        featureHighlightBubbleLabel.numberOfLines = 0
        featureHighlightBubbleLabel.textAlignment = .center
        featureHighlightBubbleView.addSubview(featureHighlightBubbleLabel)
        
        featureHighlightBubbleView.snp.makeConstraints { make in
            make.top.equalTo(newChatButton.snp.bottom).offset(10)
            make.trailing.equalTo(newChatButton.snp.trailing).offset(0)
            make.width.lessThanOrEqualTo(200)
            make.height.greaterThanOrEqualTo(40)
            make.leading.greaterThanOrEqualToSuperview().inset(16)
        }
        
        featureHighlightBubbleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    private func updateFeatureHighlightCutout() {
        guard newChatButton.superview != nil && newChatButton.bounds.width > 0 else { return }
        let buttonFrameInOverlay = newChatButton.convert(newChatButton.bounds, to: featureHighlightOverlayView)
        let path = UIBezierPath(rect: featureHighlightOverlayView.bounds)
        let cutoutRect = buttonFrameInOverlay.insetBy(dx: -8, dy: -8)
        let cutoutPath = UIBezierPath(roundedRect: cutoutRect, cornerRadius: newChatButton.layer.cornerRadius + 8)
        path.append(cutoutPath)
        featureHighlightDimmingLayer.path = path.cgPath
    }

    private func showFeatureHighlightIfNeeded() {
        let hasShownHighlight = UserDefaults.standard.bool(forKey: "hasAlreadyShownNewChatHighlight")
        if !hasShownHighlight {
            featureHighlightOverlayView.isHidden = false
            featureHighlightOverlayView.alpha = 0
            featureHighlightBubbleView.alpha = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateFeatureHighlightCutout()
                UIView.animate(withDuration: 0.5, animations: {
                    self.featureHighlightOverlayView.alpha = 1
                    self.featureHighlightBubbleView.alpha = 1
                })
            }
        }
    }

    @objc private func dismissFeatureHighlight() {
        UIView.animate(withDuration: 0.3, animations: {
            self.featureHighlightOverlayView.alpha = 0
        }) { _ in
            self.featureHighlightOverlayView.isHidden = true
            // When feature highlight is dismissed, check if we need to show feedback highlight
            self.showFeedbackHighlightIfNeeded()
        }
    }
    
    // MARK: - FEEDBACK HIGHLIGHT (NEW CODE)
    
    private func setupFeedbackHighlightOverlay() {
        feedbackHighlightOverlayView.backgroundColor = .clear
        feedbackHighlightOverlayView.isHidden = true
        addSubview(feedbackHighlightOverlayView)
        
        feedbackHighlightOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        feedbackHighlightDimmingLayer.fillColor = UIColor.black.withAlphaComponent(0.7).cgColor
        feedbackHighlightDimmingLayer.fillRule = .evenOdd
        feedbackHighlightOverlayView.layer.addSublayer(feedbackHighlightDimmingLayer)
        
        // Dismiss on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFeedbackHighlight))
        feedbackHighlightOverlayView.addGestureRecognizer(tapGesture)
        
        feedbackHighlightBubbleView.backgroundColor = TelegramColors.messageBackground
        feedbackHighlightBubbleView.layer.cornerRadius = 12
        feedbackHighlightBubbleView.alpha = 0
        feedbackHighlightOverlayView.addSubview(feedbackHighlightBubbleView)
        
        // TEXT FROM PROMPT
        feedbackHighlightBubbleLabel.text = "Feedback.HighlightText".localize()
        feedbackHighlightBubbleLabel.textColor = TelegramColors.textPrimary
        feedbackHighlightBubbleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        feedbackHighlightBubbleLabel.numberOfLines = 0
        feedbackHighlightBubbleLabel.textAlignment = .center
        feedbackHighlightBubbleView.addSubview(feedbackHighlightBubbleLabel)
        
        // Constraints for LEFT side bubble
        feedbackHighlightBubbleView.snp.makeConstraints { make in
            make.top.equalTo(feedbackButton.snp.bottom).offset(10)
            make.leading.equalTo(feedbackButton.snp.leading).offset(0) // Align left
            make.width.lessThanOrEqualTo(250) // Bit wider for long text
            make.height.greaterThanOrEqualTo(40)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        
        feedbackHighlightBubbleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }
    
    private func updateFeedbackHighlightCutout() {
        guard feedbackButton.superview != nil && feedbackButton.bounds.width > 0 else { return }
        let buttonFrameInOverlay = feedbackButton.convert(feedbackButton.bounds, to: feedbackHighlightOverlayView)
        let path = UIBezierPath(rect: feedbackHighlightOverlayView.bounds)
        let cutoutRect = buttonFrameInOverlay.insetBy(dx: -8, dy: -8)
        let cutoutPath = UIBezierPath(roundedRect: cutoutRect, cornerRadius: feedbackButton.layer.cornerRadius + 8)
        path.append(cutoutPath)
        feedbackHighlightDimmingLayer.path = path.cgPath
    }
    
    private func showFeedbackHighlightIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "hasAlreadyShownNewChatHighlight") && MainHelper.shared.is3daysPass else { return }
        
        // New Key in UserDefaults
        let hasShownFeedback = UserDefaults.standard.bool(forKey: "hasAlreadyShownFeedbackHighlight")
        
        // Only show if NOT shown before AND feature highlight is NOT currently active
        if !hasShownFeedback && featureHighlightOverlayView.isHidden {
            AnalyticService.shared.logEvent(name: "feedback", properties: ["type":"HighlightOverlay shown"])
            feedbackHighlightOverlayView.isHidden = false
            feedbackHighlightOverlayView.alpha = 0
            feedbackHighlightBubbleView.alpha = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateFeedbackHighlightCutout()
                UIView.animate(withDuration: 0.5, animations: {
                    self.feedbackHighlightOverlayView.alpha = 1
                    self.feedbackHighlightBubbleView.alpha = 1
                })
            }
        }
    }
    
    @objc private func dismissFeedbackHighlight() {
        UIView.animate(withDuration: 0.3, animations: {
            self.feedbackHighlightOverlayView.alpha = 0
        }) { _ in
            self.feedbackHighlightOverlayView.isHidden = true
        }
    }

    // MARK: - FILTER LOGIC
    @objc private func filterButtonTapped(_ sender: UIButton) {
        needScrollTotTheEnd = false
        if let selectedFilter = ChatFilterType.allCases.first(where: { $0.hashValue == sender.tag }) {
            currentFilter = selectedFilter
        }
    }

    private func updateFilterButtonStates() {
        for button in filterButtons {
            if let filterType = ChatFilterType.allCases.first(where: { $0.hashValue == button.tag }) {
                let isSelected = (filterType == currentFilter)
                button.backgroundColor = isSelected ? TelegramColors.primary : TelegramColors.cardBackground
                button.setTitleColor(isSelected ? TelegramColors.textPrimary : TelegramColors.textSecondary, for: .normal)
            }
        }
    }
}

extension AllChatsView: StoryDetailViewDelegate {
    func storyDetailViewDidClosed() {
        storyOpenedHandler?(true)
    }
    
    func storyDetailViewDidRequestStartChat(currentStoryId: String) {
        goToChatHandler?(currentStoryId)
    }
    
    func storyDetailViewDidRequestNextStory(currentStoryId: String) {
        storiesView.currentStoryIndex += 1
        goToStory()
    }
    
    func storyDetailViewDidRequestPreviousStory(currentStoryId: String) {
        storiesView.currentStoryIndex -= 1
        goToStory()
    }
    
    private func goToStory() {
        guard storiesView.stories.indices.contains(storiesView.currentStoryIndex) else {
            storyDetailView.dismiss()
            return
        }
        storiesView.stories[storiesView.currentStoryIndex].isViewed = true
        presentStoryDetail(story: storiesView.stories[storiesView.currentStoryIndex])
    }
}

extension AllChatsView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }

        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        
        filterScrollView.snp.updateConstraints { make in
            make.height.equalTo(60)
        }
        
        newChatButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
        
        // Update Feedback button for iPad too
        feedbackButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
        
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(80)
        }
        
        storiesView.snp.updateConstraints { make in
            make.height.equalTo(150)
        }
        
        featureHighlightBubbleView.layer.cornerRadius = 20
        featureHighlightBubbleLabel.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        
        featureHighlightBubbleView.snp.updateConstraints { make in
            make.width.lessThanOrEqualTo(450)
            make.height.greaterThanOrEqualTo(60)
        }
        
        // Update Feedback Bubble for iPad
        feedbackHighlightBubbleView.layer.cornerRadius = 20
        feedbackHighlightBubbleLabel.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        feedbackHighlightBubbleView.snp.updateConstraints { make in
            make.width.lessThanOrEqualTo(450)
            make.height.greaterThanOrEqualTo(60)
        }
    }
}
