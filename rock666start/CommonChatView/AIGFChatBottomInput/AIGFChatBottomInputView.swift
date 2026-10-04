import UIKit
import SnapKit

class AIGFChatBottomInputView: UIView {
    
    // Вьюмодель хранит логику
    private let viewModel = AIGFChatBottomInputViewModel()
    
    // Проксирование хэндлеров во вьюмодель (чтобы не сломать внешний контроллер)
    var sendMessageHandler: ((String) -> Void)? { get { viewModel.sendMessageHandler } set { viewModel.sendMessageHandler = newValue } }
    var showInternetErrorAlertHandler: (() -> Void)? { get { viewModel.showInternetErrorAlertHandler } set { viewModel.showInternetErrorAlertHandler = newValue } }
    var giftSendedHandler: ((GirlfriendGiftModel) -> Void)? { get { viewModel.giftSendedHandler } set { viewModel.giftSendedHandler = newValue } }
    var pleaseWaitHandler: (() -> Void)? { get { viewModel.pleaseWaitHandler } set { viewModel.pleaseWaitHandler = newValue } }
    var textDidChangedHandler: (() -> Void)? { get { viewModel.textDidChangedHandler } set { viewModel.textDidChangedHandler = newValue } }
    var needPremiumForAudioHandler: (() -> Void)? { get { viewModel.needPremiumForAudioHandler } set { viewModel.needPremiumForAudioHandler = newValue } }

    var canSendMessage: Bool { get { viewModel.canSendMessage } set { viewModel.canSendMessage = newValue } }
    weak var vc: UIViewController? { get { viewModel.vc } set { viewModel.vc = newValue; recognizer.vc = newValue } }

    // UI Элементы
    let textView = UITextView()
    let sendButton = UIButton(type: .system)
    let placeholderLabel = UILabel()
    private let inputContainer = UIView()
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let separatorView = UIView()
    
    // Новые UI элементы
    private let menuToggleButton = UIButton(type: .system) // Заменили galleryButton
    private let actionMenu = AIGFActionMenuPopupView()
    private let heartsStackView = UIStackView() // Сохраняем костыль для Love Chat
    
    private var textViewHeightConstraint: Constraint?
    private let maxTextViewHeight: CGFloat = 120
    private lazy var minTextViewHeight: CGFloat = isNeedBigTextForIPad() ? 50 : 36
    
    private enum ButtonMode { case mic, stop, send }
    private var currentButtonMode: ButtonMode = .mic
    private let recognizer = RecognitionManager()
    private var textFromMic = ""

