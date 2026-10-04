import UIKit
import SnapKit

final class OnboardingVC: UIViewController {

    // MARK: - Model

    struct OnboardingSlide {
        let imageName: String
        let title: String
        let subtitle: String
    }

    // MARK: - Properties

    var onbordingFinishedHandler: (() -> Void)?

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            imageName: "mainAvatar1_",
            title: "Your Perfect AI Girlfriend",
            subtitle: "Always here for you, ready to listen, support, and share unforgettable moments."
        ),
        OnboardingSlide(
            imageName: "mainAvatar2_",
            title: "Deep & Personal Chats",
            subtitle: "Build a unique connection with an AI that adapts to your feelings and desires."
        ),
        OnboardingSlide(
            imageName: "mainAvatar3_",
            title: "Exclusive Photos & Voice",
            subtitle: "Unlock private photos and intimate voice messages anytime, day or night."
        )
    ]

    private var currentPage: Int = 0 {
        didSet {
            updateUIForCurrentPage()
        }
    }

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(OnboardingSlideCell.self, forCellWithReuseIdentifier: OnboardingSlideCell.identifier)
        return cv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = MyColors.primary
        pc.pageIndicatorTintColor = MyColors.progressBackground
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(MyColors.pureWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = MyColors.primaryButtonBackground
        button.layer.cornerRadius = 26
        button.clipsToBounds = true
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        pageControl.numberOfPages = slides.count
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Корректный размер ячейки при смене ориентации/лейауте
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = collectionView.bounds.size
            layout.invalidateLayout()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = MyColors.background

        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(continueButton)

        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).offset(-16)
        }

        continueButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(54)
        }

        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(continueButton.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
    }

    private func setupActions() {
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func continueTapped() {
        if currentPage < slides.count - 1 {
            currentPage += 1
            let indexPath = IndexPath(item: currentPage, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        onbordingFinishedHandler?()
    }

    private func updateUIForCurrentPage() {
        pageControl.currentPage = currentPage
        let buttonTitle = (currentPage == slides.count - 1) ? "Get Started" : "Continue"
        continueButton.setTitle(buttonTitle, for: .normal)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension OnboardingVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnboardingSlideCell.identifier,
            for: indexPath
        ) as? OnboardingSlideCell else {
            return UICollectionViewCell()
        }
        
        let slide = slides[indexPath.item]
        cell.configure(with: slide)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        if page != currentPage {
            currentPage = page
        }
    }
}

// MARK: - Slide Cell

private final class OnboardingSlideCell: UICollectionViewCell {

    static let identifier = "OnboardingSlideCell"

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let gradientOverlayView: UIView = {
        let view = UIView()
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = MyColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        contentView.addSubview(avatarImageView)
        contentView.addSubview(gradientOverlayView)
        contentView.addSubview(textStackView)

        avatarImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.68)
        }

        gradientOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(avatarImageView)
        }

        textStackView.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(28)
        }
    }

    private func applyGradient() {
        gradientOverlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let gradient = CAGradientLayer()
        gradient.frame = gradientOverlayView.bounds
        gradient.colors = [
            UIColor.clear.cgColor,
            MyColors.background.withAlphaComponent(0.4).cgColor,
            MyColors.background.cgColor
        ]
        gradient.locations = [0.0, 0.6, 1.0]
        gradientOverlayView.layer.addSublayer(gradient)
    }

    func configure(with slide: OnboardingVC.OnboardingSlide) {
        avatarImageView.image = UIImage(named: slide.imageName)
        titleLabel.text = slide.title
        subtitleLabel.text = slide.subtitle
    }
}
