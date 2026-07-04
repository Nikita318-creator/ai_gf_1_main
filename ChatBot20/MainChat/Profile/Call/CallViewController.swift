import UIKit
import SnapKit
import AVFoundation

class CallViewController: UIViewController {

    private let assistant: AssistantProfile
    private let isOutgoing: Bool

    // MARK: - UI Components
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }()

    private let gradientView: UIView = {
        let view = UIView()
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        gradientLayer.locations = [0.0, 0.6, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()

    // Avatar container with beautiful shadow and glow effect
    private let avatarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 80
        imageView.backgroundColor = .white.withAlphaComponent(0.1)
        
        // Beautiful shadow
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 8)
        imageView.layer.shadowRadius = 20
        imageView.layer.shadowOpacity = 0.3
        
        return imageView
    }()

    // Animated ring around avatar
    private let animatedRingView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        
        // Text shadow for better readability
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.5
        
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        let font = UIFont.systemFont(ofSize: 18, weight: .medium)
        let descriptor = font.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.medium]
        ])
        label.font = UIFont(descriptor: descriptor, size: 18)
        label.textColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.text = "Calling..."
        
        // Text shadow
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.4
        
        return label
    }()

    // Modern button design
    private let endCallButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "phone.down.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 35
        
        // Modern shadow
        button.layer.shadowColor = UIColor.systemRed.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.4
        
        return button
    }()

    private let answerCallButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "phone.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 35
        
        // Modern shadow
        button.layer.shadowColor = UIColor.systemGreen.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.4
        
        return button
    }()
    
    private let speakerButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "speaker.wave.2.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .white.withAlphaComponent(0.25)
        button.layer.cornerRadius = 30
        
        // Glassmorphism effect
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        // Subtle shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2
        
        return button
    }()

    private let muteButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "mic.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .white.withAlphaComponent(0.25)
        button.layer.cornerRadius = 30
        
        // Glassmorphism effect
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        // Subtle shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2
        
        return button
    }()
    
    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 40
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        return stackView
    }()
    
    // MARK: - Properties
    private var callTimer: Timer?
    private var incomeRingToneTimer: Timer?
    private var callDuration: Int = 0
    private var audioPlayer: AVAudioPlayer?
    private var pulseAnimation: CABasicAnimation?
    
    private var sendTimer: Timer?

    private let viewModel = AIChatViewModel()
    private let recognizer = SpeechRecognitionService()
    private let synthesizer = SpeechSynthesizerService.shared
    private var textFromMic = ""
    private var helloSamples = (1...10).map { "call.hello\($0)".localize() }
    private var isSpeakerActive = true
    private var isMuted = false
    private let avatarImage: UIImage?
    
    private var allGreetings: [String] {
           (1...10).map { "prompt.greetings\($0)".localize() }
       }
    
    // MARK: - Init
    init(assistant: AssistantProfile, isOutgoing: Bool = true, avatarImage: UIImage? = nil) {
        self.assistant = assistant
        self.isOutgoing = isOutgoing
        self.avatarImage = avatarImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureCallUI()
        setupActions()
        setupUIForCallType()
        
        if isOutgoing {
            startCallSimulation()
        } else {
            startIncomingCall()
        }
        
        AnalyticService.shared.logEvent(name: "Call viewDidLoad", properties: ["":""])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrames()
        updateButtonGradients()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPulseAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        callTimer?.invalidate()
        incomeRingToneTimer?.invalidate()
        callTimer = nil
        incomeRingToneTimer = nil
        stopRingtone()
        stopPulseAnimation()
        recognizer.stopRecognition()
        
        synthesizer.currentSpeakinID = nil
        synthesizer.stopSpeaking()
        
        // Восстанавливаем аудио сессию
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка при деактивации аудиосессии: \(error.localizedDescription)")
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(backgroundImageView)
        view.addSubview(blurEffectView)
        view.addSubview(gradientView)
        
        view.addSubview(avatarContainerView)
        avatarContainerView.addSubview(animatedRingView)
        avatarContainerView.addSubview(avatarImageView)
        
        view.addSubview(nameLabel)
        view.addSubview(statusLabel)
        view.addSubview(buttonsStackView)
        
        setupConstraints()
        
        // todo: - убрал их нахуй чтоб не крашило
        speakerButton.isHidden = true
        muteButton.isHidden = true
    }
    
    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(80)
            make.size.equalTo(200)
        }

        animatedRingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(200)
        }

        avatarImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(160)
        }

        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarContainerView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
        }
        
        buttonsStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-80)
            make.height.equalTo(70)
        }
    }
    
    private func setupUIForCallType() {
        if isOutgoing {
            buttonsStackView.addArrangedSubview(muteButton)
            buttonsStackView.addArrangedSubview(endCallButton)
            buttonsStackView.addArrangedSubview(speakerButton)
            
            muteButton.snp.makeConstraints { make in
                make.size.equalTo(60)
            }
            endCallButton.snp.makeConstraints { make in
                make.size.equalTo(70)
            }
            speakerButton.snp.makeConstraints { make in
                make.size.equalTo(60)
            }
            
            statusLabel.text = "Calling..."
        } else {
            buttonsStackView.addArrangedSubview(endCallButton)
            buttonsStackView.addArrangedSubview(answerCallButton)
            
            answerCallButton.snp.makeConstraints { make in
                make.size.equalTo(70)
            }
            endCallButton.snp.makeConstraints { make in
                make.size.equalTo(70)
            }
            
            statusLabel.text = "Incoming Call"
        }
    }

    private func configureCallUI() {
        if assistant.avatarImageName.isEmpty {
            backgroundImageView.image = avatarImage
            avatarImageView.image = avatarImage
        } else {
            backgroundImageView.image = UIImage(named: assistant.avatarImageName)
            avatarImageView.image = UIImage(named: assistant.avatarImageName)
        }
        
        nameLabel.text = assistant.name
        
        // Add subtle glow to avatar
        avatarImageView.layer.shadowColor = UIColor.white.cgColor
        avatarImageView.layer.shadowRadius = 15
        avatarImageView.layer.shadowOpacity = 0.3
    }

    private func setupActions() {
        endCallButton.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)
        answerCallButton.addTarget(self, action: #selector(answerCallTapped), for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(speakerButtonTapped), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        
        // Add button press animations
        addButtonPressAnimations()
        
        recognizer.vc = self
        recognizer.onResult = { [weak self] text in
            guard let self = self else { return }

            self.textFromMic = text

            self.sendTimer?.invalidate()

            self.sendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                                         
                if !self.textFromMic.isEmpty {
                    print("666666 - stopRecognition")
                    self.recognizer.stopRecognition()
                    self.sendMessage()
                }
            }

            print("🎤 Recognized: \(text)")
        }
        
        viewModel.onAudioMessagesUpdated = { [weak self] isSucceed in
            guard
                let self,
                let textToSpeak = viewModel.messagesAI.last(where: { $0.role == "assistant" && !$0.isLoading })?.content
            else { return }
             
            print("6666666 textToSpeak = \(textToSpeak)")
            print("666666 - stopRecognition onAudioMessagesUpdated")
            recognizer.stopRecognition()
            synthesizer.speak(text: textToSpeak)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnFinish), // вызывается не только на финишь - в итоге ии начинает сам себя слушать во время разговора - нужно фиксить!
            name: .updateAllAudioCellsOnFinish,
            object: nil
        )
    }
    
    // MARK: - Animations
    private func startPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        animatedRingView.layer.add(pulseAnimation, forKey: "pulse")
        
        // Create ring border
        let ringLayer = CAShapeLayer()
        let ringPath = UIBezierPath(ovalIn: CGRect(x: 10, y: 10, width: 180, height: 180))
        ringLayer.path = ringPath.cgPath
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        ringLayer.lineWidth = 2
        animatedRingView.layer.addSublayer(ringLayer)
        
        self.pulseAnimation = pulseAnimation
    }
    
    private func stopPulseAnimation() {
        animatedRingView.layer.removeAllAnimations()
        pulseAnimation = nil
    }
    
    private func addButtonPressAnimations() {
        [endCallButton, answerCallButton, speakerButton, muteButton].forEach { button in
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction) {
            sender.transform = .identity
        }
    }
    
    private func updateGradientFrames() {
        (gradientView.layer.sublayers?.first as? CAGradientLayer)?.frame = gradientView.bounds
    }
    
    private func updateButtonGradients() {
        // Removed gradient layers, using backgroundColor instead
    }
    
    // MARK: - Call Logic
    private func startCallSimulation() {
        playRingtone()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.stopRingtone()
            self.startCallTimer()
            self.callStarted()
        }
    }

    private func startIncomingCall() {
        playIncomingRingtone()
    }
    
    private func startActiveCall() {
        // UI changes for active call with smooth animation
        UIView.animate(withDuration: 0.3, animations: {
            self.buttonsStackView.alpha = 0
        }) { _ in
            self.buttonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            self.buttonsStackView.addArrangedSubview(self.muteButton)
            self.buttonsStackView.addArrangedSubview(self.endCallButton)
            self.buttonsStackView.addArrangedSubview(self.speakerButton)
            
            self.muteButton.snp.makeConstraints { make in
                make.size.equalTo(60)
            }
            self.endCallButton.snp.makeConstraints { make in
                make.size.equalTo(70)
            }
            self.speakerButton.snp.makeConstraints { make in
                make.size.equalTo(60)
            }
            
            UIView.animate(withDuration: 0.3) {
                self.buttonsStackView.alpha = 1
            }
        }
        
        // Start conversation logic
        stopRingtone()
        startCallTimer()
        callStarted()
    }

    private func playRingtone() {
        guard let url = Bundle.main.url(forResource: "phoneCalling", withExtension: "mp3") else {
            print("Ringtone file not found.")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: SpeechRecognitionService.speachOptions)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    private func playIncomingRingtone() {
        incomeRingToneTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.incomeRingToneTimer == nil { return }
            AudioServicesPlaySystemSound(1003)
        }
    }
    
    private func stopRingtone() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func startCallTimer() {
        statusLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        callDuration = 0
        updateTimer()
        
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.updateTimer()
        }
    }

    private func callStarted() {
        print("666666 - stopRecognition callStarted")
        recognizer.stopRecognition()
        synthesizer.speak(text: helloSamples.randomElement() ?? "")
        
        // Change ring animation to indicate active call
        stopPulseAnimation()
        startActiveCallAnimation()
    }
    
    private func startActiveCallAnimation() {
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0.3
        glowAnimation.toValue = 0.6
        glowAnimation.duration = 2.0
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        
        avatarImageView.layer.add(glowAnimation, forKey: "glow")
    }
    
    private func sendMessage() {
        var previousMessages = ""
        if viewModel.messagesAI.count >= 2 {
            previousMessages = "promp.previosMessagesUser".localize()
            + (self.viewModel.messagesAI[self.viewModel.messagesAI.count - 2].content)
            + "promp.previosMessagesAI".localize()
            + (self.viewModel.messagesAI.last?.content ?? "")
            + "promp.previosMessagesUserStarter".localize()
        }

        print("666666 - textFromMic = \(textFromMic)")

        recognizer.stopRecognition()
        viewModel.systemPrompt = MainHelper.shared.getSystemPromptForCurrentAssistant()
        viewModel.safeSystemPrompt = MainHelper.shared.getSafeSystemPromptForCurrentAssistant()
        viewModel.previousMessages = previousMessages
        viewModel.sendMessageViaCustomServer(textFromMic, isAudioCall: true)
        textFromMic = ""
    }
    
    @objc private func updateTimer() {
        let minutes = callDuration / 60
        let seconds = callDuration % 60
        statusLabel.text = String(format: "%d:%02d", minutes, seconds)
        callDuration += 1
    }

    @objc private func endCallTapped() {
        AnalyticService.shared.logEvent(name: "Call endCallTapped", properties: ["":""])

        callTimer?.invalidate()
        callTimer = nil
        stopRingtone()
        
        // Smooth dismiss animation
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc private func answerCallTapped() {
        AnalyticService.shared.logEvent(name: "Call answerCallTapped", properties: ["":""])

        incomeRingToneTimer?.invalidate()
        incomeRingToneTimer = nil
        
        guard IAPService.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        
        startActiveCall()
    }
    
    @objc private func updateOnFinish() {
        print("startRecognition")
        if !isMuted {
            print("666666 - startRecognition")
            recognizer.startRecognition()
        }
    }
    
    // MARK: - Button Actions
    @objc private func speakerButtonTapped() {
        AnalyticService.shared.logEvent(name: "Call speakerButtonTapped", properties: ["":""])

        isSpeakerActive.toggle()
        updateSpeakerUI()
        setAudioOutput()
    }

    @objc private func muteButtonTapped() {
        AnalyticService.shared.logEvent(name: "Call muteButtonTapped", properties: ["":""])

        isMuted.toggle()
        updateMuteUI()
        setMicrophoneState()
    }

    // MARK: - UI & Audio Logic
    private func updateSpeakerUI() {
        let image = isSpeakerActive ? "speaker.wave.2.fill" : "speaker.fill"
        speakerButton.setImage(
            UIImage(systemName: image)?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            ),
            for: .normal
        )
        
        UIView.animate(withDuration: 0.2) {
            self.speakerButton.backgroundColor = self.isSpeakerActive ?
                .white.withAlphaComponent(0.25) :
                .systemRed.withAlphaComponent(0.3)
        }
    }

    private func updateMuteUI() {
        let image = isMuted ? "mic.slash.fill" : "mic.fill"
        muteButton.setImage(
            UIImage(systemName: image)?.withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            ),
            for: .normal
        )
        
        UIView.animate(withDuration: 0.2) {
            self.muteButton.backgroundColor = self.isMuted ?
                .systemRed.withAlphaComponent(0.3) :
                .white.withAlphaComponent(0.25)
        }
    }

    private func setAudioOutput() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: SpeechRecognitionService.speachOptions)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }

    private func setMicrophoneState() {
        if isMuted {
            print("666666 - 1111 stopRecognition")
            recognizer.stopRecognition()
        } else {
            print("666666 - 111 startRecognition")
            recognizer.startRecognition()
        }
    }
    
    private func showSubs() {
        stopRingtone()
        let subsView = SubsView()
        subsView.vc = self
        
        AnalyticService.shared.logEvent(name: "showSubs from call", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            if self.view.isCurrentDeviceiPad() {
                subsView.scrollToBottom()
//            }
            subsView.yearlyButtonTapped()
        }
    }
}

// MARK: - UIColor Extension
extension UIColor {
    func darker(by percentage: CGFloat) -> UIColor {
        return self.adjustBrightness(by: -percentage)
    }
    
    func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            b = max(min(b + (percentage / 100.0), 1.0), 0.0)
            return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        }
        return self
    }
}
