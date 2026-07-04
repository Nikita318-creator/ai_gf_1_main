import UIKit
import SnapKit
import AudioToolbox

class AllChatsViewController: UIViewController {

    private struct TelegramColors {
        static let primary = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let cardBackground = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) // #2C2C2E
        static let messageBackground = UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1.0) // #38383A
        static let userMessageBackground = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0) // #3390DC
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0) // #A4A4A8
        static let separator = UIColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0) // #48484A
    }
    
    private let allChatsView = AllChatsView()
    private let viewModel = AllChatsViewModel()

    override func loadView() {
        view = allChatsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        setupActions()
        showSubsIfNeeded()
        
        if UserDefaults.standard.bool(forKey: MainHelper.shared.needShowTrialPayWallKey) {
//            showTrialSubs() // todo думаю показывать его или нет???
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем список чатов при каждом появлении экрана
        allChatsView.currentFilter = allChatsView.currentFilter // тут через костыль релоад, подгрузка, фильтр и обновление
        
        allChatsView.storyOpenedHandler = { [weak self] isVisible in
            self?.tabBarController?.tabBar.isHidden = !isVisible
        }
        
        if MainHelper.shared.needOpenCreateNewAI {
            MainHelper.shared.needOpenCreateNewAI = false
            newChatButtonTapped()
        }
        
        if ConfigService.shared.isFreeMode {
            showFreeModePopup()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        allChatsView.updateForRLTIfNeeded()
    }
    
    private func showFreeModePopup() {
        let lastShowDateKey = "last_free_mode_show_date"
        let streakCountKey = "user_login_streak_count"
        let premActivationDateKey = "free_premium_start_date"
        let isPremActiveKey = "is_free_premium_active"
        
        let calendar = Calendar.current
        let today = Date()
        
        // Форматируем дату для сравнения "был ли вход сегодня"
        let todayString = "\(calendar.component(.year, from: today))-\(calendar.component(.month, from: today))-\(calendar.component(.day, from: today))"
        let lastDate = UserDefaults.standard.string(forKey: lastShowDateKey)
        
        // 1. Проверка: показывали ли уже сегодня?
        if lastDate == todayString {
            print("сегодня уже видел свой подарок. Не части.")
            return
        }
        
        var currentStreak = UserDefaults.standard.integer(forKey: streakCountKey)
        
        // 2. ПРОВЕРКА ПРОПУСКА
        if let lastDateString = lastDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-M-d"
            
            if let lastShowDate = dateFormatter.date(from: lastDateString) {
                let startOfLast = calendar.startOfDay(for: lastShowDate)
                let startOfToday = calendar.startOfDay(for: today)
                let diff = calendar.dateComponents([.day], from: startOfLast, to: startOfToday).day ?? 0
                
                if diff > 1 {
                    AnalyticService.shared.logEvent(name: "FreeMode currentStreak LOST", properties: ["currentStreak":"\(currentStreak)"])
                    currentStreak = 1 // Сбрасываем на 1, чтобы увидел День 1 попап
                }
            }
        }
        
        // Показываем попап (со 2-го по 7-й день включительно)
        // На 7-й день внутри попапа сработает логика с твоим новым текстом MessageOnDay7
        // чувакам с премиумом не показываем эту ебатень но дни считает пусть - почеум нет, просто логика закостылется если перестать считать
        if currentStreak > 0, currentStreak <= 7, !IAPService.shared.hasActiveSubscription {
            let popup = FreeModePopupView(currentDay: currentStreak)
            popup.alpha = 0
            view.addSubview(popup)
            
            popup.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            UIView.animate(withDuration: 0.4) {
                popup.alpha = 1
            }
        }
        
        if currentStreak == 7 {
            // --- ПРАЗДНИЧНЫЙ ЭФФЕКТ ---
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1022) // Звук успеха
            
            // --- АКТИВАЦИЯ ПРЕМИУМА ---
            UserDefaults.standard.set(true, forKey: isPremActiveKey)
            UserDefaults.standard.set(today, forKey: premActivationDateKey)
            
        } else if currentStreak > 7 {
            // --- ПРОВЕРКА ИСТЕЧЕНИЯ 3-Х ДНЕЙ ---
            if let activationDate = UserDefaults.standard.object(forKey: premActivationDateKey) as? Date {
                let daysPassed = calendar.dateComponents([.day], from: activationDate, to: today).day ?? 0
                
                AnalyticService.shared.logEvent(name: "FreeMode daysPassed", properties: ["daysPassed":"\(daysPassed)"])
                
                if daysPassed >= 3 {
                    // Срок вышел — обнуляем всё по кругу
                    currentStreak = 0
                    UserDefaults.standard.set(false, forKey: isPremActiveKey)
                    UserDefaults.standard.removeObject(forKey: premActivationDateKey)
                    print("Premium период окончен. Стрик сброшен для нового цикла.")
                }
            }
        }
        
        AnalyticService.shared.logEvent(name: "FreeMode currentStreak", properties: ["currentStreak":"\(currentStreak)"])
        
        currentStreak += 1
        UserDefaults.standard.set(todayString, forKey: lastShowDateKey)
        UserDefaults.standard.set(currentStreak, forKey: streakCountKey)
        UserDefaults.standard.synchronize()
    }
    
    private func showTrialSubs() {
//        tabBarController?.tabBar.isHidden = true
//        
//        let subsView = TrialSubsView()
//        subsView.vc = self
//        subsView.onPaywallClosedHandler = { [weak self] in
//            self?.tabBarController?.tabBar.isHidden = false
//        }
//        
//        AnalyticService.shared.logEvent(name: "showTrialSubs", properties: ["":""])
//        
//        view.addSubview(subsView)
//
//        subsView.snp.remakeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//
//        // needUpdateProductsByTapYearlyButton:
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            subsView.yearlyButtonTapped()
//            subsView.scrollToBottom()
//            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
//                subsView.yearlyButtonTapped()
//            }
//        }
    }
    
    private func setupTableView() {
        allChatsView.tableView.delegate = self
        allChatsView.tableView.dataSource = self
    }

    private func setupViewModel() {
        viewModel.onChatsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.allChatsView.tableView.reloadData()
            }
        }
        viewModel.loadChats() // Загружаем чаты при старте
    }

    private func setupActions() {
        allChatsView.newChatButton.addTarget(self, action: #selector(newChatButtonTapped), for: .touchUpInside)
        
        allChatsView.goToChatHandler = { [weak self] avatarID in
            guard let self else { return }
            
            let currentAssistant = viewModel.chats.first { $0.assistantAvatar == avatarID }
            
            MainHelper.shared.isCurrentAssistantPremium = (currentAssistant?.isPremium ?? false) && !IAPService.shared.hasActiveSubscription
            MainHelper.shared.isCurrentAssistantPremiumVoice = currentAssistant?.isPremium ?? false
            print("opened chat isPremium: \(currentAssistant?.isPremium ?? false)")
            
            let selectedAssistant = AssistantsService().getAllConfigs().first { $0.avatarImageName == avatarID }
            MainHelper.shared.currentAssistant = selectedAssistant
            MainHelper.shared.isFirstMessageInChat = true
            AnalyticService.shared.logEvent(name: "chat selected from stories", properties: ["index:":"\(avatarID)", "name:":"\(selectedAssistant?.assistantName ?? "")"])
            
            let aiChatViewController = MainChatVC()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
            present(aiChatViewController, animated: false)
        }
        
        allChatsView.filterChatsHandler = { [weak self] filter in
            guard let self else { return }
            viewModel.filterChats(for: filter)
        }
    }

    private func showSubsIfNeeded() {
        if MainHelper.shared.needOpenPaywall {
            showSubs()
            MainHelper.shared.needOpenPaywall = false
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    private func showSubs() {
        let subsView = SubsView(isOnboarding: true)
        subsView.vc = self
        
        subsView.onPaywallClosedHandler = { [weak self] in
            guard let self else { return }
            tabBarController?.tabBar.isHidden = false
        }
        
        AnalyticService.shared.logEvent(name: "showSubs from Onboarding", properties: ["":""])
        
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        // needUpdateProductsByTapYearlyButton:
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            if self.view.isCurrentDeviceiPad() {
                subsView.scrollToBottom()
//            }
            subsView.yearlyButtonTapped()
        }
    }
    
    @objc private func newChatButtonTapped() {
        AnalyticService.shared.logEvent(name: "create new chat ButtonTapped", properties: ["":""])

        UserDefaults.standard.set(true, forKey: "hasAlreadyShownNewChatHighlight")

        let createGFVC = CreateGFVCNew()
        createGFVC.modalPresentationStyle = .fullScreen
        createGFVC.isModalInPresentation = true
        createGFVC.completionHandler = { [weak self] in
            self?.allChatsView.currentFilter = .createdByUser
        }
        present(createGFVC, animated: true)
    }
    
    @objc private func newChatButtonOnEmptyScreenTapped() {
        if allChatsView.currentFilter == .roleplay {
            AnalyticService.shared.logEvent(name: "create new roleplay ButtonTapped", properties: ["":""])
            tabBarController?.selectedIndex = 1
        } else {
            newChatButtonTapped()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AllChatsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.chats.isEmpty {
            emptyChatList()
        } else {
            restoreChatList()
        }
        return viewModel.chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListItemCell.identifier, for: indexPath) as? ChatListItemCell else { return UITableViewCell() }
        let chat = viewModel.chat(at: indexPath)
        cell.configure(with: chat)
        
        if UnreadMessagesService.shared.lasChatUnreadID == chat.id {
            cell.setUnread()
        }
        
        let didReceiveFirstMessage = UserDefaults.standard.bool(forKey: "didReceiveFirstMessage")
        
        if GEOService.shared.isAsionGeo {
            if !didReceiveFirstMessage, chat.assistantAvatar == "asion58" {
                cell.setUnread()
            }
        } else {
            if !didReceiveFirstMessage, chat.assistantAvatar == "latina3" {
                cell.setUnread()
            }
        }
        
        if chat.isPremium {
            cell.setPremium()
        } else if chat.assistantAvatar.contains("milf") {
            cell.setMilf()
        } else if chat.assistantAvatar.contains("audio") {
            cell.setVoice()
        } else if chat.assistantAvatar.contains("ex") {
            cell.setEx()
        } else if chat.assistantAvatar.contains("roleplay") {
            cell.setRole(getBage(for: chat.assistantAvatar.replacingOccurrences(of: "roleplay", with: "")))
        } else if ["asion74"].contains(chat.assistantAvatar) {
            cell.setRole(getBage(for: "1"))
        } else if ["asion49"].contains(chat.assistantAvatar) {
            cell.setRole(getBage(for: "2"))
        } else if ["asion72"].contains(chat.assistantAvatar) {
            cell.setRole(getBage(for: "6"))
        } else if ["asion89"].contains(chat.assistantAvatar) {
            cell.setRole(getBage(for: "9"))
        } else if ["asion35"].contains(chat.assistantAvatar) {
            cell.setRole(getBage(for: "10"))
        } else if ["asion36"].contains(chat.assistantAvatar) {
            cell.setRole(getBage(for: "11"))
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        MainHelper.shared.isCurrentAssistantPremium = (viewModel.chat(at: indexPath).isPremium || (viewModel.chat(at: indexPath).assistantAvatar.contains("roleplay"))) && !IAPService.shared.hasActiveSubscription // todo убрал ролплей из премиум
        MainHelper.shared.isCurrentAssistantPremium = viewModel.chat(at: indexPath).isPremium && !IAPService.shared.hasActiveSubscription

        if UnreadMessagesService.shared.lasChatUnreadID == viewModel.chat(at: indexPath).id {
            AnalyticService.shared.logEvent(name: "opened unread message", properties: ["":""])
            UnreadMessagesService.shared.lasChatUnreadID = nil
        }
        
        let didReceiveFirstMessage = UserDefaults.standard.bool(forKey: "didReceiveFirstMessage")
        if GEOService.shared.isAsionGeo {
            if !didReceiveFirstMessage, viewModel.chat(at: indexPath).assistantAvatar == "asion58" {
                UserDefaults.standard.set(true, forKey: "didReceiveFirstMessage")
                MainHelper.shared.isCurrentAssistantPremium = false
            }
        } else {
            if !didReceiveFirstMessage, viewModel.chat(at: indexPath).assistantAvatar == "latina3" {
                UserDefaults.standard.set(true, forKey: "didReceiveFirstMessage")
                MainHelper.shared.isCurrentAssistantPremium = false
            }
        }
        
        MainHelper.shared.isCurrentAssistantPremiumVoice = viewModel.chat(at: indexPath).isPremium
        MainHelper.shared.isVoiceChat = viewModel.chat(at: indexPath).assistantAvatar.contains("audio")

        print("Selected chat isPremium: \(viewModel.chat(at: indexPath).isPremium)")

        // брал всегда по уникальному аватару - но теперь кастом чаты могут буть не с уникальным аватаром!
        let selectedAssistant = AssistantsService().getAllConfigs().first(where: { $0.id == viewModel.chat(at: indexPath).id })
        MainHelper.shared.currentAssistant = selectedAssistant
        MainHelper.shared.isFirstMessageInChat = true
        AnalyticService.shared.logEvent(name: "chat selected", properties: ["index:":"\(indexPath.row)", "name:":"\(selectedAssistant?.assistantName ?? "")"])
        
        let aiChatViewController = MainChatVC()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.isCurrentDeviceiPad() ? 130 : 80 // Высота ячейки чата
    }
    
    private func emptyChatList() {
        // 1. Создаем контейнер-вью для иконки
        let emptyView = UIView(frame: allChatsView.tableView.bounds)
        
        // 2. Создаем кнопку
        let newChatButton = UIButton(type: .custom)
        
        // 3. Настраиваем изображение
        let plusImage = UIImage(systemName: "plus.circle.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 80, weight: .regular))
        newChatButton.setImage(plusImage, for: .normal)
        newChatButton.tintColor = TelegramColors.primary
        
        // 4. Добавляем таргет для обработки нажатия
        newChatButton.addTarget(self, action: #selector(newChatButtonOnEmptyScreenTapped), for: .touchUpInside)
        
        // 5. Добавляем кнопку в контейнер-вью
        emptyView.addSubview(newChatButton)
        
        // 6. Используем SnapKit для центрирования кнопки
        newChatButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(80) // Размер кнопки/иконки
        }
        
        // 7. Устанавливаем нашу emptyView как backgroundView таблицы
        allChatsView.tableView.backgroundView = emptyView
        allChatsView.tableView.separatorStyle = .none
    }

    // 8. Теперь нужно предусмотреть, что делать, когда чаты появятся
    // Эту логику лучше вынести в отдельный метод, который будет вызываться,
    // когда данные в таблице не пустые.
    private func restoreChatList() {
        allChatsView.tableView.backgroundView = nil
        allChatsView.tableView.separatorStyle = .none
    }
    
    private func getBage(for number: String) -> String {
        switch number {
        case "1":
            "role.secretary".localize()
        case "2":
            "role.teacher".localize()
        case "3":
            "role.nurse".localize()
        case "4":
            "role.elf".localize()
        case "5":
            "role.neighbor".localize()
        case "6":
            "role.boss".localize()
        case "7":
            "role.fitness".localize()
        case "8":
            "role.animeGirl".localize()
        case "9":
            "role.friendsGirl".localize()
        case "10":
            "role.sistersFriend".localize()
        case "11":
            "role.sensitive".localize()
        case "12":
            "role.princess".localize()
        default: ""
        }
    }
    
    // MARK: - SWIPE TO DELETE
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "ClearChatHistory".localize()) { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let assistantsService = AssistantsService()
            let selectedAssistant = assistantsService.getAllConfigs().first(where: { $0.id == self.viewModel.chat(at: indexPath).id })
            MessageHistoryService().getAllMessages(forAssistantId: selectedAssistant?.id ?? "").forEach {
                MessageHistoryService().deleteMessage(id: $0.id ?? "")
            }
            
            assistantsService.getAllConfigs().reversed().forEach { assistantConfig in
                if assistantConfig.id != selectedAssistant?.id {
                    assistantsService.updateConfig(id: assistantConfig.id ?? "", config: assistantConfig)
                }
            }

            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            
            viewModel.loadChats()
            tableView.reloadData()
            completionHandler(true)
            self.showToastNotification(message: "ChatHistoryCleared".localize())
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    
    private func showToastNotification(message: String) {
        // 1. Создаем контейнер для тоста в Telegram-стиле
        let toastContainer = UIView()
        toastContainer.backgroundColor = TelegramColors.cardBackground
        toastContainer.layer.cornerRadius = 14
        toastContainer.alpha = 0
        
        // Легкая тень, чтобы выделялся над ячейками
        toastContainer.layer.shadowColor = UIColor.black.cgColor
        toastContainer.layer.shadowOpacity = 0.4
        toastContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        toastContainer.layer.shadowRadius = 6
        
        // 2. Иконка галочки (или инфо)
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
        iconImageView.tintColor = TelegramColors.primary
        iconImageView.contentMode = .scaleAspectFit
        
        // 3. Текст
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = TelegramColors.textPrimary
        messageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        messageLabel.numberOfLines = 0
        
        // Собираем вьюху
        toastContainer.addSubview(iconImageView)
        toastContainer.addSubview(messageLabel)
        view.addSubview(toastContainer)
        
        // 4. Верстка элементов внутри тоста
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(22)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        // 5. Позиционируем сам тост (снизу экрана, чуть выше таббара)
        toastContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(20)
            make.height.equalTo(50)
            make.width.greaterThanOrEqualTo(200)
            make.width.lessThanOrEqualTo(view.snp.width).offset(-40)
        }
        
        // 6. Красивая анимация появления и исчезновения
        UIView.animate(withDuration: 0.3, animations: {
            toastContainer.alpha = 1
        }) { _ in
            // Ждем 2 секунды и плавно тушим
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
                toastContainer.alpha = 0
            }) { _ in
                toastContainer.removeFromSuperview() // Удаляем из иерархии
            }
        }
    }
}
