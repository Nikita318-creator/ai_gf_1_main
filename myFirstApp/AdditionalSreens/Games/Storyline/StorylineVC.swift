import UIKit
import SnapKit

class StorylineVC: UIViewController {
    
    // MARK: - Properties
    struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 0.85) // Слегка прозрачный для облачка
        static let textPrimary = UIColor.white
    }
    
    private let viewModel = StorylineViewModel()
    private var storyIndex: Int
    private var currentPageIndex: Int = 0
    private var storyTitle: String
    
    // MARK: - UI Elements
    private let customNavBar = UIView()
    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    
    private let backgroundImageView = UIImageView()
    
    // Облачко с сюжетом
    private let narrationBubbleView = UIView()
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
        view.backgroundColor = TelegramColors.background
        
        // --- NavBar ---
        view.addSubview(customNavBar)
        customNavBar.backgroundColor = TelegramColors.background
        
        let backConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left.circle.fill", withConfiguration: backConfig), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        customNavBar.addSubview(backButton)
        
        titleLabel.text = storyTitle.uppercased()
        titleLabel.font = .systemFont(ofSize: 20, weight: .black)
        titleLabel.textColor = .white
        customNavBar.addSubview(titleLabel)
        
        let infoConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        infoButton.setImage(UIImage(systemName: "info.circle.fill", withConfiguration: infoConfig), for: .normal)
        infoButton.tintColor = TelegramColors.primary
        infoButton.addTarget(self, action: #selector(showRules), for: .touchUpInside)
        customNavBar.addSubview(infoButton)
        
        // --- Background Story Image ---
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        view.addSubview(backgroundImageView)
        
        // --- Narration Bubble (Облачко) ---
        narrationBubbleView.backgroundColor = TelegramColors.cardBackground
        narrationBubbleView.layer.cornerRadius = view.isCurrentDeviceiPad() ? 26 : 16
        narrationBubbleView.clipsToBounds = true
        view.addSubview(narrationBubbleView)
        
        narrationLabel.font = .systemFont(ofSize: view.isCurrentDeviceiPad() ? 26 : 16, weight: .medium)
        narrationLabel.textColor = TelegramColors.textPrimary
        narrationLabel.numberOfLines = 0
        narrationBubbleView.addSubview(narrationLabel)
        
        // --- Bottom Interaction Area ---
        bottomBlurView.clipsToBounds = true
        // Закругляем только верхние углы
        bottomBlurView.layer.cornerRadius = 24
        bottomBlurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(bottomBlurView)
        
        questionLabel.font = .systemFont(ofSize: view.isCurrentDeviceiPad() ? 28 : 18, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        bottomBlurView.contentView.addSubview(questionLabel)
        
        setupOptionButton(option1Button, action: #selector(option1Tapped))
        setupOptionButton(option2Button, action: #selector(option2Tapped))
        bottomBlurView.contentView.addSubview(option1Button)
        bottomBlurView.contentView.addSubview(option2Button)
    }
    
    private func setupOptionButton(_ button: UIButton, action: Selector) {
        button.titleLabel?.font = .systemFont(ofSize: view.isCurrentDeviceiPad() ? 26 : 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 1, alpha: 0.1)
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // Добавляем иконку радио-кнопки
        let radioIcon = UIImage(systemName: "circle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        button.setImage(radioIcon, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        customNavBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(questionLabel.snp.top)
        }
        
        // Облачко: Правая верхняя половина
        narrationBubbleView.snp.makeConstraints { make in
            make.bottom.equalTo(backgroundImageView.snp.bottom).inset(30)
            make.leading.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.65) // Занимает 65% ширины
        }
        
        narrationLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16) // Отступы текста от краев облачка
        }
        
        // Нижний блок с выбором
        bottomBlurView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        questionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(view.isCurrentDeviceiPad() ? 32 : 22)
        }
        
        option1Button.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        option2Button.snp.makeConstraints { make in
            make.top.equalTo(option1Button.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    // MARK: - Logic
    private func loadPage(index: Int) {
        guard index >= 0 && index < viewModel.stories[storyIndex].pages.count else { return }
        currentPageIndex = index
        let page = viewModel.stories[storyIndex].pages[index]
        
        // Анимация плавного перехода
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: {
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
