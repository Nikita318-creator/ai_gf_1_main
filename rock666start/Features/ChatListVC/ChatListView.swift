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
        guard isNeedBigTextForIPad() else { return }

        titleLabel.font = UIFont.systemFont(ofSize: 38, weight: .semibold)
      
        navigationBar.snp.updateConstraints { make in
            make.height.equalTo(80)
        }
        
        storiesView.snp.updateConstraints { make in
            make.height.equalTo(150)
        }
    }
}