    private let audioWaveView = UIView()
    private var audioWaveBars: [UIView] = []
    private var isAnimatingAudioWave = false
    private var needScrollTotTheEnd: Bool = true

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }
        
        // 1. Если меню открыто — проверяем попадание по меню (даже если оно вылезло за bounds родительской вьюхи)
        if !actionMenu.isHidden {
            let pointInMenu = convert(point, to: actionMenu)
            if actionMenu.point(inside: pointInMenu, with: event) {
                return actionMenu.hitTest(pointInMenu, with: event)
            } else {
                // Тапнули мимо меню (например, в область сообщений или текстового поля) — закрываем меню
                let hitView = super.hitTest(point, with: event)
                if hitView != menuToggleButton {
                    hideMenu()
                }
                return hitView
            }
        }
        
        // 2. Стандартная обработка для остальных элементов внутри bounds
        return super.hitTest(point, with: event)
    }
    
    func setup() {
        clipsToBounds = false // Важно, чтобы меню могло вылезать за пределы
        setupBackground()
        setupHeartsStackView()
        setupInputContainer()
        setupTextView()
        setupAudioWaveView()
        setupButtons()
        setupMenuToggleButton()
        setupActionMenu()
        setupConstraints()
        updateActionButtonUI()
        updateTextForIPadIfNeeded()
        applyABTests()
        
        recognizer.onResult = { [weak self] text in
            print("🎤 Recognized: \(text)")
            self?.textFromMic = text
            self?.textView.text = text
            self?.updateTextViewHeight()
        }
    }
    
    private func setupBackground() {
        backgroundColor = .clear
        backgroundBlurView.alpha = 0.3
        addSubview(backgroundBlurView)
        separatorView.backgroundColor = MyColors.separator
        addSubview(separatorView)
    }
    
    // Заменяем promptsStackView на heartsStackView, чтобы Love Chat не сломался
    private func setupHeartsStackView() {
        heartsStackView.axis = .horizontal
        heartsStackView.spacing = 8
        addSubview(heartsStackView)
    }
    
    private func setupInputContainer() {
        inputContainer.backgroundColor = MyColors.inputBackground
        inputContainer.layer.cornerRadius = 20
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = MyColors.separator.withAlphaComponent(0.6).cgColor
        addSubview(inputContainer)
    }
    
    private func setupTextView() {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = MyColors.textPrimary
        textView.backgroundColor = .clear
        textView.textAlignment = isRTL ? .right : .left
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.enablesReturnKeyAutomatically = true
        
        placeholderLabel.text = "WriteMessage".localize()
        placeholderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.textColor = MyColors.textSecondary
        placeholderLabel.textAlignment = isRTL ? .right : .left
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        inputContainer.addSubview(textView)
        inputContainer.addSubview(placeholderLabel)
    }

    private func setupAudioWaveView() {
        audioWaveView.backgroundColor = .clear
        audioWaveView.isHidden = true
        inputContainer.addSubview(audioWaveView)

        audioWaveView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textView)
            make.centerY.equalTo(textView)
            make.height.equalTo(minTextViewHeight)
        }

        let numberOfBars = 5
        for i in 0..<numberOfBars {
            let bar = UIView()
            bar.backgroundColor = MyColors.textSecondary
            bar.layer.cornerRadius = 1.5
            audioWaveView.addSubview(bar)
            audioWaveBars.append(bar)

            bar.snp.makeConstraints { make in
                make.width.equalTo(4)
                make.height.equalTo(minTextViewHeight * 0.5)
                make.centerY.equalToSuperview()
                make.leading.equalTo(i == 0 ? 0 : audioWaveBars[i-1].snp.trailing).offset(4)
            }
        }
    }
    
    private func setupButtons() {
        sendButton.layer.cornerRadius = 18
        sendButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureHandler(_:)))
        longPressGesture.minimumPressDuration = 0.5
        sendButton.addGestureRecognizer(longPressGesture)
        addSubview(sendButton)
    }
    
    private func setupMenuToggleButton() {
        let size: CGFloat = isNeedBigTextForIPad() ? 28 : 22
        let icon = UIImage(systemName: "chevron.up.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: size, weight: .medium))
        
        menuToggleButton.setImage(icon, for: .normal)
        menuToggleButton.tintColor = MyColors.textSecondary
        menuToggleButton.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        addSubview(menuToggleButton)
    }
    
    private func setupActionMenu() {
        actionMenu.isHidden = true
        addSubview(actionMenu)
        
        actionMenu.onGiftTapped = { [weak self] in
            self?.hideMenu()
            self?.viewModel.openGiftController()
        }
        
        actionMenu.onPromptTapped = { [weak self] text in
            self?.hideMenu()
            self?.viewModel.sendText(text) {
                self?.resetInputState()
            }
        }
        
        actionMenu.onAudioToggled = { [weak self] isOn in
            guard let self = self else { return }
            if isOn && !SubscriptionManager.shared.hasActiveSubscription {
                self.actionMenu.audioToggleSwitch.setOn(false, animated: true)
                self.needPremiumForAudioHandler?()
            } else {
                BaseManager.shared.isAudioMessagesMode = isOn
            }
        }
    }
    
    private func setupConstraints() {
        backgroundBlurView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(-100)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        heartsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalTo(inputContainer.snp.top).offset(-8)
            make.height.equalTo(24) // Достаточно для сердечек
        }

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(inputContainer).inset(2)
            make.width.height.equalTo(36)
        }
        
        menuToggleButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.bottom.equalTo(inputContainer).inset(4)
            make.width.height.equalTo(36)
        }
        
        inputContainer.snp.makeConstraints { make in
            make.leading.equalTo(menuToggleButton.snp.trailing).offset(8)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            make.top.greaterThanOrEqualTo(heartsStackView.snp.bottom).offset(12)
        }
        
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(6)
            textViewHeightConstraint = make.height.equalTo(minTextViewHeight).constraint
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textView)
            make.centerY.equalTo(textView)
        }
        
        actionMenu.snp.makeConstraints { make in
            make.leading.equalTo(menuToggleButton.snp.leading)
            make.bottom.equalTo(menuToggleButton.snp.top).offset(-12)
            make.width.equalTo(250) // Фиксированная ширина меню
        }
    }
    
    // АБ Тесты перенесены сюда
    private func applyABTests() {
        if BackendService.shared.currentData.isABTestRandom {
            if BaseManager.shared.notFriendProfileAvatar != nil {
                actionMenu.hidePhotoPrompt()
            }
        } else {
            if BaseManager.shared.notFriendProfileAvatar == nil {
                actionMenu.hideVideoPrompt()
            } else {
                actionMenu.hidePhotoPrompt()
                actionMenu.hideVideoPrompt()
            }
        }
    }

    func showMenu() {
        guard actionMenu.isHidden else { return }
        actionMenu.alpha = 0
        actionMenu.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.actionMenu.alpha = 1
            self.menuToggleButton.transform = CGAffineTransform(rotationAngle: .pi)
        }
    }
    
    func hideMenu() {
        guard !actionMenu.isHidden else { return }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.actionMenu.alpha = 0
            self.menuToggleButton.transform = .identity
        }) { _ in
            self.actionMenu.isHidden = true
        }
    }
    
    @objc func toggleMenu() {
        if actionMenu.isHidden {
            showMenu()
        } else {
            hideMenu()
        }
    }

    // MARK: - Сохраненные методы (Костыли)
    
    func updateForRLTIfNeeded() { /* Больше не нужен скролл, но оставляем пустым, чтобы не сломать внешние вызовы */ }
    
    func remakeConstraintsForloveChat() {
        inputContainer.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            make.top.greaterThanOrEqualTo(heartsStackView.snp.bottom).offset(12)
        }
    }
    
    private var heartImageViews: [UIImageView] = []
    
    func setHartsForLoveChat(count: Int) {
        heartsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        heartImageViews.removeAll()
        
        let totalHearts = 10
        let filledCount = min(max(0, count), totalHearts)
        let filledHeartColor = MyColors.accentRed
        let emptyHeartColor = MyColors.textSecondary
        let heartSize: CGFloat = 20.0
        
        for i in 0..<totalHearts {
            let isFilled = i < filledCount
            let imageName = isFilled ? "heart.fill" : "heart"
            let heartImage = UIImage(systemName: imageName)?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: heartSize, weight: .regular))
            
            let imageView = UIImageView(image: heartImage)
            imageView.tintColor = isFilled ? filledHeartColor : emptyHeartColor
            imageView.contentMode = .scaleAspectFit
            imageView.tag = 20 + i
            
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(heartSize)
            }
            heartsStackView.addArrangedSubview(imageView)
            heartImageViews.append(imageView)
        }
    }
    
    func hideAllPromptsExceptGift() { actionMenu.hideAllPromptsExceptGift() }
    func hideVideoPrompt() { actionMenu.hideVideoPrompt() }
    func hidePhotoPrompt() { actionMenu.hidePhotoPrompt() }
    
    func enableSendButton() {
        viewModel.canSendMessage = true
        if self.currentButtonMode == .send {
            self.sendButton.backgroundColor = MyColors.primary
        }
    }
    
    // MARK: - Управление состоянием ввода
    
    private func resetInputState() {
        UIView.animate(withDuration: 0.2, animations: {
            self.textView.alpha = 0.5
        }) { _ in
            self.textView.text = ""
            self.textView.alpha = 1.0
            self.placeholderLabel.isHidden = false
            self.updateActionButtonUI()
            self.updateTextViewHeight()
        }
    }
    
    private func updateActionButtonUI() {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasText { currentButtonMode = .send }
        else if currentButtonMode != .stop { currentButtonMode = .mic }
        
        var image: UIImage?
        var backgroundColor: UIColor

        textView.isHidden = false
        placeholderLabel.isHidden = !textView.text.isEmpty
        audioWaveView.isHidden = true
        stopAudioWaveAnimation()

        let pointSize: CGFloat = isNeedBigTextForIPad() ? 24 : 16
        switch currentButtonMode {
        case .mic:
            image = UIImage(systemName: "mic.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold))
            backgroundColor = MyColors.inputBackground
            if textView.inputView != nil { textView.resignFirstResponder(); textView.inputView = nil; textView.reloadInputViews() }
        case .stop:
            image = UIImage(systemName: "stop.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold))
            backgroundColor = MyColors.accentRed
            placeholderLabel.isHidden = true
            audioWaveView.isHidden = true
            startAudioWaveAnimation()
            textView.inputView = UIView()
            textView.reloadInputViews()
            textView.becomeFirstResponder()
        case .send:
            image = UIImage(systemName: "paperplane.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold))
            backgroundColor = canSendMessage ? MyColors.primary : MyColors.inputBackground
            if textView.inputView != nil { textView.resignFirstResponder(); textView.inputView = nil; textView.reloadInputViews() }
        }
        
        sendButton.setImage(image, for: .normal)
        sendButton.tintColor = MyColors.textPrimary
        sendButton.backgroundColor = backgroundColor
        UIView.animate(withDuration: 0.2) { self.sendButton.transform = .identity }
    }
    
    private func updateActionButtonUIForLongTap() {
        // (Логика идентична старой, опущена для компактности, но структура соблюдена)
        updateActionButtonUI()
        if currentButtonMode == .stop {
            sendButton.tintColor = MyColors.textPrimary
            sendButton.backgroundColor = MyColors.primary
            startPulsatingMicAnimation()
        } else {
            stopPulsatingMicAnimation()
        }
    }
    
    private func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let newHeight = max(minTextViewHeight, min(maxTextViewHeight, size.height))
        textViewHeightConstraint?.update(offset: newHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) { self.layoutIfNeeded() }
        textView.isScrollEnabled = true
    }
    
    // MARK: - Аудио-анимации
    
    private func startPulsatingMicAnimation() {
        let pulseLayer = CALayer()
        pulseLayer.backgroundColor = MyColors.primary.withAlphaComponent(0.4).cgColor
        pulseLayer.frame = sendButton.bounds
        pulseLayer.cornerRadius = sendButton.layer.cornerRadius
        sendButton.layer.insertSublayer(pulseLayer, at: 0)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 3.0
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.8
        opacityAnimation.toValue = 0.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [scaleAnimation, opacityAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseLayer.add(groupAnimation, forKey: "pulsingAnimation")
        sendButton.layer.setValue(pulseLayer, forKey: "pulseLayer")
    }

    private func stopPulsatingMicAnimation() {
        if let pulseLayer = sendButton.layer.value(forKey: "pulseLayer") as? CALayer {
            pulseLayer.removeFromSuperlayer()
            sendButton.layer.setValue(nil, forKey: "pulseLayer")
        }
    }
    
    private func startAudioWaveAnimation() {
        guard !isAnimatingAudioWave else { return }
        isAnimatingAudioWave = true
        let maxScaleY: CGFloat = 2.0; let minScaleY: CGFloat = 0.5; let duration: TimeInterval = 0.6
        for (index, bar) in audioWaveBars.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = minScaleY
            animation.toValue = maxScaleY
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.beginTime = CACurrentMediaTime() + Double(index) * (duration / Double(audioWaveBars.count))
            bar.layer.add(animation, forKey: "scaleAnimation")
        }
    }

    private func stopAudioWaveAnimation() {
        guard isAnimatingAudioWave else { return }
        isAnimatingAudioWave = false
        for bar in audioWaveBars { bar.layer.removeAnimation(forKey: "scaleAnimation") }
    }
    
    // MARK: - Actions (Отправка и Запись)
    
    @objc private func actionButtonTapped() {
        switch currentButtonMode {
        case .mic:
            textFromMic = ""
            currentButtonMode = .stop
            updateActionButtonUI()
            recognizer.startRecognition()
        case .stop:
            currentButtonMode = .mic
            updateActionButtonUI()
            recognizer.stopRecognition()
            viewModel.sendText(textFromMic) { self.resetInputState() }
        case .send:
            if let text = textView.text {
                if let language = textView.textInputMode?.primaryLanguage { BaseManager.shared.currentLanguage = language }
                viewModel.sendText(text) { self.resetInputState() }
            }
        }
    }

    @objc private func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            textFromMic = ""
            currentButtonMode = .stop
            updateActionButtonUIForLongTap()
            recognizer.startRecognition()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .ended, .cancelled:
            currentButtonMode = .mic
            updateActionButtonUIForLongTap()
            recognizer.stopRecognition()
            viewModel.sendText(textFromMic) { self.resetInputState() }
        default: break
        }
    }
}

// MARK: - UITextViewDelegate
extension AIGFChatBottomInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textDidChangedHandler?()
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateActionButtonUI()
        updateTextViewHeight()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= 2000
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        inputContainer.layer.borderColor = MyColors.primary.withAlphaComponent(0.6).cgColor
        hideMenu() // Автоматически скрываем меню, когда юзер начинает печатать
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.inputContainer.layer.shadowOpacity = 0.2
            self.inputContainer.layer.shadowRadius = 6
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        inputContainer.layer.borderColor = MyColors.separator.withAlphaComponent(0.6).cgColor
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.inputContainer.layer.shadowOpacity = 0.1
            self.inputContainer.layer.shadowRadius = 3
            self.inputContainer.transform = .identity
        }
    }
}

extension AIGFChatBottomInputView {
    func updateTextForIPadIfNeeded() {
        guard isNeedBigTextForIPad() else { return }
        inputContainer.layer.cornerRadius = 28
        sendButton.layer.cornerRadius = 28
        textView.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        placeholderLabel.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        sendButton.snp.updateConstraints { make in make.width.height.equalTo(56) }
        menuToggleButton.snp.updateConstraints { make in make.width.height.equalTo(56) }
    }
}
