import UIKit
import SnapKit

class FeedVC: UIViewController {
    
    enum FeedType: Int {
        case friends = 0
        case feed = 1
    }
    
    private var currentFeedType: FeedType = .friends
    
    // Исходные базы данных видео
    private let friendsPool: [String] = [
        "https://youtube.com/shorts/74FasD2jDGg?feature=share",
        "https://youtube.com/shorts/tPLlRVd-9zk?feature=share",
        "https://youtube.com/shorts/ybFHEk1A7Qc?feature=share",
        "https://youtube.com/shorts/zN5u-XM4-Is?feature=share",
        "https://youtube.com/shorts/duaVJHY5iFs?feature=share",
        "https://youtube.com/shorts/hTkb7LxMHKU?feature=share",
        "https://youtube.com/shorts/CIfmUVCPml4?feature=share",
        "https://youtube.com/shorts/hoR2dPiNkdU?feature=share",
        "https://youtube.com/shorts/CVwL9yowgGA?feature=share",
        "https://youtube.com/shorts/LFYCg2kAJjA?feature=share",
        "https://youtube.com/shorts/1j7lofY9JP8?feature=share",
        "https://youtube.com/shorts/92pH8SN3ooM?feature=share",
        "https://youtube.com/shorts/bn98rraTUIs?feature=share",
        "https://youtube.com/shorts/5snYxEKIqdg?feature=share",
        "https://youtube.com/shorts/G-GmrGjtJmA?feature=share",
        "https://youtube.com/shorts/9IEtxVe577s?feature=share",
        "https://youtube.com/shorts/qFxIauXGoJY?feature=share",
        "https://youtube.com/shorts/ILLulNS9udE?feature=share",
        "https://youtube.com/shorts/2pXnHiwDrYI?feature=share",
        "https://youtube.com/shorts/XCJHD2emj1w?feature=share",
        "https://youtube.com/shorts/rp8K2Paf3PI?feature=share",
        "https://youtube.com/shorts/J-lnoihB2o8?feature=share",
        "https://youtube.com/shorts/Dg3DgCd3hps?feature=share",
        "https://youtube.com/shorts/aBrHA9PJ_AI?feature=share",
        "https://youtube.com/shorts/awCRyfzUpB4?feature=share",
        "https://youtube.com/shorts/zKKu4F153VU?feature=share"
    ]
    
