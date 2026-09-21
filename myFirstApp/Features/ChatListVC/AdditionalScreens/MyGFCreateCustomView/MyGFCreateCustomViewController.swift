import UIKit
import SnapKit

class MyGFCreateCustomViewController: UIViewController {
    private let viewModel = MyGFCreateCustomViewModel()
    private lazy var slides: [MyGFScreenData] = viewModel.slides
    
    // MARK: - UI Components
    private lazy var progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.trackTintColor = MyColors.bubbleBackground
        view.progressTintColor = MyColors.primary
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        ), for: .normal)
        btn.tintColor = MyColors.textSecondary
        btn.backgroundColor = MyColors.cardBackground
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        return btn
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.isScrollEnabled = false
        cv.register(CreateMyGFCell.self, forCellWithReuseIdentifier: CreateMyGFCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CreateMyGF.action.next".localize(), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.setTitleColor(MyColors.textPrimary, for: .normal)
        btn.setTitleColor(MyColors.textSecondary, for: .disabled)
        btn.backgroundColor = MyColors.cardBackground
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()

    private var currentIndex: Int = 0
    private let selectionManager = CreateMyGFUseCase.shared

    var onSuccessCreated: (() -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateProgress()
        updateTextForIPadIfNeeded()
        checkSlideCompletion()
        
        AmplitudeManager.shared.logEvent(name: "CreateDreamWaifuVC opend", properties: ["":""])
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = MyColors.background
        collectionView.semanticContentAttribute = .forceLeftToRight
        
        view.addSubview(progressBar)
        view.addSubview(collectionView)
        view.addSubview(actionButton)
        view.addSubview(closeButton)
        
        progressBar.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalTo(closeButton.snp.leading).offset(-14)
            make.height.equalTo(4)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(32)
        }
        
        actionButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(52)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top).offset(-20)
        }
    }
    
    // MARK: - Actions
    @objc private func handleClose() {
        dismiss(animated: true)
    }
    
    @objc private func handleNext() {
        if currentIndex < slides.count - 1 {
            currentIndex += 1
            let indexPath = IndexPath(item: currentIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            let cell = collectionView.visibleCells.first as? CreateMyGFCell
            cell?.scrollView.setContentOffset(.zero, animated: true)
            updateProgress()
            updateButtonTitle()
            checkSlideCompletion()
        } else {
            checkSubscriptionAndFinish()
        }
    }
    
    private func checkSubscriptionAndFinish() {
        if SubscriptionManager.shared.hasActiveSubscription {
            let nameAlert = UIAlertController(
                title: "CreateMyGF.nameAlert.title".localize(),
                message: "CreateMyGF.nameAlert.message".localize(),
                preferredStyle: .alert
            )
            
            // Поле 1: Имя персонажа (Waifu)
            nameAlert.addTextField { textField in
                textField.placeholder = "CreateMyGF.nameAlert.placeholder".localize() // e.g. "Her name (e.g. Luna)"
                textField.autocapitalizationType = .words
            }
            
            // Поле 2: Имя пользователя
            nameAlert.addTextField { textField in
                textField.placeholder = "CreateMyGF.userNameAlert.placeholder".localize() // e.g. "Your name (e.g. Alex)"
                textField.autocapitalizationType = .words
            }
            
            let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self, weak nameAlert] _ in
                guard let self = self else { return }
                
                let waifuNameInput = nameAlert?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                let userNameInput = nameAlert?.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let finalWaifuName = (waifuNameInput?.isEmpty == false) ? waifuNameInput! : "MyGF".localize()
                let finalUserName = (userNameInput?.isEmpty == false) ? userNameInput! : ""
                
                self.finalizeWaifuCreation(assistantName: finalWaifuName, userName: finalUserName)
            }
            
            nameAlert.addAction(confirmAction)
            present(nameAlert, animated: true)
        } else {
            UIView.animate(withDuration: 0.3) {
                self.showSubs()
            }
        }
    }
    
    private func finalizeWaifuCreation(assistantName: String, userName: String) {
        let config = selectionManager.getFinalConfiguration()
        print("✅ Waifu Created: \(assistantName), User Name: \(userName)")
        AmplitudeManager.shared.logEvent(name: "CreateDreamWaifuVC Waifu Created!", properties: [
            "config": "\(config)",
            "name": assistantName,
            "userName": userName
        ])
        
        let waifuDict = config["waifu_config"] as? [String: [String]] ?? [:]
        
        // Формируем список всех выбранных параметров с локализацией
        let allTraitsDescription = waifuDict.map { questionId, selectedOptions in
            let localizedOptions = selectedOptions.map { $0.localize() }.joined(separator: ", ")
            return "- \(questionId): \(localizedOptions)"
        }.joined(separator: "\n")
        
        // Формируем блок обращения к пользователю
        let userInstruction: String
        if !userName.isEmpty {
            userInstruction = "Always address the user by their name: '\(userName)' in your responses."
        } else {
            userInstruction = "Address the user warmly and naturally."
        }
        
        // Единый системный контекст
        let assistantInfoContext = """
        Name: \(assistantName)
        \(userInstruction)
        
        User Selected Configuration & Persona Traits:
        \(allTraitsDescription)
        """
        
        print("🤖 Full System Prompt Context:\n\(assistantInfoContext)")
        
        // MARK: - Logic for dynamic Image selection
        let eyeType = waifuDict["eye_type"]?.first ?? ""
        let avatarImageName: String
        let countKey = "count_\(eyeType)"
        let lastIdxKey = "lastIdx_\(eyeType)"
        let creationCount = UserDefaults.standard.integer(forKey: countKey)
        let lastIndex = UserDefaults.standard.integer(forKey: lastIdxKey) // 1 или 2
        
        let imagePrefix: String
        switch eyeType {
        case "CreateMyGF.option.almond".localize():           imagePrefix = "MyGF1"
        case "CreateMyGF.option.big_doe".localize():          imagePrefix = "MyGF2"
        case "CreateMyGF.option.glowing_red".localize():      imagePrefix = "MyGF3"
        case "CreateMyGF.option.mysterious_purple".localize(): imagePrefix = "MyGF4"
        default:                                                    imagePrefix = "MyGF1"
        }
        
        if creationCount >= 3 {
            let randomSuffix = ["", "_1"].randomElement() ?? ""
            avatarImageName = "\(imagePrefix)\(randomSuffix)"
        } else {
            let newIndex = (lastIndex == 1) ? 2 : 1
            let suffix = (newIndex == 2) ? "_1" : ""
            avatarImageName = "\(imagePrefix)\(suffix)"
            
            UserDefaults.standard.set(newIndex, forKey: lastIdxKey)
            UserDefaults.standard.set(creationCount + 1, forKey: countKey)
        }
        
        let createdAssistantID = UUID().uuidString
        let createdAssistant = AIGirlfriendsConfig(
            id: createdAssistantID,
            assistantName: assistantName,
            assistantInfo: assistantInfoContext,
            avatarImageName: avatarImageName
        )
        
        let messageId = UUID().uuidString
        AIGirlfriendsManager().addConfig(createdAssistant)
        AIGirlfriendMessagesManager().addMessage(
            AIGFMessageModel(role: "assistant", content: "Hi".localize(), id: messageId),
            assistantId: createdAssistantID,
            messageId: messageId
        )
        
        BaseManager.shared.needOpenChatWithId = createdAssistantID

        showCompletionAlert()
    }
    
    private func showSubs() {
        let subsView = PaywallView()
        subsView.vc = self
        subsView.onPaywallClosedHandler = { [weak self] in
            self?.tabBarController?.tabBar.isHidden = false
        }
        
        AmplitudeManager.shared.logEvent(name: "showSubs from CreateDreamWaifu", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            subsView.yearlyButtonTapped()
        }
    }
    
    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: "CreateMyGF.alert.title".localize(),
            message: "CreateMyGF.alert.message".localize(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "CreateMyGF.alert.button".localize(), style: .default) { _ in
            self.onSuccessCreated?()
            self.selectionManager.clearAll() // только тут сбрасывать думаю - а иначе не сбрасываем прогресс юзера
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func updateProgress() {
        let progress = Float(currentIndex + 1) / Float(slides.count)
        progressBar.setProgress(progress, animated: true)
    }
    
    private func updateButtonTitle() {
        if currentIndex == slides.count - 1 {
            actionButton.setTitle("CreateMyGF.action.finish".localize(), for: .normal)
        } else {
            let remaining = slides.count - currentIndex - 1
            let format = "CreateMyGF.action.next_count".localize()
            actionButton.setTitle(String(format: format, remaining), for: .normal)
        }
    }
    
    // MARK: - Selection Callback
    func didUpdateSelection() {
        checkSlideCompletion()
        
        let indexPath = IndexPath(item: currentIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? CreateMyGFCell {
            cell.refreshSelections()
        }
    }
    
    private func checkSlideCompletion() {
        let currentSlide = slides[currentIndex]
        let isComplete = selectionManager.isSlideComplete(questions: currentSlide.questions)
        
        actionButton.isEnabled = isComplete
        
        UIView.animate(withDuration: 0.3) {
            self.actionButton.backgroundColor = isComplete
                ? (self.currentIndex == self.slides.count - 1
                    ? MyColors.accentRed
                    : MyColors.primary)
                : MyColors.cardBackground
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension MyGFCreateCustomViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateMyGFCell.identifier, for: indexPath) as? CreateMyGFCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: slides[indexPath.item], delegate: self)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - iPad Support
extension MyGFCreateCustomViewController {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        actionButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            let indexPath = IndexPath(item: self.currentIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }, completion: nil)
    }
}
