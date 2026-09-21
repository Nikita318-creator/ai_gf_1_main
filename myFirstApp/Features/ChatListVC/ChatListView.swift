import UIKit
import SnapKit

class ChatListView: UIView {
    let tableView = UITableView()
    private let titleLabel = UILabel()
    private let navigationBar = UIView()
    private let listSeparatorView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let storiesView = StoriesView()
    private var storyDetailView = StoryDetailView()

    let newChatButton = UIButton(type: .system)
    let feedbackButton = UIButton(type: .system)

    private let featureHighlightOverlayView = UIView()
    private let featureHighlightDimmingLayer = CAShapeLayer()
    private let featureHighlightBubbleView = UIView()
    private let featureHighlightBubbleLabel = UILabel()

    private let feedbackHighlightOverlayView = UIView()
    private let feedbackHighlightDimmingLayer = CAShapeLayer()
    private let feedbackHighlightBubbleView = UIView()
    private let feedbackHighlightBubbleLabel = UILabel()

    private var needScrollTotTheEnd: Bool = true
    
    var goToChatHandler: ((String) -> Void)?
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
        setupTableView()
        setupConstraints()
        
        setupFeatureHighlightOverlay()
        setupFeedbackHighlightOverlay()
        
        DispatchQueue.main.async {
            self.showFeatureHighlightIfNeeded()
            if self.featureHighlightOverlayView.isHidden {
                self.showFeedbackHighlightIfNeeded()
            }
        }
        
        updateTextForIPadIfNeeded()
    }

    func updateForRLTIfNeeded() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        if isRTL, needScrollTotTheEnd {
            storiesView.updateForRLTIfNeeded()
        }
    }
    
    private func setupBackground() {
        backgroundColor = MyColors.background

        gradientLayer.colors = [
            MyColors.background.cgColor,
            MyColors.gradientEnd.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupNavigationBar() {
        navigationBar.backgroundColor = MyColors.background
        addSubview(navigationBar)

        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.text = "Chats".localize()
        navigationBar.addSubview(titleLabel)

        newChatButton.setImage(UIImage(systemName: "plus.bubble")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        ), for: .normal)
        newChatButton.tintColor = MyColors.primary
        newChatButton.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
        newChatButton.layer.cornerRadius = 20
        navigationBar.addSubview(newChatButton)

        feedbackButton.setImage(UIImage(systemName: "ellipsis.message")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        ), for: .normal)
        feedbackButton.tintColor = MyColors.primary
        feedbackButton.backgroundColor = MyColors.primary.withAlphaComponent(0.15)
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

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 70, right: 0)
        listSeparatorView.backgroundColor = MyColors.separator.withAlphaComponent(0.6)
        addSubview(listSeparatorView)
        tableView.register(ChatListCell.self, forCellReuseIdentifier: ChatListCell.identifier)
        addSubview(tableView)
    }

    private func setupConstraints() {
        storiesView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(60)
        }

        newChatButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        
        feedbackButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }

        listSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(storiesView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(listSeparatorView.snp.bottom)
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
    
    @objc private func feedbackButtonTapped() {
        AmplitudeManager.shared.logEvent(name: "feedback", properties: ["type":"feedback Button Tapped"])

        UserDefaults.standard.set(true, forKey: "hasAlreadyShownFeedbackHighlight")

        let alert = FeedbackAlertView(frame: self.bounds)
        alert.onSendTapped = { text in
            guard !text.isEmpty else { return }
                        
            TGReportsManager.shared.sendErrorReport(messageText: "👽🛸 Feedback Sent: \(text)\nfor user: \(TGReportsManager.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")")
            
            AmplitudeManager.shared.logEvent(
                name: "Feedback Sent",
                properties: [
                    "text":"\(text)"
                ]
            )
        }
        alert.show(in: self)
    }

    private func setupFeatureHighlightOverlay() {
        featureHighlightOverlayView.backgroundColor = .clear
        featureHighlightOverlayView.isHidden = true
        addSubview(featureHighlightOverlayView)
        
        featureHighlightOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        featureHighlightDimmingLayer.fillColor = MyColors.background.withAlphaComponent(0.8).cgColor
        featureHighlightDimmingLayer.fillRule = .evenOdd
        featureHighlightOverlayView.layer.addSublayer(featureHighlightDimmingLayer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFeatureHighlight))
        featureHighlightOverlayView.addGestureRecognizer(tapGesture)
        
        featureHighlightBubbleView.backgroundColor = MyColors.messageBackground
        featureHighlightBubbleView.layer.cornerRadius = 14
        featureHighlightBubbleView.layer.borderWidth = 1
        featureHighlightBubbleView.layer.borderColor = MyColors.separator.cgColor
        featureHighlightBubbleView.alpha = 0
        featureHighlightOverlayView.addSubview(featureHighlightBubbleView)
        
        featureHighlightBubbleLabel.text = "CreateAIGF.Text".localize()
        featureHighlightBubbleLabel.textColor = MyColors.textPrimary
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
        
        feedbackHighlightDimmingLayer.fillColor = MyColors.background.withAlphaComponent(0.8).cgColor
        feedbackHighlightDimmingLayer.fillRule = .evenOdd
        feedbackHighlightOverlayView.layer.addSublayer(feedbackHighlightDimmingLayer)
        
        // Dismiss on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFeedbackHighlight))
        feedbackHighlightOverlayView.addGestureRecognizer(tapGesture)
        
        feedbackHighlightBubbleView.backgroundColor = MyColors.messageBackground
        feedbackHighlightBubbleView.layer.cornerRadius = 14
        feedbackHighlightBubbleView.layer.borderWidth = 1
        feedbackHighlightBubbleView.layer.borderColor = MyColors.separator.cgColor
        feedbackHighlightBubbleView.alpha = 0
        feedbackHighlightOverlayView.addSubview(feedbackHighlightBubbleView)
        
        // TEXT FROM PROMPT
        feedbackHighlightBubbleLabel.text = "UserSupport.Prompt".localize()
        feedbackHighlightBubbleLabel.textColor = MyColors.textPrimary
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
        guard UserDefaults.standard.bool(forKey: "hasAlreadyShownNewChatHighlight") && BaseManager.shared.is3daysPass else { return }
        
        // New Key in UserDefaults
        let hasShownFeedback = UserDefaults.standard.bool(forKey: "hasAlreadyShownFeedbackHighlight")
        
        // Only show if NOT shown before AND feature highlight is NOT currently active
        if !hasShownFeedback && featureHighlightOverlayView.isHidden {
            AmplitudeManager.shared.logEvent(name: "feedback", properties: ["type":"HighlightOverlay shown"])
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
}

extension ChatListView: StoryDetailViewDelegate {
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

extension ChatListView {
    func updateTextForIPadIfNeeded() {
        guard isCurrentDeviceiPad() else { return }

        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
        newChatButton.layer.cornerRadius = 30
        feedbackButton.layer.cornerRadius = 30
        
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
