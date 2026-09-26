import UIKit
import SnapKit
import AVFoundation

final class AudioCallVC: UIViewController {

    // MARK: - Properties & Dependencies
    private let assistant: AssistantProfile
    private let isOutgoing: Bool
    private let avatarImage: UIImage?

    private var callTimer: Timer?
    private var incomeRingToneTimer: Timer?
    private var callDuration: Int = 0
    private var audioPlayer: AVAudioPlayer?
    private var pulseAnimation: CABasicAnimation?
    private var sendTimer: Timer?

    private let viewModel = AIGFChatViewModel()
    private let recognizer = RecognitionManager()
    private let synthesizer = VoiceManager.shared
    
    private var textFromMic = ""
    private var isSpeakerActive = true
    private var isMuted = false

    private var helloSamples: [String] {
        (1...10).map { "call.hello\($0)".localize() }
    }

    // MARK: - UI Components
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        return UIVisualEffectView(effect: blurEffect)
    }()

    private let gradientOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = MyColors.background.withAlphaComponent(0.65)
        return view
    }()

    private let avatarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let animatedRingView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 80
        imageView.layer.borderColor = MyColors.primary.cgColor
        imageView.layer.borderWidth = 3
        
        imageView.layer.shadowColor = MyColors.primary.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 8)
        imageView.layer.shadowRadius = 20
        imageView.layer.shadowOpacity = 0.4
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = MyColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.5
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = MyColors.textSecondary
        label.textAlignment = .center
        label.text = "Calling...".localize()
        return label
    }()

    // MARK: - Action Buttons
    private let endCallButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "phone.down.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.accentRed
        button.layer.cornerRadius = 35
        
        button.layer.shadowColor = MyColors.accentRed.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.5
        return button
    }()

    private let answerCallButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "phone.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.avatarBackground
        button.layer.cornerRadius = 35
        
        button.layer.shadowColor = MyColors.avatarBackground.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.5
        return button
    }()
    
    private let speakerButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "speaker.wave.2.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.cardBackground
        button.layer.cornerRadius = 30
        button.layer.borderWidth = 1
        button.layer.borderColor = MyColors.separator.cgColor
        button.isHidden = true // Хак сохранен, пока не готова логика
        return button
    }()

    private let muteButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "mic.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        )
        button.setImage(image, for: .normal)
        button.tintColor = MyColors.textPrimary
        button.backgroundColor = MyColors.cardBackground
        button.layer.cornerRadius = 30
        button.layer.borderWidth = 1
        button.layer.borderColor = MyColors.separator.cgColor
        button.isHidden = true // Хак сохранен, пока не готова логика
        return button
    }()
    
    private let buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 30
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()

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
        
        AmplitudeManager.shared.logEvent(name: "Call viewDidLoad", properties: ["": ""])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPulseAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUpCallSession()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = MyColors.background
        
        view.addSubview(backgroundImageView)
        view.addSubview(blurEffectView)
        view.addSubview(gradientOverlayView)
        
        view.addSubview(avatarContainerView)
        avatarContainerView.addSubview(animatedRingView)
        avatarContainerView.addSubview(avatarImageView)
        
        view.addSubview(nameLabel)
        view.addSubview(statusLabel)
        
        // Добавляем неактивные кнопки обратно в иерархию (скрытые через isHidden)
        view.addSubview(speakerButton)
        view.addSubview(muteButton)
        view.addSubview(buttonsStackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        gradientOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
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
            make.top.equalTo(avatarContainerView.snp.bottom).offset(28)
            make.horizontalEdges.equalToSuperview().inset(24)
        }

        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
        }
        
        buttonsStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-50)
            make.height.equalTo(70)
        }
    }
    
    private func setupUIForCallType() {
        buttonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if isOutgoing {
            buttonsStackView.addArrangedSubview(endCallButton)
            endCallButton.snp.makeConstraints { make in make.size.equalTo(70) }
            statusLabel.text = "Calling...".localize()
        } else {
            buttonsStackView.addArrangedSubview(endCallButton)
            buttonsStackView.addArrangedSubview(answerCallButton)
            
            endCallButton.snp.makeConstraints { make in make.size.equalTo(70) }
            answerCallButton.snp.makeConstraints { make in make.size.equalTo(70) }
            
            statusLabel.text = "Incoming Call".localize()
        }
    }

    private func configureCallUI() {
        if assistant.avatarImageName.isEmpty {
            backgroundImageView.image = avatarImage
            avatarImageView.image = avatarImage
        } else {
            backgroundImageView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (assistant.avatarImageName + "_") : assistant.avatarImageName)) ?? UIImage(named: assistant.avatarImageName)
            avatarImageView.image = (UIImage(named: APIManager.shared.isRemotePhoto ? (assistant.avatarImageName + "_") : assistant.avatarImageName)) ?? UIImage(named: assistant.avatarImageName)
        }
        
        if let name = BaseManager.shared.currentAssistant?.avatarImageName, name.contains("waifuInOutfit_") {
            let photo = MiniGamesPhotoCacheService.shared.getImage(named: name)
            backgroundImageView.image = photo
            avatarImageView.image = photo
        }
        
        nameLabel.text = assistant.name
    }

    private func setupActions() {
        endCallButton.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)
        answerCallButton.addTarget(self, action: #selector(answerCallTapped), for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(speakerButtonTapped), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        
        addButtonPressAnimations()
        
        recognizer.vc = self
        recognizer.onResult = { [weak self] text in
            guard let self = self else { return }

            self.textFromMic = text
            self.sendTimer?.invalidate()

            self.sendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                                         
                if !self.textFromMic.isEmpty {
                    self.recognizer.stopRecognition()
                    self.sendMessage()
                }
            }
        }
        
        viewModel.onAudioMessagesUpdated = { [weak self] _ in
            guard
                let self,
                let textToSpeak = viewModel.messagesAI.last(where: { $0.role == "assistant" && !$0.isLoading })?.content
            else { return }
             
            self.recognizer.stopRecognition()
            let isAnime = (11...20).map({ "mainAvatar\($0)" }).contains(BaseManager.shared.currentAssistant?.avatarImageName ?? "")
            self.synthesizer.speak(text: textToSpeak, isAnime: isAnime)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnFinish),
            name: .updateAllAudioCellsOnFinish,
            object: nil
        )
    }
    
    // MARK: - Animations
    private func startPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 1.6
        pulse.fromValue = 1.0
        pulse.toValue = 1.12
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        
        animatedRingView.layer.add(pulse, forKey: "pulse")
        
        let ringLayer = CAShapeLayer()
        let ringPath = UIBezierPath(ovalIn: CGRect(x: 10, y: 10, width: 180, height: 180))
        ringLayer.path = ringPath.cgPath
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = MyColors.primary.withAlphaComponent(0.4).cgColor
        ringLayer.lineWidth = 2
        animatedRingView.layer.addSublayer(ringLayer)
        
        self.pulseAnimation = pulse
    }
    
    private func stopPulseAnimation() {
        animatedRingView.layer.removeAllAnimations()
        pulseAnimation = nil
    }
    
    private func addButtonPressAnimations() {
        [endCallButton, answerCallButton].forEach { button in
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction) {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .allowUserInteraction) {
            sender.transform = .identity
        }
    }
    
    // MARK: - Call Flow Logic
    private func startCallSimulation() {
        playRingtone()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
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
        UIView.animate(withDuration: 0.25, animations: {
            self.buttonsStackView.alpha = 0
        }) { _ in
            self.buttonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            self.buttonsStackView.addArrangedSubview(self.endCallButton)
            self.endCallButton.snp.makeConstraints { make in make.size.equalTo(70) }
            
            UIView.animate(withDuration: 0.25) {
                self.buttonsStackView.alpha = 1
            }
        }
        
        stopRingtone()
        startCallTimer()
        callStarted()
    }

    private func playRingtone() {
        guard let url = Bundle.main.url(forResource: "phoneCalling", withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: RecognitionManager.speachOptions)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Audio session error: \(error.localizedDescription)")
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
        statusLabel.textColor = MyColors.textPrimary
        callDuration = 0
        updateTimer()
        
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    private func callStarted() {
        recognizer.stopRecognition()
        let isAnime = (11...20).map({ "mainAvatar\($0)" }).contains(BaseManager.shared.currentAssistant?.avatarImageName ?? "")
        synthesizer.speak(text: helloSamples.randomElement() ?? "", isAnime: isAnime)
        
        stopPulseAnimation()
    }
    
    private func sendMessage() {
        var previousMessages = ""
        if viewModel.messagesAI.count >= 2 {
            previousMessages = "\nFor context, I'm attaching our recent messages\n"
            + (self.viewModel.messagesAI[self.viewModel.messagesAI.count - 2].content)
            + "\nYou responded: "
            + (self.viewModel.messagesAI.last?.content ?? "")
            + "\nAnd now I'm asking: "
        }

        recognizer.stopRecognition()
        viewModel.systemPrompt = BaseManager.shared.getSystemPromptForCurrentAssistant()
        viewModel.safeSystemPrompt = BaseManager.shared.getSafeSystemPromptForCurrentAssistant()
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
        AmplitudeManager.shared.logEvent(name: "Call endCallTapped", properties: ["": ""])

        cleanUpCallSession()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc private func answerCallTapped() {
        AmplitudeManager.shared.logEvent(name: "Call answerCallTapped", properties: ["": ""])

        incomeRingToneTimer?.invalidate()
        incomeRingToneTimer = nil
        
        guard SubscriptionManager.shared.hasActiveSubscription else {
            showSubs()
            return
        }
        
        startActiveCall()
    }
    
    @objc private func updateOnFinish() {
        if !isMuted {
            recognizer.startRecognition()
        }
    }
    
    // MARK: - Handlers (Stubs for future logic)
    @objc private func speakerButtonTapped() {
        AmplitudeManager.shared.logEvent(name: "Call speakerButtonTapped", properties: ["": ""])
    }

    @objc private func muteButtonTapped() {
        AmplitudeManager.shared.logEvent(name: "Call muteButtonTapped", properties: ["": ""])
    }
    
    private func cleanUpCallSession() {
        callTimer?.invalidate()
        incomeRingToneTimer?.invalidate()
        callTimer = nil
        incomeRingToneTimer = nil
        
        stopRingtone()
        stopPulseAnimation()
        recognizer.stopRecognition()
        
        synthesizer.currentSpeakinID = nil
        synthesizer.stopSpeaking()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }
    
    private func showSubs() {
        stopRingtone()
        let subsView = PaywallView()
        subsView.vc = self
        
        AmplitudeManager.shared.logEvent(name: "showSubs from call", properties: ["": ""])
        
        view.addSubview(subsView)
        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            subsView.scrollToBottom()
            subsView.yearlyButtonTapped()
        }
    }
}