    private let feedPool: [String] = [
        "https://www.youtube.com/shorts/v6uT6kdXxkA", "https://www.youtube.com/shorts/BOqrg_61v5U",
        "https://www.youtube.com/shorts/ZUhHQSpzABc", "https://www.youtube.com/shorts/FzgBPkfQm2I",
        "https://www.youtube.com/shorts/H4_hxjgfq9w", "https://www.youtube.com/shorts/YcRgHirjwYg",
        "https://www.youtube.com/shorts/BeJ-lab2Mks",
        "https://www.youtube.com/shorts/qPfjsncfIjs", "https://www.youtube.com/shorts/yUJf0qX9vEA",
        "https://www.youtube.com/shorts/U1prwI3WF1Q", "https://www.youtube.com/shorts/0xisq2NFnE8",
        "https://www.youtube.com/shorts/wjS0ZEP6X3Q", "https://www.youtube.com/shorts/g1PatgIMcrg",
        "https://www.youtube.com/shorts/LVaWa6_KgU4", "https://www.youtube.com/shorts/11mTRkCdIJ0",
        "https://www.youtube.com/shorts/m9XM-tCNDwo", "https://www.youtube.com/shorts/NYTqgwHRk78",
        "https://www.youtube.com/shorts/SnXewndv5cU", "https://www.youtube.com/shorts/noapALzLnDM",
        "https://www.youtube.com/shorts/tx5-stJkwY4", "https://www.youtube.com/shorts/ejMVniS_1Eo",
        "https://www.youtube.com/shorts/2-kwxBtNlV4", "https://www.youtube.com/shorts/f3lHPvknrTs",
        "https://www.youtube.com/shorts/x023rhUfgVs", "https://www.youtube.com/shorts/nxX9cTvnZxs",
        "https://www.youtube.com/shorts/3KYnDSQojP0", "https://www.youtube.com/shorts/luSgaddKBXc",
        "https://www.youtube.com/shorts/-O2qKdvwr5w", "https://www.youtube.com/shorts/EasH1kOZxZ0",
        "https://www.youtube.com/shorts/Y2GAx5bo7Bs", "https://www.youtube.com/shorts/N9k4oi6kN8Y",
        "https://www.youtube.com/shorts/vG-oU7OSOOw", "https://www.youtube.com/shorts/FeuH0jcUxHQ",
        "https://www.youtube.com/shorts/KIqnjC1UvdE", "https://www.youtube.com/shorts/yME-Emqd6-s",
        "https://www.youtube.com/shorts/WkVfrVISi6A", "https://www.youtube.com/shorts/UjwPdqg8r2Y",
        "https://www.youtube.com/shorts/A-TXMdWA8BM", "https://www.youtube.com/shorts/_1FERZD7YWk",
        "https://www.youtube.com/shorts/Ret7FGnoITU", "https://www.youtube.com/shorts/M4-P0u22BOc",
        "https://www.youtube.com/shorts/3vGDWv5S8qk", "https://www.youtube.com/shorts/aPyyHHiykEw",
        "https://www.youtube.com/shorts/3MBSfg_NTKk", "https://www.youtube.com/shorts/eYddOS7krMI",
        "https://www.youtube.com/shorts/LAknEx2ykmo", "https://www.youtube.com/shorts/PRGXnvtetPk",
        "https://www.youtube.com/shorts/sUazr6jYlNY", "https://www.youtube.com/shorts/Y-WtsvjLbJI",
        "https://www.youtube.com/shorts/oeEpohotttI", "https://www.youtube.com/shorts/kT7oPjYD0PQ",
        "https://www.youtube.com/shorts/9UME1-qMcWc", "https://www.youtube.com/shorts/Hy3yzEUALvU",
        "https://www.youtube.com/shorts/1YadsVbvXro", "https://www.youtube.com/shorts/Ry0tCeZZQeg",
        "https://www.youtube.com/shorts/DddXzv1VED8", "https://www.youtube.com/shorts/aJeTepHqC1w",
        "https://www.youtube.com/shorts/xeUqTwKc4Ag", "https://www.youtube.com/shorts/LbuCY3ghYkY",
        "https://www.youtube.com/shorts/WfHDNr1Fwxs", "https://www.youtube.com/shorts/3IGOPixn8Uw",
        "https://www.youtube.com/shorts/Dwde9wenC3E", "https://www.youtube.com/shorts/zOSDr1Qu_Og",
        "https://www.youtube.com/shorts/WTODM_sqgvM", "https://www.youtube.com/shorts/BYTrB7f20OU",
        "https://www.youtube.com/shorts/81YfUTO8Eoc", "https://www.youtube.com/shorts/doqiaX3vfHE",
        "https://www.youtube.com/shorts/nEq_fj_4UgY", "https://www.youtube.com/shorts/iaOtj2fO1Wk",
        "https://www.youtube.com/shorts/HFaxvFOHcJw", "https://www.youtube.com/shorts/2-rJ3hXUihY",
        "https://www.youtube.com/shorts/qXv1z_LFM3U", "https://www.youtube.com/shorts/mFH7hE4hP60",
        "https://www.youtube.com/shorts/m7vHAynI24Y", "https://www.youtube.com/shorts/vRQzXwUKKrI",
        "https://www.youtube.com/shorts/nfbS9McMOBQ", "https://www.youtube.com/shorts/3vdt7O4BGME",
        "https://www.youtube.com/shorts/nO0OgdVn5Tw", "https://www.youtube.com/shorts/7kgVsuGg9K8",
        "https://www.youtube.com/shorts/nEaRx0LQk64", "https://www.youtube.com/shorts/aHvu9CI2Lww",
        "https://www.youtube.com/shorts/UdUUMD9KBXY", "https://www.youtube.com/shorts/F8A-9S7vh0g",
        "https://www.youtube.com/shorts/wCAh3ck6EVo", "https://www.youtube.com/shorts/xyLaXFVxkXs",
        "https://www.youtube.com/shorts/swrgASGVLgY", "https://www.youtube.com/shorts/vMvavBsbcVY",
        "https://www.youtube.com/shorts/DZp8Jh1a9-Y", "https://www.youtube.com/shorts/jm_NQ_J_pPY",
        "https://www.youtube.com/shorts/3uxFzNeKOVw", "https://www.youtube.com/shorts/61LbSctEnb8",
        "https://www.youtube.com/shorts/inGhNmV2fFw", "https://www.youtube.com/shorts/4QHeFot9zfU",
        "https://www.youtube.com/shorts/P_wPYBOdyWo", "https://www.youtube.com/shorts/JdoHQwb-4ck",
        "https://www.youtube.com/shorts/N3cT3l9olxY", "https://www.youtube.com/shorts/eMOUXIISuq4",
        "https://www.youtube.com/shorts/oAPWfIqKU5A", "https://www.youtube.com/shorts/KXfQLfbTUoo",
        "https://www.youtube.com/shorts/dSp8xMlwjuc", "https://www.youtube.com/shorts/swIVhYjj1G8",
        "https://www.youtube.com/shorts/w24OVukbpso", "https://www.youtube.com/shorts/hzQux59MH_M",
        "https://www.youtube.com/shorts/saNdUWkYT08", "https://www.youtube.com/shorts/d4hVgYSm03w",
        "https://www.youtube.com/shorts/2TSOju2gbQ0", "https://www.youtube.com/shorts/dq8spTbwSJY",
        "https://www.youtube.com/shorts/b4Usrtkdb_s", "https://www.youtube.com/shorts/pZxsfb_TjvM",
        "https://www.youtube.com/shorts/1VGNtf1t45s", "https://www.youtube.com/shorts/sHWRsKENvac",
        "https://www.youtube.com/shorts/MJWQHvVqR60", "https://www.youtube.com/shorts/abTwPplx15Q",
        "https://www.youtube.com/shorts/s7lduFALIFA", "https://www.youtube.com/shorts/CkP7uEowmCY",
        "https://www.youtube.com/shorts/JWAxCDoWWE0", "https://www.youtube.com/shorts/y9Xnv_llADE",
        "https://www.youtube.com/shorts/X2sbtiS8W_A", "https://www.youtube.com/shorts/tg4xc5arrxU",
        "https://www.youtube.com/shorts/gWVwHeviYhg", "https://www.youtube.com/shorts/8jZb_F-AxMA"
    ]
    
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
    
