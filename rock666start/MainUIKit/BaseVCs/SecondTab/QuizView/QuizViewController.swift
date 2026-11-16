import UIKit
import SnapKit

final class QuizViewController: UIViewController {
    
    private let viewModel: QuizViewModel
    private var isAnswerLocked = false
    
    private lazy var backgroundIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: viewModel.topic.iconName)
        iv.contentMode = .scaleAspectFill
        iv.alpha = 0.08
        return iv
    }()
    
    private let blurOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = BasePalitColors.background.withAlphaComponent(0.92)
        return view
    }()
    
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
        return label
    }()
    
    private let optionsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.distribution = .fillEqually
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
        view.addSubview(progressLabel)
        view.addSubview(progressBar)
        view.addSubview(questionCardView)
        questionCardView.addSubview(questionLabel)
        view.addSubview(optionsStackView)
        view.addSubview(actionButton)
        
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
        
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
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
            make.height.equalTo(140)
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
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(20)
        }
    }
    
    private func createOptionButton(index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(BasePalitColors.textPrimary, for: .normal)
        button.backgroundColor = BasePalitColors.unselectedOption
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = BasePalitColors.separator.cgColor
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.tag = index
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        
        button.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        return button
    }
    
    private func setupNavigationBar() {
        title = viewModel.topic.title
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BasePalitColors.background
        appearance.titleTextAttributes = [.foregroundColor: BasePalitColors.textPrimary]
        
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
            button.setTitle("  \(question.options[index])", for: .normal)
            button.backgroundColor = BasePalitColors.unselectedOption
            button.layer.borderColor = BasePalitColors.separator.cgColor
            button.setTitleColor(BasePalitColors.textPrimary, for: .normal)
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
        
        // Подсвечиваем ответ
        for (index, button) in optionButtons.enumerated() {
            button.isUserInteractionEnabled = false
            
            if index == question.correctIndex {
                // Правильный всегда подсвечиваем зеленым (используем avatarBackground как успешный зеленый)
                button.backgroundColor = BasePalitColors.avatarBackground.withAlphaComponent(0.3)
                button.layer.borderColor = BasePalitColors.avatarBackground.cgColor
            } else if index == selectedIndex && !isCorrect {
                // Ошибочный выбор пользователя подсвечиваем красным
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
            title: "Quiz Completed! 🎉",
            message: "You scored \(viewModel.score) out of \(viewModel.totalQuestions) correct answers in \(viewModel.topic.title).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Back to Topics", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
