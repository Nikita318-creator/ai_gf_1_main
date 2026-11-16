import UIKit
import SnapKit

final class QuizViewController: UIViewController {
    
    private let viewModel: QuizViewModel
    private var isAnswerLocked = false
    
    private lazy var backgroundIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: viewModel.topic.iconName)
        iv.contentMode = .scaleAspectFill
        iv.alpha = 0.5
        return iv
    }()
    
    private let blurOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.background.withAlphaComponent(0.82)
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentView = UIView()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = BasePalitColors.textSecondary
        return label
    }()
    
    private let progressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.trackTintColor = BasePalitColors.progressBackground
        pv.progressTintColor = BasePalitColors.progressForeground
        pv.layer.cornerRadius = 3
        pv.clipsToBounds = true
        return pv
    }()
    
    private let questionCardView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.cardBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = BasePalitColors.separator.cgColor
        return view
    }()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = BasePalitColors.textPrimary
        label.numberOfLines = 0
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    private let optionsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.distribution = .fill
        return sv
    }()
    
    private var optionButtons: [UIButton] = []
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next Question", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(BasePalitColors.pureWhite, for: .normal)
        button.backgroundColor = BasePalitColors.primaryButtonBackground
        button.layer.cornerRadius = 14
        button.isEnabled = false
        button.alpha = 0.5
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadQuestion()
    }
    
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        
        view.addSubview(backgroundIconImageView)
        view.addSubview(blurOverlayView)
        view.addSubview(scrollView)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(progressLabel)
        contentView.addSubview(progressBar)
        contentView.addSubview(questionCardView)
        questionCardView.addSubview(questionLabel)
        contentView.addSubview(optionsStackView)
        contentView.addSubview(actionButton)
        
        for i in 0..<4 {
            let button = createOptionButton(index: i)
            optionButtons.append(button)
            optionsStackView.addArrangedSubview(button)
        }
        
        backgroundIconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        blurOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(20)
        }
        
        progressBar.snp.makeConstraints { make in
            make.centerY.equalTo(progressLabel)
            make.leading.equalTo(progressLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(6)
        }
        
        questionCardView.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        questionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        optionsStackView.snp.makeConstraints { make in
            make.top.equalTo(questionCardView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(optionsStackView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(32)
        }
    }
    
    private func createOptionButton(index: Int) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        config.titleAlignment = .leading
        
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.backgroundColor = BasePalitColors.unselectedOption
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = BasePalitColors.separator.cgColor
        button.clipsToBounds = true
        button.tag = index
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.setContentHuggingPriority(.required, for: .vertical)
        
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(52)
        }
        
        return button
    }
    
    private func applyOptionTitle(_ text: String, to button: UIButton) {
        var config = button.configuration ?? UIButton.Configuration.plain()
        var container = AttributeContainer()
        container.font = .systemFont(ofSize: 15, weight: .medium)
        container.foregroundColor = BasePalitColors.textPrimary
        config.attributedTitle = AttributedString(text, attributes: container)
        button.configuration = config
    }
    
    private func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = viewModel.topic.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = BasePalitColors.textPrimary
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BasePalitColors.background
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = BasePalitColors.primary
    }
    
    private func loadQuestion() {
        guard let question = viewModel.currentQuestion else {
            showCompletionAlert()
            return
        }
        
        isAnswerLocked = false
        actionButton.isEnabled = false
        actionButton.alpha = 0.5
        
        let currentIndex = viewModel.currentQuestionIndex + 1
        let total = viewModel.totalQuestions
        progressLabel.text = "Question \(currentIndex) of \(total)"
        progressBar.setProgress(Float(currentIndex) / Float(total), animated: true)
        
        questionLabel.text = question.questionText
        
        for (index, button) in optionButtons.enumerated() {
            applyOptionTitle(question.options[index], to: button)
            button.backgroundColor = BasePalitColors.unselectedOption
            button.layer.borderColor = BasePalitColors.separator.cgColor
            button.isUserInteractionEnabled = true
        }
        
        if currentIndex == total {
            actionButton.setTitle("Finish Quiz", for: .normal)
        } else {
            actionButton.setTitle("Next Question", for: .normal)
        }
    }
    
    @objc private func optionTapped(_ sender: UIButton) {
        guard !isAnswerLocked, let question = viewModel.currentQuestion else { return }
        isAnswerLocked = true
        
        let selectedIndex = sender.tag
        let isCorrect = viewModel.validateAnswer(selectedIdx: selectedIndex)
        
        for (index, button) in optionButtons.enumerated() {
            button.isUserInteractionEnabled = false
            
            if index == question.correctIndex {
                button.backgroundColor = BasePalitColors.avatarBackground.withAlphaComponent(0.3)
                button.layer.borderColor = BasePalitColors.avatarBackground.cgColor
            } else if index == selectedIndex && !isCorrect {
                button.backgroundColor = BasePalitColors.accentRed.withAlphaComponent(0.3)
                button.layer.borderColor = BasePalitColors.accentRed.cgColor
            }
        }
        
        actionButton.isEnabled = true
        actionButton.alpha = 1.0
    }
    
    @objc private func actionButtonTapped() {
        let hasMore = viewModel.nextQuestion()
        if hasMore {
            loadQuestion()
        } else {
            showCompletionAlert()
        }
    }
    
    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: "Quiz Completed!",
            message: "You scored \(viewModel.score) out of \(viewModel.totalQuestions) correct answers in \(viewModel.topic.title).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Back to Topics", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
