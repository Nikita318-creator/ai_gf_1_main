import UIKit
import SnapKit

final class SearchViewController: UIViewController {

    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Search".localize()
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "SearchSubtitle".localize()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = MyColors.textSecondary
        label.numberOfLines = 0
        return label
    }()
    
    private let cardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    // Карточка: Swipe Mode
    private lazy var swipeModeCard: FeatureCardView = {
        let card = FeatureCardView(
            badgeText: "SearchSwipeBadge".localize(),
            title: "SearchSwipeTitle".localize(),
            description: "SearchSwipeDescription".localize(),
            iconName: "flame.fill",
            accentColor: MyColors.primary
        )
        card.addTarget(self, action: #selector(didTapSwipeMode), for: .touchUpInside)
        return card
    }()
    
    // Карточка: Chat Roulette
    private lazy var rouletteModeCard: FeatureCardView = {
        let card = FeatureCardView(
            badgeText: "SearchRouletteBadge".localize(),
            title: "SearchRouletteTitle".localize(),
            description: "SearchRouletteDescription".localize(),
            iconName: "shuffle.circle.fill",
            accentColor: MyColors.link
        )
        card.addTarget(self, action: #selector(didTapRouletteMode), for: .touchUpInside)
        return card
    }()
    
    // Информационный баннер / Совет
    private let tipContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.messageBackground
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let tipIconImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iv.image = UIImage(systemName: "sparkles", withConfiguration: config)
        iv.tintColor = MyColors.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = "SearchTipText".localize()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = MyColors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup UI
    
    private func setupUI() {
        view.backgroundColor = MyColors.background
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerStackView)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(subtitleLabel)
        
        contentView.addSubview(cardsStackView)
        cardsStackView.addArrangedSubview(swipeModeCard)
        cardsStackView.addArrangedSubview(rouletteModeCard)
        
        contentView.addSubview(tipContainerView)
        tipContainerView.addSubview(tipIconImageView)
        tipContainerView.addSubview(tipLabel)
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        cardsStackView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        tipContainerView.snp.makeConstraints { make in
            make.top.equalTo(cardsStackView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        tipIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        tipLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.leading.equalTo(tipIconImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Actions
    
    @objc private func didTapSwipeMode() {
        let swipeVC = SwipeModeVC()
        swipeVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(swipeVC, animated: true)
    }
    
    @objc private func didTapRouletteMode() {
        let rouletteVC = ChatRouletteVC()
        rouletteVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(rouletteVC, animated: true)
    }
}

// MARK: - Custom Feature Card Component

final class FeatureCardView: UIControl {
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = MyColors.textSecondary
        label.numberOfLines = 0
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iv.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        iv.tintColor = MyColors.textSecondary
        return iv
    }()
    
    init(badgeText: String, title: String, description: String, iconName: String, accentColor: UIColor) {
        super.init(frame: .zero)
        setupView()
        setupConstraints()
        configure(badgeText: badgeText, title: title, description: description, iconName: iconName, accentColor: accentColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = MyColors.cardBackground
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = MyColors.separator.cgColor
        
        addSubview(badgeLabel)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(iconImageView)
        addSubview(arrowImageView)
    }
    
    private func setupConstraints() {
        badgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(badgeLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(iconImageView.snp.leading).offset(-12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(12)
            make.height.equalTo(18)
        }
    }
    
    private func configure(badgeText: String, title: String, description: String, iconName: String, accentColor: UIColor) {
        badgeLabel.text = "  \(badgeText)  "
        badgeLabel.backgroundColor = accentColor.withAlphaComponent(0.2)
        badgeLabel.textColor = accentColor
        
        titleLabel.text = title
        descriptionLabel.text = description
        
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        if let systemImage = UIImage(systemName: iconName, withConfiguration: config) {
            iconImageView.image = systemImage
            iconImageView.tintColor = accentColor
        } else {
            iconImageView.image = UIImage(named: iconName)
        }
    }
    
    // MARK: - Touch Animations
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.85 : 1.0
            }
        }
    }
}
