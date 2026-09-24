import UIKit
import SnapKit

// MARK: - StoryDetailViewDelegate
protocol StoryDetailViewDelegate: AnyObject {
    func storyDetailViewDidRequestNextStory(currentStoryId: String)
    func storyDetailViewDidRequestPreviousStory(currentStoryId: String)
    func storyDetailViewDidRequestStartChat(currentStoryId: String)
    func storyDetailViewDidClosed()
}

class StoryDetailView: UIView {

    // MARK: - UI Elements

    private let backgroundImageView = UIImageView()
    private let dimmingView = UIView()
    private let descriptionLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let startChatButton = UIButton(type: .system)
    private let headerAvatarView = UIImageView()
    private let headerNameLabel = UILabel()
    private let topScrimLayer = CAGradientLayer()
    private let bottomScrimLayer = CAGradientLayer()

    private let progressBarBackground = UIView()
    private let progressBarFiller = UIView()

    // MARK: - Properties

    weak var delegate: StoryDetailViewDelegate?

    private var storyTimer: Timer?
    private var progressUpdateTimer: Timer?
    private var startTime: Date?

    private let storyDuration: TimeInterval = 5.0
    private let progressUpdateTimeInterval: TimeInterval = 0.05

    private var currentStory: StoryModel?

    private var progressBarFillerWidthConstraint: Constraint?
    private let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    
    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures() 
        updateTextForIPadIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    private func setupViews() {
        backgroundColor = .clear // Прозрачный фон для анимации

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        dimmingView.backgroundColor = MyColors.background.withAlphaComponent(0.15)
        addSubview(dimmingView)
        
        topScrimLayer.colors = [
            MyColors.background.withAlphaComponent(0.7).cgColor,
            MyColors.background.withAlphaComponent(0).cgColor
        ]
        bottomScrimLayer.colors = [
            MyColors.background.withAlphaComponent(0).cgColor,
            MyColors.background.withAlphaComponent(0.85).cgColor
        ]
        dimmingView.layer.addSublayer(topScrimLayer)
        dimmingView.layer.addSublayer(bottomScrimLayer)
        
        // Единый прогресс-бар (фон)
        progressBarBackground.backgroundColor = MyColors.progressBackground
        progressBarBackground.layer.cornerRadius = 1
        progressBarBackground.clipsToBounds = true
        addSubview(progressBarBackground)

        // Единый прогресс-бар (заполняющая часть)
        progressBarFiller.backgroundColor = MyColors.progressForeground
        progressBarFiller.layer.cornerRadius = 1
        progressBarBackground.addSubview(progressBarFiller) // Filler внутри Background
        
        // Текст описания
        descriptionLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        descriptionLabel.textColor = MyColors.textPrimary
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.shadowColor = MyColors.background
        descriptionLabel.shadowOffset = CGSize(width: 1, height: 1)
        dimmingView.addSubview(descriptionLabel)
        descriptionLabel.isHidden = true
        
        // Кнопка закрытия
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        ), for: .normal)
        closeButton.tintColor = MyColors.textPrimary.withAlphaComponent(0.85)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addSubview(closeButton)
        
        // Шапка: аватар + имя
        headerAvatarView.contentMode = .scaleAspectFill
        headerAvatarView.clipsToBounds = true
        headerAvatarView.layer.cornerRadius = 18
        headerAvatarView.layer.borderWidth = 1.5
        headerAvatarView.layer.borderColor = MyColors.textPrimary.withAlphaComponent(0.9).cgColor
        addSubview(headerAvatarView)
        
        headerNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        headerNameLabel.textColor = MyColors.textPrimary
        headerNameLabel.numberOfLines = 1
        addSubview(headerNameLabel)
        
        // НОВОЕ: Кнопка "Start Chatting"
        startChatButton.setTitle("StartChatting".localize(), for: .normal)
        startChatButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        startChatButton.backgroundColor = MyColors.primaryButtonBackground
        startChatButton.setTitleColor(MyColors.textPrimary, for: .normal)
        startChatButton.layer.cornerRadius = 14
        startChatButton.clipsToBounds = true
        startChatButton.addTarget(self, action: #selector(startChatButtonTapped), for: .touchUpInside)
        addSubview(startChatButton)
        startChatButton.isHidden = true
        
        // Constraints
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Констрейнты для единого прогресс-бара
        progressBarBackground.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(4) // Высота полоски
        }

        // Констрейнты для заполняющей части (изначально 0 ширина)
        progressBarFiller.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            // Присваиваем констрейнт ширины свойству
            progressBarFillerWidthConstraint = make.width.equalTo(0).constraint
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(44)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(startChatButton.snp.top).offset(-20) // НОВОЕ: descriptionLabel над кнопкой
        }

        // НОВОЕ: Констрейнты для кнопки "Start Chatting"
        startChatButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(20)
            make.height.equalTo(52)
        }
        
        headerAvatarView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(20)
            make.leading.equalToSuperview().inset(16)
            make.size.equalTo(36)
        }
        
        headerNameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(headerAvatarView)
            make.leading.equalTo(headerAvatarView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }
    }

    // НОВОЕ: Настройка жестов
    private func setupGestures() {
        // Жест тапа (разделение на левую/правую половину)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        dimmingView.addGestureRecognizer(tapGesture)

        // Жест свайпа влево
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeLeftGesture.direction = .left
        dimmingView.addGestureRecognizer(swipeLeftGesture)

        // Жест свайпа вправо
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeRightGesture.direction = .right
        dimmingView.addGestureRecognizer(swipeRightGesture)
        
        // Жест долгого нажатия для паузы
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.2 // Короткое нажатие, чтобы реагировало быстро
        dimmingView.addGestureRecognizer(longPressGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        topScrimLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: min(bounds.height, safeAreaInsets.top + 120))
        let bottomHeight = min(bounds.height, safeAreaInsets.bottom + 260)
        bottomScrimLayer.frame = CGRect(x: 0, y: bounds.height - bottomHeight, width: bounds.width, height: bottomHeight)
        CATransaction.commit()
    }

    // MARK: - Configuration

    func configure(with story: StoryModel) {
        AmplitudeManager.shared.logEvent(name: "Story viewed with id: \(story.id)", properties: ["":""])
        
        self.currentStory = story
        
        backgroundImageView.image = UIImage(named: story.detailImageName)
        
        descriptionLabel.text = story.description
        headerAvatarView.image = UIImage(named: story.imageName)
        headerNameLabel.text = story.title
        
        if !BaseManager.shared.viewedStoriesId.contains(story.id) {
            BaseManager.shared.viewedStoriesId.append(story.id)
        }
        
        startStoryTimer() // Запускаем таймеры для этой сторис
    }

    // MARK: - Timer & Progress Animation

    private func startStoryTimer() {
        invalidateAllTimers() // Очищаем все предыдущие таймеры

        // Сбрасываем ширину прогресс-бара до нуля через констрейнт
        progressBarFillerWidthConstraint?.update(offset: 0)
        self.layoutIfNeeded() // Принудительно обновляем лейаут для начального состояния (0 ширина)

        startTime = Date() // Запоминаем время начала показа сторис

        // Таймер для пошагового обновления прогресс-бара
        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: progressUpdateTimeInterval, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }

            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = min(1.0, elapsedTime / self.storyDuration) // Прогресс от 0.0 до 1.0

            let newWidth = self.progressBarBackground.bounds.width * CGFloat(progress)
            
            // Анимируем изменение ширины прогресс-бара
            // Анимация должна быть очень короткой, чтобы имитировать плавное движение
            UIView.animate(withDuration: self.progressUpdateTimeInterval, delay: 0, options: .curveLinear) {
                self.progressBarFillerWidthConstraint?.update(offset: newWidth)
                // !!! ВАЖНО: layoutIfNeeded() НЕ должен быть здесь внутри анимационного блока для плавного прогресса
                // Он вызывался бы на каждом шаге таймера, мгновенно пересчитывая лейаут
            }
            

            // Если прогресс достиг 100%, останавливаем таймер обновления прогресса
            if progress >= 1.0 {
                self.progressUpdateTimer?.invalidate()
                self.progressUpdateTimer = nil
            }
        }
        
        // Таймер для закрытия сторис по истечении storyDuration
        storyTimer = Timer.scheduledTimer(withTimeInterval: storyDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.showNextStory() // Закрываем сторис по истечении 5 секунд
        }
    }
    
    func invalidateAllTimers() {
        storyTimer?.invalidate()
        storyTimer = nil
        progressUpdateTimer?.invalidate()
        progressUpdateTimer = nil
        // НОВОЕ: Сброс анимации прогресс-бара при остановке таймеров
        progressBarFiller.layer.removeAllAnimations()
    }
    
    // MARK: - Actions

    @objc private func startChatButtonTapped() {
        if let currentStoryId = currentStory?.id {
            dismiss()
            delegate?.storyDetailViewDidRequestStartChat(currentStoryId: currentStoryId)
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss()
    }
    
    // НОВОЕ: Обработчик тапа по экрану (разделение на левую/правую половину)
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let screenWidth = bounds.width

        if isRTL {
            if location.x < screenWidth / 2 {
                showNextStory()
            } else {
                showPreviousStory()
            }
        } else {
            if location.x < screenWidth / 2 {
                showPreviousStory()
            } else {
                showNextStory()
            }
        }
    }

    // НОВОЕ: Обработчик свайпа
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            if isRTL {
                showPreviousStory()
            } else {
                showNextStory()
            }
        case .right:
            if isRTL {
                showNextStory()
            } else {
                showPreviousStory()
            }
        default:
            break
        }
    }
    
    // НОВОЕ: Обработчик долгого нажатия для паузы/возобновления
    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            pauseStory() // Пауза при начале долгого нажатия
        case .ended, .cancelled:
            resumeStory() // Возобновление при отпускании или отмене
        default:
            break
        }
    }

    private func pauseStory() {
        storyTimer?.invalidate() // Останавливаем таймер закрытия
        progressUpdateTimer?.invalidate() // Останавливаем таймер обновления прогресса
        progressBarFiller.layer.pauseAnimation() // Паузим анимацию прогресс-бара
    }

    private func resumeStory() {
        progressBarFiller.layer.resumeAnimation()
        storyTimer = Timer.scheduledTimer(withTimeInterval: storyDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.showNextStory()
        }
        startStoryTimer()
    }
    
    // НОВОЕ: Методы для запроса следующей/предыдущей сторис (информируют делегат)
    private func showNextStory() {
        if let currentStoryId = currentStory?.id {
            delegate?.storyDetailViewDidRequestNextStory(currentStoryId: currentStoryId)
        }
        invalidateAllTimers() // Останавливаем таймеры текущей сторис
    }

    private func showPreviousStory() {
        if let currentStoryId = currentStory?.id {
            delegate?.storyDetailViewDidRequestPreviousStory(currentStoryId: currentStoryId)
        }
        invalidateAllTimers() // Останавливаем таймеры текущей сторис
    }

    // MARK: - Presentation and Dismissal

    func show(in view: UIView) {
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Начальное состояние для анимации
        view.addSubview(self) // Добавляем себя как субвью к родительской вью (AllChatsView)

        self.snp.makeConstraints { make in
            make.edges.equalToSuperview() // Растягиваем на всю родительскую вью
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: nil)
    }

    func dismiss() {
        invalidateAllTimers() // Останавливаем все таймеры при закрытии
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.delegate?.storyDetailViewDidClosed()
        }) { [weak self] _ in
            self?.removeFromSuperview() // Удаляем себя из иерархии вью
        }
    }
    
    deinit {
        invalidateAllTimers() // Гарантируем остановку таймеров при deinit
    }
}

extension StoryDetailView {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 40, weight: .semibold)
        headerNameLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        startChatButton.titleLabel?.font = UIFont.systemFont(ofSize: 38, weight: .bold)
        
        descriptionLabel.snp.updateConstraints { make in
            make.leading.trailing.equalToSuperview().inset(80)
            make.bottom.equalTo(startChatButton.snp.top).offset(-80)
        }
        
        startChatButton.snp.updateConstraints { make in
            make.height.equalTo(80)
        }
    }
}
