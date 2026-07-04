import UIKit
import SnapKit

// MARK: - Protocol for communication between Cell and VC
protocol GFOnboardingPageCellDelegate: AnyObject {
    func didCompletePage(at index: Int)
    func didUpdateName(yourName: String?, gfName: String?)
    func didSelectBodySize(type: String)
    func didChangeSliderValue(pageIndex: Int, value: Float)
    func didChooseDistance(keepDistance: Bool)
}

class CreateGFVCNew: UIViewController {

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.isScrollEnabled = false // User cannot scroll manually
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(GFOnboardingPageCell.self, forCellWithReuseIdentifier: "GFOnboardingPageCell")
        cv.backgroundColor = .clear
        return cv
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next".localize(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close".localize(), for: .normal)
        button.setTitleColor(UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()

    // MARK: - Data and State
    private var currentPage: Int = 0
    private let totalPages = 7
    private let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft

    // Stored user selections
    private var yourName: String?
    private var gfName: String?
    private var buttockSize: String?
    private var hairColor: String?
    private var breastSize: String?
    private var candorLevel: Float = 0.5
    private var modestyLevel: Float = 0.5
    private var keepDistance: Bool = false
    private var selectedAvatarAssetID: String?

    // Old sliders that will be a part of "deep settings"
    private var flirtLevel: Float = 0.5
    private var toneLevel: Float = 0.0
    private var attitudeLevel: Float = 0.0
    private var sarcasmLevel: Float = 0.0
    private var humorLevel: Float = 0.0
    private var prideLevel: Float = 0.0

    var completionHandler: (() -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTapGesture()
        updateTextForIPadIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the flow layout's item size is correct after the view is laid out
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = collectionView.bounds.size
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard view.isCurrentDeviceiPad() else { return }
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.invalidateLayout()
        }

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.layoutIfNeeded()
            let newSize = self.collectionView.bounds.size
            let newOffset = CGPoint(x: CGFloat(self.currentPage) * newSize.width, y: 0)
            self.collectionView.setContentOffset(newOffset, animated: false)
        }, completion: nil)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        if isRTL {
            currentPage = totalPages - 1
        }
        
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        
        view.addSubview(collectionView)
        view.addSubview(nextButton)
        view.addSubview(closeButton)
        
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        updateButtonVisibility()
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(25)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        nextButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(56)
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false 
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func nextTapped() {
        // Определяем следующий индекс в зависимости от направления
        let nextPageIndex: Int
        if isRTL {
            // Для RTL-языка: свайп "вперед" (next) означает скролл к предыдущей странице
            nextPageIndex = currentPage - 1
        } else {
            // Для LTR-языка: свайп "вперед" (next) означает скролл к следующей странице
            nextPageIndex = currentPage + 1
        }

        // Проверяем, не вышли ли мы за пределы
        if nextPageIndex >= 0 && nextPageIndex < totalPages {
            currentPage = nextPageIndex
            let indexPath = IndexPath(item: currentPage, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            updateButtonVisibility()
        } else if nextPageIndex == totalPages {
            // Если это последний экран для LTR
            createGF()
        } else if nextPageIndex == -1 {
            // Если это последний экран для RTL (поскольку индекс уменьшается)
            createGF()
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func updateButtonVisibility() {
        nextButton.setTitle("Next".localize(), for: .normal)
        
        if isRTL {
            if currentPage == 6 {
                // Disable next button until names are entered
                nextButton.isEnabled = false
                nextButton.backgroundColor = .gray
            } else {
                nextButton.isEnabled = true
                nextButton.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
            }
            
            // Hide next button on pages with direct actions (buttons/sliders)
            let hideNext = [5, 4, 1, 0].contains(currentPage)
            nextButton.isHidden = hideNext
        } else {
            if currentPage == 0 {
                // Disable next button until names are entered
                nextButton.isEnabled = false
                nextButton.backgroundColor = .gray
            } else {
                nextButton.isEnabled = true
                nextButton.backgroundColor = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)
            }
            
            // Hide next button on pages with direct actions (buttons/sliders)
            let hideNext = [1, 2, 5, 6].contains(currentPage)
            nextButton.isHidden = hideNext
        }
    }
    
    private func createGF() {
        guard let gfName = gfName, !gfName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "CreateYourGF.MissingName".localize(), message: "CreateYourGF.MissingName.MesageAlert".localize())
            return
        }

        var userSuppliedName = yourName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !userSuppliedName.isEmpty {
            userSuppliedName = "prompt.userName".localize() + userSuppliedName + ". "
        }
        
        // Start building the prompt based on all collected data
        let promptComponents: [String] = [
            "".localize(attribut: "CustomGFPromptsNew22", arguments: gfName),
            "".localize(attribut: "CustomGFPromptsNew23", arguments: buttockSize ?? ""),
            "".localize(attribut: "CustomGFPromptsNew24", arguments: breastSize ?? ""),
            "".localize(attribut: "CustomGFPromptsNew34", arguments: hairColor ?? ""),
            "".localize(attribut: "CustomGFPromptsNew25", arguments: "\(candorLevel * 100)%"),
            "".localize(attribut: "CustomGFPromptsNew26", arguments: "\(modestyLevel * 100)%"),
        ]
        
        var finalPrompt = userSuppliedName
        finalPrompt += promptComponents.joined(separator: " ")
        
        // Формирование итогового assistantInfo
        var finalAssistantInfo = "CustomGFPrompts25".localize()
        finalAssistantInfo += finalPrompt
        
        let assistantsService = AssistantsService()
        
        // потом можно расширить кастом аватар на огромное число копий фоток - пока ограничемся малым набором
        let finalAvatarName: String
        switch hairColor {
        case "CustomGFPromptsNew28".localize(): // red
            finalAvatarName = ["CustomAvatar3", "CustomAvatar16", "CustomAvatar17", "CustomAvatar18"].randomElement() ?? "CustomAvatar1"
        case "CustomGFPromptsNew29".localize(): // ginger
            finalAvatarName = ["CustomAvatar7", "CustomAvatar8", "CustomAvatar12", "CustomAvatar14", "CustomAvatar15"].randomElement() ?? "CustomAvatar1"
        case "CustomGFPromptsNew30".localize(): // blonde
            finalAvatarName = ["CustomAvatar1", "CustomAvatar4"].randomElement() ?? "CustomAvatar1"
        case "CustomGFPromptsNew31".localize(): // white
            finalAvatarName = ["CustomAvatar13"].randomElement() ?? "CustomAvatar1"
        case "CustomGFPromptsNew32".localize(): // pink
            finalAvatarName = ["CustomAvatar5", "CustomAvatar10", "CustomAvatar11"].randomElement() ?? "CustomAvatar1"
        case "CustomGFPromptsNew33".localize(): // brunette
            finalAvatarName = ["CustomAvatar2", "CustomAvatar6", "CustomAvatar9"].randomElement() ?? "CustomAvatar1"
        case "CustomGFPromptsNew35".localize(), "CustomGFPromptsNew36".localize(), "CustomGFPromptsNew37".localize(), "CustomGFPromptsNew38".localize():
            let existedAvatars = assistantsService.getAllConfigs().map { $0.avatarImageName }
            var avatarsArr = ["asion39", "asion48", "asion52", "asion56", "asion73", "asion92", "asion78"].filter { !existedAvatars.contains($0) }
            if avatarsArr.isEmpty {
                avatarsArr = ["asion39", "asion48", "asion52", "asion56", "asion73", "asion92", "asion78"]
            }
            print(avatarsArr)
            finalAvatarName = avatarsArr.randomElement() ?? ""
        default:
            finalAvatarName = "CustomAvatar1"
        }
        
        let newAssistant = AssistantConfig(
            id: UUID().uuidString,
            assistantName: gfName,
            aiModel: .gemini15Flash, // не используется
            tone: .soft, // не используется
            style: .friendly, // не используется
            expertise: .customGF,
            assistantInfo: "", // берется после, универсальное для всех
            userInfo: finalPrompt,
            avatarImageName: finalAvatarName
        )
        
        // Добавление новой AI Girlfriend через AssistantsService
        assistantsService.addConfig(newAssistant)
        MessageHistoryService().addMessage(
            Message(role: "assistant", content: newAssistant.expertise.rawValue.localize()),
            assistantId: newAssistant.id ?? ""
        )

        AnalyticService.shared.logEvent(name: "new chat create successfully", properties: ["":""])

        completionHandler?() // Вызываем handler об успешном создании
        dismiss(animated: true) // Закрываем экран
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localize(), style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CreateGFVCNew: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalPages
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GFOnboardingPageCell", for: indexPath) as? GFOnboardingPageCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        let currentIndex: Int
        if isRTL {
            currentIndex = totalPages - 1 - indexPath.item
        } else {
            currentIndex = indexPath.item
        }
        cell.configure(for: currentIndex)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // This is a backup to ensure state is correct
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        if isRTL {
            currentPage = totalPages - 1 - page
        } else {
            currentPage = page
        }
        updateButtonVisibility()
    }
}

