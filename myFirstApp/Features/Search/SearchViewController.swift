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
    
    private let headerTopStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Search".localize()
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = MyColors.textPrimary
        return label
    }()
    
    private lazy var gamesButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Hub".localize()
        config.image = UIImage(systemName: "arcade.stick.console")
        config.imagePadding = 6
        config.cornerStyle = .capsule
        config.baseForegroundColor = MyColors.primary
        config.baseBackgroundColor = MyColors.primary
        
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(didTapGamesMode), for: .touchUpInside)
        return button
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
        updateForIPadIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        gamesButton.isHidden = !MiniGamesPhotoCacheService.shared.isCacheReadyAndPreloadIfNeeded()
    }

    // MARK: - Setup UI
    
    private func setupUI() {
        view.backgroundColor = MyColors.background
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerStackView)
        
        headerTopStackView.addArrangedSubview(titleLabel)
        headerTopStackView.addArrangedSubview(gamesButton)
        
        headerStackView.addArrangedSubview(headerTopStackView)
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
        let swipeVC = SearchAIGFFeatureVC()
        swipeVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(swipeVC, animated: true)
    }
    
    @objc private func didTapRouletteMode() {
        let rouletteVC = RandomAIGFViewController()
        rouletteVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(rouletteVC, animated: true)
    }
    
    @objc private func didTapGamesMode() {
        let gamesVC = HubVC()
        gamesVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(gamesVC, animated: true)
    }
}

// MARK: - iPad Layout Support

extension SearchViewController {
    func updateForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }

        // Увеличение шрифтов заголовков и подсказок
        titleLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        subtitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        tipLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)

        // Адаптация кнопки Hub
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        tipIconImageView.image = UIImage(systemName: "sparkles", withConfiguration: config)

        tipContainerView.layer.cornerRadius = 24
        cardsStackView.spacing = 24

        // Обновление отступов и размеров
        headerStackView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        cardsStackView.snp.updateConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        tipContainerView.snp.updateConstraints { make in
            make.top.equalTo(cardsStackView.snp.bottom).offset(36)
            make.leading.trailing.equalToSuperview().inset(32)
            make.bottom.equalToSuperview().offset(-36)
        }

        tipIconImageView.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.size.equalTo(36)
        }

        tipLabel.snp.updateConstraints { make in
            make.top.bottom.equalToSuperview().inset(20)
            make.leading.equalTo(tipIconImageView.snp.trailing).offset(18)
            make.trailing.equalToSuperview().offset(-24)
        }
    }
}
