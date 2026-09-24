import UIKit
import SnapKit

class NovellViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = NovellVM()
    private var storyIndex: Int
    private var currentPageIndex: Int = 0
    private var storyTitle: String
    
    // MARK: - UI Elements
    private let backgroundImageView = UIImageView()
    
    // Единый кастомный навбар
    private let customNavBar = UIView()
    private let navSeparator = UIView()
    private let backButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let titlePillView = UIView()
    private let titleLabel = UILabel()
    
    // Компактное облачко с сюжетом
    private let narrationContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let narrationLabel = UILabel()
    
    // Интерактивный подвал
    private let bottomBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let questionLabel = UILabel()
    private let option1Button = UIButton(type: .system)
    private let option2Button = UIButton(type: .system)
    
    // MARK: - Init
    init(storyIndex: Int, title: String) {
        self.storyIndex = storyIndex
        self.storyTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadPage(index: 0)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = MyColors.background
        
        // --- Background Story Image ---
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        view.addSubview(backgroundImageView)
        
        // --- NavBar ---
        setupCustomNavigationBar()
        
        // --- Narration Bubble (Облачко) ---
        narrationContainer.contentView.backgroundColor = MyColors.messageBackground.withAlphaComponent(0.7)
        narrationContainer.layer.cornerRadius = view.isNeedBigTextForIPad() ? 26 : 14
        narrationContainer.clipsToBounds = true
        narrationContainer.layer.borderWidth = 1
        narrationContainer.layer.borderColor = MyColors.separator.withAlphaComponent(0.5).cgColor
        view.addSubview(narrationContainer)
        
        narrationLabel.font = .systemFont(ofSize: view.isNeedBigTextForIPad() ? 24 : 14, weight: .medium)
        narrationLabel.textColor = MyColors.textPrimary
        narrationLabel.numberOfLines = 0
        narrationLabel.adjustsFontSizeToFitWidth = true
        narrationLabel.minimumScaleFactor = 0.8
        narrationLabel.setLineSpacing(lineSpacing: view.isNeedBigTextForIPad() ? 4.0 : 2.0)
        narrationContainer.contentView.addSubview(narrationLabel)
        
        // --- Bottom Interaction Area ---
        bottomBlurView.contentView.backgroundColor = MyColors.background.withAlphaComponent(0.4)
        bottomBlurView.clipsToBounds = true
        bottomBlurView.layer.cornerRadius = view.isNeedBigTextForIPad() ? 36 : 24
        bottomBlurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(bottomBlurView)
        
        questionLabel.font = .systemFont(ofSize: view.isNeedBigTextForIPad() ? 26 : 15, weight: .bold)
        questionLabel.textColor = MyColors.textPrimary
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.8
        bottomBlurView.contentView.addSubview(questionLabel)
        
        setupOptionButton(option1Button, action: #selector(option1Tapped))
        setupOptionButton(option2Button, action: #selector(option2Tapped))
        bottomBlurView.contentView.addSubview(option1Button)
        bottomBlurView.contentView.addSubview(option2Button)
    }

    private func setupCustomNavigationBar() {
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = MyColors.background
        
        let navBarHeight: CGFloat = view.isNeedBigTextForIPad() ? 80 : 60
        let buttonSize: CGFloat = view.isNeedBigTextForIPad() ? 52 : 40
        let buttonCornerRadius: CGFloat = buttonSize / 2
        let iconPointSize: CGFloat = view.isNeedBigTextForIPad() ? 26 : 20
        let infoIconPointSize: CGFloat = view.isNeedBigTextForIPad() ? 24 : 18
        
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(navBarHeight)
        }
        
        // Тонкий разделитель
        navSeparator.backgroundColor = MyColors.separator
        customNavBar.addSubview(navSeparator)
        navSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // Кнопка Назад
        let backConfig = UIImage.SymbolConfiguration(pointSize: iconPointSize, weight: .semibold)
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: backConfig)
        
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = MyColors.textPrimary
        backButton.backgroundColor = MyColors.cardBackground
        backButton.layer.cornerRadius = buttonCornerRadius
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(view.isNeedBigTextForIPad() ? 24 : 16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
        
        // Кнопка Инфо
        let infoConfig = UIImage.SymbolConfiguration(pointSize: infoIconPointSize, weight: .semibold)
        let infoImage = UIImage(systemName: "info.circle", withConfiguration: infoConfig)
        
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = MyColors.primary
        infoButton.backgroundColor = MyColors.cardBackground
        infoButton.layer.cornerRadius = buttonCornerRadius
        infoButton.addTarget(self, action: #selector(showRules), for: .touchUpInside)
        customNavBar.addSubview(infoButton)
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(view.isNeedBigTextForIPad() ? -24 : -16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
        
        // Пилл с заголовком истории
        let pillHeight: CGFloat = view.isNeedBigTextForIPad() ? 48 : 36
        titlePillView.backgroundColor = MyColors.cardBackground
        titlePillView.layer.cornerRadius = pillHeight / 2
        titlePillView.layer.borderWidth = 1
        titlePillView.layer.borderColor = MyColors.separator.cgColor
        customNavBar.addSubview(titlePillView)
        
        titlePillView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(pillHeight)
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(infoButton.snp.leading).offset(-12)
        }
        
        titleLabel.text = storyTitle.uppercased()
        titleLabel.font = .systemFont(ofSize: view.isNeedBigTextForIPad() ? 20 : 15, weight: .bold)
        titleLabel.textColor = MyColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        titlePillView.addSubview(titleLabel)
        
        let titleInset = view.isNeedBigTextForIPad() ? UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24) : UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(titleInset)
        }
    }
    
    private func setupOptionButton(_ button: UIButton, action: Selector) {
        let isIPad = view.isNeedBigTextForIPad()
        button.titleLabel?.font = .systemFont(ofSize: isIPad ? 22 : 14, weight: .semibold)
        button.setTitleColor(MyColors.textPrimary, for: .normal)
        button.backgroundColor = MyColors.unselectedOption
        
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        
        button.layer.cornerRadius = isIPad ? 20 : 14
        button.layer.borderWidth = 1
        button.layer.borderColor = MyColors.separator.cgColor
        
        button.contentHorizontalAlignment = .left
        let padding: CGFloat = isIPad ? 20 : 14
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
        
        button.setImage(nil, for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: -padding)
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = isIPad ? 12 : 8
        
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        let isIPad = view.isNeedBigTextForIPad()
        let sideInset: CGFloat = isIPad ? 24 : 16
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(questionLabel.snp.bottom).inset(-1)
        }
        
        // Компактное облачко прямо над нижним подвалом
        narrationContainer.snp.makeConstraints { make in
            make.bottom.equalTo(bottomBlurView.snp.top).offset(isIPad ? -20 : -12)
            make.leading.trailing.equalToSuperview().inset(sideInset)
        }
        
        narrationLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(isIPad ? 20 : 12)
        }
        
        // Нижний компактный блок с выбором
        bottomBlurView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        questionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(isIPad ? 22 : 14)
            make.leading.trailing.equalToSuperview().inset(sideInset)
        }
        
        option1Button.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(isIPad ? 18 : 12)
            make.leading.trailing.equalToSuperview().inset(sideInset)
            make.height.equalTo(isIPad ? 68 : 46)
        }
        
        option2Button.snp.makeConstraints { make in
            make.top.equalTo(option1Button.snp.bottom).offset(isIPad ? 12 : 8)
            make.leading.trailing.equalToSuperview().inset(sideInset)
            make.height.equalTo(isIPad ? 68 : 46)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(isIPad ? -20 : -12)
        }
    }
    
    // MARK: - Logic
    private func loadPage(index: Int) {
        guard index >= 0 && index < viewModel.stories[storyIndex].pages.count else { return }
        currentPageIndex = index
        let page = viewModel.stories[storyIndex].pages[index]
        
        UIView.transition(with: view, duration: 0.35, options: .transitionCrossDissolve, animations: {
            self.backgroundImageView.image = MiniGamesPhotoCacheService.shared.getImage(named: page.imageName)
            self.narrationLabel.text = page.narrationText.localize()
            self.questionLabel.text = page.questionText.localize()
            
            if page.options.count >= 2 {
                self.option1Button.setTitle(page.options[0].text.localize(), for: .normal)
                self.option2Button.setTitle(page.options[1].text.localize(), for: .normal)
            }
        }, completion: nil)
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        AmplitudeManager.shared.logEvent(name: "Storyline closed", properties: ["currentPageIndex":"\(currentPageIndex)"])
        dismiss(animated: true)
    }
    
    @objc private func showRules() {
        let rulesText = "Novels.INSTRUCTIONS".localize()
        
        let alert = UIAlertController(title: "mini.game.aigf.texts.Rules".localize(), message: rulesText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "mini.game.aigf.texts.Understood".localize(), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func option1Tapped() {
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        let nextPage = viewModel.stories[storyIndex].pages[currentPageIndex].options[0].nextPageIndex
        guard nextPage >= 0 else {
            backTapped()
            return
        }
        loadPage(index: nextPage)
    }
    
    @objc private func option2Tapped() {
        let haptic = UISelectionFeedbackGenerator()
        haptic.selectionChanged()
        let nextPage = viewModel.stories[storyIndex].pages[currentPageIndex].options[1].nextPageIndex
        guard nextPage >= 0 else {
            backTapped()
            return
        }
        loadPage(index: nextPage)
    }
    
    @objc private func imageTapped() {
        let fullScreenView = PreviewImageView(image: backgroundImageView.image)
        fullScreenView.vc = self
        fullScreenView.show(in: view)
    }
}