// MARK: - GFOnboardingPageCellDelegate
extension CreateGFVCNew: GFOnboardingPageCellDelegate {
    func didCompletePage(at index: Int) {
        nextTapped()
    }
    
    func didUpdateName(yourName: String?, gfName: String?) {
        self.yourName = yourName
        self.gfName = gfName
        // Only on the first page, we enable the button
        let isValid = !(gfName?.isEmpty ?? true)
        nextButton.isEnabled = isValid
        nextButton.backgroundColor = isValid ? UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) : .gray
    }

    func didSelectBodySize(type: String) {
        if isRTL {
            if currentPage == 5 {
                self.buttockSize = type
            } else if currentPage == 4 {
                self.breastSize = type
            } else if currentPage == 1 {
                self.hairColor = type
            }
        } else {
            if currentPage == 1 {
                self.buttockSize = type
            } else if currentPage == 2 {
                self.breastSize = type
            } else if currentPage == 5 {
                self.hairColor = type
            }
        }
        nextTapped()
    }
    
    func didChangeSliderValue(pageIndex: Int, value: Float) {
        if pageIndex == 3 {
            self.candorLevel = value
        } else if pageIndex == 4 {
            self.modestyLevel = value
        }
    }
    
    func didChooseDistance(keepDistance: Bool) {
        self.keepDistance = keepDistance
        
        AnalyticService.shared.logEvent(name: "Create Custom GF final page:", properties: ["data:":"keepDistance: \(keepDistance), buttockSize: \(buttockSize ?? ""), breastSize: \(breastSize ?? ""), hairColor: \(hairColor ?? ""), candorLevel: \(candorLevel), modestyLevel: \(modestyLevel)"])        
        
        if IAPService.shared.hasActiveSubscription {
            createGF()
        } else {
            showSubs()
        }
    }
    
    private func showSubs() {
        let subsView = SubsView()
        subsView.vc = self
        subsView.purchasedHandler = { [weak self] in
            self?.createGF()
        }
        
        AnalyticService.shared.logEvent(name: "showSubs from Create GF New", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        // needUpdateProductsByTapYearlyButton:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            if self.view.isCurrentDeviceiPad() {
                subsView.scrollToBottom()
//            }
            subsView.yearlyButtonTapped()
        }
    }
}

extension CreateGFVCNew {
    func updateTextForIPadIfNeeded() {
        guard view.isCurrentDeviceiPad() else { return }
        
        nextButton.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold)
        closeButton.titleLabel?.font = .systemFont(ofSize: 26, weight: .medium)
    }
}
