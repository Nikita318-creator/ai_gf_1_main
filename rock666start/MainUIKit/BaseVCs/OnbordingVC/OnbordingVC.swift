import UIKit
import SnapKit

final class OnboardingVC: UIViewController {

    struct OnbordModel {
        let imageName: String
        let title: String
        let subtitle: String
    }

    var onbordingFinishedHandler: (() -> Void)?

    private let walkthroughItems: [OnbordModel] = [
        OnbordModel(
            imageName: "openning",
            title: "Your Ultimate Companion",
            subtitle: "Experience hyper-realistic conversations with unique AI personalities who are always by your side."
        ),
        OnbordModel(
            imageName: "icon27",
            title: "Vivid Media & Voice",
            subtitle: "Engage in lifelike, meaningful conversations with voice chats—speak directly and listen to your AI companions respond."
        ),
        OnbordModel(
            imageName: "icon1",
            title: "Deep Connection",
            subtitle: "Discuss any topic on your mind. Choose companions for every life situation—from getting style and haircut advice to casual friendly chats."
        )
    ]

    private var activeStepIndex: Int = 0 {
        didSet {
            refreshInterfaceState()
        }
    }

    private lazy var mainCarouselView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        let grid = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        grid.isPagingEnabled = true
        grid.showsHorizontalScrollIndicator = false
        grid.backgroundColor = .clear
        grid.dataSource = self
        grid.delegate = self
        grid.register(OnbordCell.self, forCellWithReuseIdentifier: OnbordCell.identifier)
        return grid
    }()

    private let stepIndicator: UIPageControl = {
        let indicator = UIPageControl()
        indicator.currentPageIndicatorTintColor = BasePalitColors.primary
        indicator.pageIndicatorTintColor = BasePalitColors.progressBackground
        indicator.isUserInteractionEnabled = false
        return indicator
    }()

    private let primaryActionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.setTitleColor(BasePalitColors.pureWhite, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = BasePalitColors.primaryButtonBackground
        btn.layer.cornerRadius = 26
        btn.clipsToBounds = true
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewHierarchy()
        bindEventHandlers()
        stepIndicator.numberOfPages = walkthroughItems.count
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layoutRef = mainCarouselView.collectionViewLayout as? UICollectionViewFlowLayout {
            layoutRef.itemSize = mainCarouselView.bounds.size
            layoutRef.invalidateLayout()
        }
    }

    private func configureViewHierarchy() {
        view.backgroundColor = BasePalitColors.background

        view.addSubview(mainCarouselView)
        view.addSubview(stepIndicator)
        view.addSubview(primaryActionButton)

        mainCarouselView.snp.makeConstraints { constraintMaker in
            constraintMaker.top.equalToSuperview()
            constraintMaker.leading.trailing.equalToSuperview()
            constraintMaker.bottom.equalTo(primaryActionButton.snp.top).offset(-16)
        }

        primaryActionButton.snp.makeConstraints { constraintMaker in
            constraintMaker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
            constraintMaker.leading.trailing.equalToSuperview().inset(24)
            constraintMaker.height.equalTo(54)
        }

        stepIndicator.snp.makeConstraints { constraintMaker in
            constraintMaker.bottom.equalTo(primaryActionButton.snp.top).offset(-20)
            constraintMaker.centerX.equalToSuperview()
        }
    }

    private func bindEventHandlers() {
        primaryActionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
    }

    @objc private func handleActionTap() {
        if activeStepIndex < walkthroughItems.count - 1 {
            activeStepIndex += 1
            let targetPath = IndexPath(item: activeStepIndex, section: 0)
            mainCarouselView.scrollToItem(at: targetPath, at: .centeredHorizontally, animated: true)
        } else {
            notifyFlowCompletion()
        }
    }

    private func notifyFlowCompletion() {
        onbordingFinishedHandler?()
    }

    private func refreshInterfaceState() {
        stepIndicator.currentPage = activeStepIndex
        let labelText = (activeStepIndex == walkthroughItems.count - 1) ? "Get Started" : "Continue"
        primaryActionButton.setTitle(labelText, for: .normal)
    }
}

extension OnboardingVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return walkthroughItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnbordCell.identifier,
            for: indexPath
        ) as? OnbordCell else {
            return UICollectionViewCell()
        }
        
        let itemData = walkthroughItems[indexPath.item]
        itemCell.configure(with: itemData)
        return itemCell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let calculatedPage = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        if calculatedPage != activeStepIndex {
            activeStepIndex = calculatedPage
        }
    }
}