    // Пейдж контроллер для горизонтального свайпа лент
    private var pageViewController: UIPageViewController!
    private var viewControllersList: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        generateMoreVideos(for: .feed)
        generateMoreVideos(for: .friends)
        
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
        // Упаковываем коллекции в простые контейнеры-контроллеры
        let friendsVC = UIViewController()
        friendsVC.view.addSubview(friendsCollectionView)
        friendsCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let feedVC = UIViewController()
        feedVC.view.addSubview(feedCollectionView)
        feedCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        viewControllersList = [friendsVC, feedVC]
        
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        // Ставим дефолтный экран (Friends)
        pageViewController.setViewControllers([viewControllersList[0]], direction: .forward, animated: false, completion: nil)
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }
    
    private func setupUI() {
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(topSegmentedControl)
        topSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(250)
            make.height.equalTo(40)
        }
        
        topSegmentedControl.addTarget(self, action: #selector(feedTypeChanged(_:)), for: .valueChanged)
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
            let randomBatch = (0..<15).compactMap { _ in friendsPool.randomElement() }
            friendsGeneratedUrls.append(contentsOf: randomBatch)
            friendsCollectionView.reloadData()
        case .feed:
            let randomBatch = (0..<15).compactMap { _ in feedPool.randomElement() }
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
    
    // Метод вызова Share Sheet для ячейки
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

// MARK: - UIPageViewController Protocols
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

// MARK: - UICollectionView Protocols
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
        
        // Реализация колбэка шера
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
            
            // Залогируем для аналитики, чтобы знать, какие ссылки умерли
            AnalyticService.shared.logEvent(name: "FeedVC videoFailedToLoad", properties: ["url": urlString])
            
            let isFeed = currentFeedType == .feed
            // 1. Находим актуальный индекс (на случай, если данные успели измениться)
            guard let currentIdx = isFeed ? self.feedGeneratedUrls.firstIndex(of: urlString) : self.friendsGeneratedUrls.firstIndex(of: urlString) else { return }
            
            // 2. Удаляем ссылку из пула
            if isFeed {
                self.feedGeneratedUrls.remove(at: currentIdx)
            } else {
                self.friendsGeneratedUrls.remove(at: currentIdx)
            }
            
            // 3. Обновляем UI без перезагрузки всего экрана, чтобы не дергать плеер
            cv.performBatchUpdates({
                cv.deleteItems(at: [IndexPath(row: currentIdx, section: 0)])
            }, completion: { _ in
                // После удаления автоматически запускаем видео, которое встало на место удаленного
                self.playVisibleVideo()
                
                // Проверка: если осталось мало видео, подгружаем еще batch
                let totalItems = isFeed ? self.feedGeneratedUrls.count : self.friendsGeneratedUrls.count
                if currentIdx >= totalItems - 4 {
                    self.generateMoreVideos(for: isFeed ? .feed : .friends)
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // ФИКС: Перед началом скролла проверяем, соответствует ли скроллируемая коллекция текущему стейту.
        // Если юзер скроллит коллекцию, а система думает, что активна другая — принудительно переключаем стейт.
        if scrollView == feedCollectionView && currentFeedType != .feed {
            syncFeedState(to: .feed)
        } else if scrollView == friendsCollectionView && currentFeedType != .friends {
            syncFeedState(to: .friends)
        }
        
        // Теперь глушим видео именно в реально активной на экране коллекции
        currentCollectionView().visibleCells.forEach { ($0 as? VideoCollectionViewCell)?.pauseVideo() }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // ФИКС: Дублируем проверку при остановке скролла (на случай если dragging начался до завершения анимации пейджа)
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
