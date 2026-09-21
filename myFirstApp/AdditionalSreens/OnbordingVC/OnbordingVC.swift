import UIKit
import SnapKit

final class OnboardingVC: UIViewController {
    
    private var currentPage = 0
    private var pages: [(title: String, image: String)] {
        return [
            (
                APIManager.shared.isRemotePhoto ? "Onboarding.title1".localize() : "Onboarding.title11".localize(),
                APIManager.shared.isRemotePhoto ? "mainAvatar10_" : "mainAvatar10"
            ),
            (
                APIManager.shared.isRemotePhoto ? "Onboarding.title2".localize() : "Onboarding.title21".localize(),
                APIManager.shared.isRemotePhoto ? "mainAvatar14_" : "mainAvatar14"
            ),
            (
                APIManager.shared.isRemotePhoto ? "Onboarding.title3".localize() : "Onboarding.title31".localize(),
                APIManager.shared.isRemotePhoto ? "mainAvatar7_" : "mainAvatar7"
            )
        ]
    }
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.delegate = self
        sv.bounces = false
        return sv
    }()
    
    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 0
        return sv
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = 3
        pc.currentPageIndicatorTintColor = MyColors.primary
        pc.pageIndicatorTintColor = MyColors.separator
        pc.isUserInteractionEnabled = false
        pc.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        return pc
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = MyColors.primary
        button.setTitleColor(MyColors.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = MyColors.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 12
        return button
    }()
    
    var onbordingFinishedHandler: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MyColors.background
        
        setupUI()
        setupPages()
        updateNavigationButtons()
        
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        addButtonAnimations()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard view.isCurrentDeviceiPad() else { return }
        
        coordinator.animate(alongsideTransition: { _ in
            self.view.layoutIfNeeded()
            self.scrollToCurrentPage(animated: false)
        }, completion: nil)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-30)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(scrollView.snp.width).multipliedBy(pages.count)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(nextButton.snp.top).offset(-28)
        }
        
        nextButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.height.equalTo(56)
            make.width.equalTo(220)
        }
    }
    
    private func setupPages() {
        AnalyticService.shared.logEvent(name: "onbording shown: \(!APIManager.shared.isABTestRandom ? "TestA" : "TestB")", properties: ["for mode:": !APIManager.shared.isABTestRandom ? "TestA" : "TestB"])
        for (index, page) in pages.enumerated() {
            let pageView = createPageView(title: page.title, imageName: page.image, index: index)
            contentStackView.addArrangedSubview(pageView)
        }
    }
    
    private func createPageView(title: String, imageName: String, index: Int) -> UIView {
        let containerView = UIView()
        
        let verticalStackView: UIStackView = {
            let sv = UIStackView()
            sv.axis = .vertical
            sv.alignment = .fill
            sv.spacing = 20
            return sv
        }()
        
        containerView.addSubview(verticalStackView)
        
        let imageContainer = UIView()
        imageContainer.backgroundColor = MyColors.cardBackground
        imageContainer.layer.cornerRadius = 24
        imageContainer.layer.borderWidth = 1
        imageContainer.layer.borderColor = MyColors.separator.cgColor
        imageContainer.layer.shadowColor = MyColors.primary.cgColor
        imageContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        imageContainer.layer.shadowRadius = 16
        imageContainer.layer.shadowOpacity = 0.25
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: imageName)
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        
        let bubbleWrapper = UIView()
        
        let bubbleWithTail = BubbleView()
        bubbleWithTail.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        bubbleWrapper.addSubview(bubbleWithTail)
        bubbleWithTail.addSubview(titleLabel)
        
        imageContainer.addSubview(imageView)
        verticalStackView.addArrangedSubview(imageContainer)
        verticalStackView.setCustomSpacing(32, after: imageContainer)
        verticalStackView.addArrangedSubview(bubbleWrapper)
        
        verticalStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(28)
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        
        if view.isCurrentDeviceiPad() {
            let smallerSide = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
            imageContainer.snp.makeConstraints { make in
                make.width.height.equalTo(smallerSide / 2)
            }
            
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
            
            nextButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
            titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        } else {
            imageContainer.snp.makeConstraints { make in
                make.width.height.equalTo(UIScreen.main.bounds.width / 1.25)
            }
            
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(8)
            }
        }
        
        bubbleWrapper.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(verticalStackView).multipliedBy(0.95)
        }
        
        bubbleWithTail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-26)
        }
        
        return containerView
    }
    
    private func addButtonAnimations() {
        [nextButton].forEach { button in
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            sender.transform = .identity
        }
    }
    
    @objc private func nextTapped() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            scrollToCurrentPage(animated: true)
        } else {
            onboardingCompleted()
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToCurrentPage(animated: Bool) {
        let offsetX = CGFloat(currentPage) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
        updatePageControl()
        updateNavigationButtons()
    }
    
    private func updatePageControl() {
        pageControl.currentPage = currentPage
    }
    
    private func updateNavigationButtons() {
        if currentPage == pages.count - 1 {
            nextButton.setTitle("GetStarted".localize(), for: .normal)
            nextButton.backgroundColor = MyColors.avatarBackground
            nextButton.layer.shadowColor = MyColors.avatarBackground.cgColor
        } else {
            nextButton.setTitle("Next".localize(), for: .normal)
            nextButton.backgroundColor = MyColors.primary
            nextButton.layer.shadowColor = MyColors.primary.cgColor
        }
    }
    
    private func onboardingCompleted() {
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            self.view.alpha = 0
        }) { [weak self] _ in
            self?.dismiss(animated: false) {
                self?.onbordingFinishedHandler?()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
        let newPage = max(0, min(Int(pageIndex), pages.count - 1))
        
        if newPage != currentPage {
            currentPage = newPage
            updatePageControl()
            updateNavigationButtons()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let pageIndex = targetContentOffset.pointee.x / scrollView.frame.width
        currentPage = max(0, min(Int(pageIndex), pages.count - 1))
    }
}
