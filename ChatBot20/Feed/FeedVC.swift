import UIKit
import SnapKit

class FeedVC: UIViewController {
    
    enum FeedType: Int {
        case friends = 0
        case feed = 1
    }
    
    private var currentFeedType: FeedType = .friends
    private let viewModel = FeedVM()
    
    private var friendsGeneratedUrls: [String] = []
    private var feedGeneratedUrls: [String] = []
    
    private let topSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Friends".localize(), "Feed".localize()])
        sc.selectedSegmentIndex = 0
        sc.backgroundColor = .clear
        sc.selectedSegmentTintColor = .clear
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        sc.setTitleTextAttributes(normalAttributes, for: .normal)
        sc.setTitleTextAttributes(selectedAttributes, for: .selected)
        sc.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        sc.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        return sc
    }()
    
    private lazy var feedCollectionView: UICollectionView = createCollectionView()
    private lazy var friendsCollectionView: UICollectionView = createCollectionView()
    
    private var pageViewController: UIPageViewController!
    private var viewControllersList: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        if MainHelper.shared.isMode {
            generateMoreVideos(for: .friends)
        } else {
            generateMoreVideos(for: .feed)
            generateMoreVideos(for: .friends)
        }
        
        setupPages()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVisibleVideo()
        AnalyticService.shared.logEvent(name: "FeedVC viewDidAppear", properties: ["":""])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllVideos()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // 1. Запоминаем индекс текущего открытого видео перед поворотом
        let activeCV = currentCollectionView()
        let visibleRect = CGRect(origin: activeCV.contentOffset, size: activeCV.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let currentIdxPath = activeCV.indexPathForItem(at: visiblePoint)
        
        // Ставим на паузу текущее видео, чтобы картинка не дергалась во время анимации
        activeCV.visibleCells.forEach { ($0 as? VideoCollectionViewCell)?.pauseVideo() }
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            
            // 2. Полностью инвалидируем лейаут у обеих коллекций, чтобы пересчитать CGSize
            self.feedCollectionView.collectionViewLayout.invalidateLayout()
            self.friendsCollectionView.collectionViewLayout.invalidateLayout()
            
            // 3. Скроллим активную коллекцию к сохраненному индексу с новыми размерами экрана
            if let indexPath = currentIdxPath {
                activeCV.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }, completion: { [weak self] _ in
            // 4. По завершению поворота запускаем видео заново
            self?.playVisibleVideo()
        })
    }
    
    private func createCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: "VideoCell")
        cv.backgroundColor = .black
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }
    
    private func setupPages() {
        let friendsVC = UIViewController()
        friendsVC.view.addSubview(friendsCollectionView)
        friendsCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        if MainHelper.shared.isMode {
            viewControllersList = [friendsVC]
        } else {
            let feedVC = UIViewController()
            feedVC.view.addSubview(feedCollectionView)
            feedCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
            viewControllersList = [friendsVC, feedVC]
        }
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        pageViewController.setViewControllers([viewControllersList[0]], direction: .forward, animated: false, completion: nil)
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }
    
    private func setupUI() {
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if !MainHelper.shared.isMode {
            view.addSubview(topSegmentedControl)
            topSegmentedControl.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
                make.centerX.equalToSuperview()
                make.width.equalTo(250)
                make.height.equalTo(40)
            }
            topSegmentedControl.addTarget(self, action: #selector(feedTypeChanged(_:)), for: .valueChanged)
        }
    }
    
    @objc private func feedTypeChanged(_ sender: UISegmentedControl) {
        AnalyticService.shared.logEvent(name: "FeedVC feedTypeChanged", properties: ["":""])
        stopAllVideos()
        
        let targetIndex = sender.selectedSegmentIndex
        let direction: UIPageViewController.NavigationDirection = (targetIndex > currentFeedType.rawValue) ? .forward : .reverse
        
        currentFeedType = (targetIndex == 0) ? .friends : .feed
        
        pageViewController.setViewControllers([viewControllersList[targetIndex]], direction: direction, animated: true) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.playVisibleVideo()
            }
        }
    }
    
    private func generateMoreVideos(for type: FeedType) {
        switch type {
        case .friends:
            let pool = MainHelper.shared.isMode ? viewModel.friendsTestAPool : viewModel.friendsPool
            let randomBatch = (0..<15).compactMap { _ in pool.randomElement() }
            friendsGeneratedUrls.append(contentsOf: randomBatch)
            friendsCollectionView.reloadData()
        case .feed:
            let randomBatch = (0..<15).compactMap { _ in viewModel.feedPool.randomElement() }
            feedGeneratedUrls.append(contentsOf: randomBatch)
            feedCollectionView.reloadData()
        }
    }
    
    private func currentCollectionView() -> UICollectionView {
        return (currentFeedType == .feed) ? feedCollectionView : friendsCollectionView
    }
    
    private func playVisibleVideo() {
        let activeCV = currentCollectionView()
        let visibleRect = CGRect(origin: activeCV.contentOffset, size: activeCV.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = activeCV.indexPathForItem(at: visiblePoint),
           let cell = activeCV.cellForItem(at: indexPath) as? VideoCollectionViewCell {
            cell.playVideo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                cell.playVideo()
            }
        }
    }
    
    private func stopAllVideos() {
        feedCollectionView.visibleCells.forEach { ($0 as? VideoCollectionViewCell)?.stopVideo() }
        friendsCollectionView.visibleCells.forEach { ($0 as? VideoCollectionViewCell)?.stopVideo() }
    }
    
    private func presentShareSheet(for downloadedAvatar: UIImage?) {
        let textToShare = "\("ResourceText".localize()) \(SubsView.Constants.appStoreUrl)"
        var itemsToShare: [Any] = [textToShare]
        
        if let image = downloadedAvatar {
            itemsToShare.append(image)
        }
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true, completion: nil)
    }
    
    private func showSubs() {
        AnalyticService.shared.logEvent(name: "showSubs from Feed", properties: ["":""])
        let subsView = SubsView()
        subsView.vc = self
        view.addSubview(subsView)
        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subsView.scrollToBottom()
            subsView.yearlyButtonTapped()
            SpeechSynthesizerService.shared.stopSpeaking()
        }
    }
}

extension FeedVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllersList.firstIndex(of: viewController), index > 0 else { return nil }
        return viewControllersList[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllersList.firstIndex(of: viewController), index < viewControllersList.count - 1 else { return nil }
        return viewControllersList[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentVC = pageViewController.viewControllers?.first,
           let index = viewControllersList.firstIndex(of: currentVC) {
            stopAllVideos()
            currentFeedType = (index == 0) ? .friends : .feed
            topSegmentedControl.selectedSegmentIndex = index
            playVisibleVideo()
        }
    }
}

extension FeedVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (collectionView == feedCollectionView) ? feedGeneratedUrls.count : friendsGeneratedUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let urlString = (collectionView == feedCollectionView) ? feedGeneratedUrls[indexPath.row] : friendsGeneratedUrls[indexPath.row]
        cell.configure(with: urlString)
        
        cell.onShareTapped = { [weak self] downloadedAvatar in
            AnalyticService.shared.logEvent(name: "FeedVC onShareTapped", properties: ["":""])
            self?.presentShareSheet(for: downloadedAvatar)
        }
        
        cell.onAuthorTapped = { [weak self] downloadedAvatar in
            AnalyticService.shared.logEvent(name: "FeedVC onAuthorTapped", properties: ["":""])
            
            self?.stopAllVideos()
            
            let randomProfile = AIChatViewModel().sampleProfiles.prefix(32).randomElement() ?? [:]
            
            if let age = randomProfile["age"] as? Int,
               let country = randomProfile["country"] as? String,
               let city = randomProfile["city"] as? String,
               let bio = randomProfile["bio"] as? String {
                
                let assistantProfile = AssistantProfile(
                    id: UUID().uuidString,
                    avatarImageName: "",
                    name: "",
                    age: age,
                    country: country,
                    city: city,
                    bio: bio
                )
                
                let profileVC = ProfileViewController(assistant: assistantProfile, isFeed: true, notFriendProfileAvatar: downloadedAvatar)
                self?.present(profileVC, animated: true)
            }
        }
        
        cell.onVideoFailedToLoad = { [weak self, weak collectionView] in
            guard let self = self, let cv = collectionView else { return }
            
            AnalyticService.shared.logEvent(name: "FeedVC videoFailedToLoad", properties: ["url": urlString])
            
            let isFeed = currentFeedType == .feed
            guard let currentIdx = isFeed ? self.feedGeneratedUrls.firstIndex(of: urlString) : self.friendsGeneratedUrls.firstIndex(of: urlString) else { return }
            
            if isFeed {
                self.feedGeneratedUrls.remove(at: currentIdx)
            } else {
                self.friendsGeneratedUrls.remove(at: currentIdx)
            }
            
            cv.performBatchUpdates({
                cv.deleteItems(at: [IndexPath(row: currentIdx, section: 0)])
            }, completion: { _ in
                self.playVisibleVideo()
                
                let totalItems = isFeed ? self.feedGeneratedUrls.count : self.friendsGeneratedUrls.count
                if currentIdx >= totalItems - 4 {
                    self.generateMoreVideos(for: isFeed ? .feed : .friends)
                }
            })
        }
        
        cell.onCommentsTapped = { [weak self] videoId in
            guard let self = self else { return }
            AnalyticService.shared.logEvent(name: "FeedVC onCommentsTapped", properties: ["videoId": videoId])
            
            let authorImg = cell.profileImageView.image
            let commentsVC = CommentsViewController(videoId: videoId, authorAvatar: authorImg)
            commentsVC.modalPresentationStyle = .pageSheet
            
            if #available(iOS 15.0, *) {
                if let sheet = commentsVC.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                    sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                    sheet.prefersEdgeAttachedInCompactHeight = true
                }
            }
            
            self.present(commentsVC, animated: true, completion: nil)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == feedCollectionView && currentFeedType != .feed {
            syncFeedState(to: .feed)
        } else if scrollView == friendsCollectionView && currentFeedType != .friends {
            syncFeedState(to: .friends)
        }
        
        currentCollectionView().visibleCells.forEach { ($0 as? VideoCollectionViewCell)?.pauseVideo() }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == feedCollectionView && currentFeedType != .feed {
            syncFeedState(to: .feed)
        } else if scrollView == friendsCollectionView && currentFeedType != .friends {
            syncFeedState(to: .friends)
        }
        
        playVisibleVideo()
        
        let activeCV = currentCollectionView()
        let visibleRect = CGRect(origin: activeCV.contentOffset, size: activeCV.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = activeCV.indexPathForItem(at: visiblePoint) {
            let totalItems = (activeCV == feedCollectionView) ? feedGeneratedUrls.count : friendsGeneratedUrls.count
            if indexPath.row >= totalItems - 4 {
                generateMoreVideos(for: (activeCV == feedCollectionView) ? .feed : .friends)
            }
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        playVisibleVideo()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCollectionViewCell)?.stopVideo()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let urlString = (collectionView == feedCollectionView) ? feedGeneratedUrls[indexPath.row] : friendsGeneratedUrls[indexPath.row]
        AnalyticService.shared.logEvent(name: "FeedVC willDisplay cell", properties: ["for url":"urlString"])

        if indexPath.row != 0 && indexPath.row % 2 == 0 && !IAPService.shared.hasActiveSubscription {
            showSubs()
        }
    }
    
    private func syncFeedState(to targetType: FeedType) {
        stopAllVideos()
        currentFeedType = targetType
        topSegmentedControl.selectedSegmentIndex = targetType.rawValue
        
        let targetVC = viewControllersList[targetType.rawValue]
        pageViewController.setViewControllers([targetVC], direction: .forward, animated: false, completion: nil)
    }
}
