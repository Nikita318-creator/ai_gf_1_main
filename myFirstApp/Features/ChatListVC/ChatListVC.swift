import UIKit
import ApphudSDK
import SnapKit
import AudioToolbox

class ChatListVC: UIViewController {
    private let allChatsView = ChatListView()
    private let viewModel = ChatListVM()

    override func loadView() {
        view = allChatsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        setupActions()
        showSubsIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        BaseManager.shared.needOpenChatWithId = nil
        
        viewModel.loadChats()
        
        allChatsView.storyOpenedHandler = { [weak self] isVisible in
            self?.tabBarController?.tabBar.isHidden = !isVisible
        }
        
        if APIManager.shared.canGotPremiumForDailyLogin {
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
        
        let todayString = "\(calendar.component(.year, from: today))-\(calendar.component(.month, from: today))-\(calendar.component(.day, from: today))"
        let lastDate = UserDefaults.standard.string(forKey: lastShowDateKey)
        
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
                    AmplitudeManager.shared.logEvent(name: "FreeMode currentStreak LOST", properties: ["currentStreak":"\(currentStreak)"])
                    currentStreak = 1 // Сбрасываем на 1, чтобы увидел День 1 попап
                }
            }
        }
        
        // --- ПОКАЗ ПОПАПОВ (СТРИК ОТ 1 ДО 7) ---
        // ЖЕСТКОЕ РАЗДЕЛЕНИЕ: Смотрим ТОЛЬКО в Apphud, чтобы халявщики не воровали монеты!
        let hasRealPurchasedSubscription = SubscriptionManager.shared.hasRealPurchasedSubscription
        
        if currentStreak > 0, currentStreak <= 7 {
            if hasRealPurchasedSubscription {
                // ВЕТКА ДЛЯ РЕАЛЬНО ПЛАТЯЩИХ (Твоя новая фича с монетами)
                let coinsToGive = PremiumRewardPopupView.getCoins(for: currentStreak)
                CoinsService.shared.addCoins(coinsToGive)
                print("Начислено \(coinsToGive) монет для реального премиум юзера за день \(currentStreak)")
                
                let popup = PremiumRewardPopupView(currentDay: currentStreak)
                popup.alpha = 0
                view.addSubview(popup)
                
                popup.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                
                UIView.animate(withDuration: 0.4) {
                    popup.alpha = 1
                }
            } else {
                // ВЕТКА ДЛЯ БЕСПЛАТНЫХ ЮЗЕРОВ И ТЕХ, КТО НА ХАЛЯВНОМ ТРИАЛЕ
                // (Им показываем оригинальный попап, монеты НЕ ДАЕМ)
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
        }
        
        // --- ОРИГИНАЛЬНАЯ ЛОГИКА ОБРАБОТКИ ДНЕЙ ---
        if currentStreak == 7 {
            // Праздничный эффект срабатывает для всех
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1022) // Звук успеха
            
            // АКТИВАЦИЯ ХАЛЯВЫ: даем бесплатный премиум ТОЛЬКО если у юзера НЕТ реальной подписки
            if !hasRealPurchasedSubscription {
                UserDefaults.standard.set(true, forKey: isPremActiveKey)
                UserDefaults.standard.set(today, forKey: premActivationDateKey)
                print("Активирован бесплатный 3-дневный премиум для халявщика")
            }
            
        } else if currentStreak > 7 {
            
            // СБРОС ЦИКЛА ДЛЯ РЕАЛЬНОГО ПРЕМИУМА (Apphud)
            if hasRealPurchasedSubscription {
                // Если юзер реально купил подписку, нам насрать на даты халявы.
                // На 8-й день сбрасываем его стрик в 0, чтобы внизу метода он инкрементировался в 1 и пошел на новый круг за монетами.
                currentStreak = 0
                print("Реальный премиум юзер ушел на новый цикл получения монет.")
            }
            // СБРОС ЦИКЛА ДЛЯ ХАЛЯВЩИКОВ ПО ДАТЕ ИСТЕЧЕНИЯ (3 ДНЯ)
            else if let activationDate = UserDefaults.standard.object(forKey: premActivationDateKey) as? Date {
                let daysPassed = calendar.dateComponents([.day], from: activationDate, to: today).day ?? 0
                
                AmplitudeManager.shared.logEvent(name: "FreeMode daysPassed", properties: ["daysPassed":"\(daysPassed)"])
                
                if daysPassed >= 3 {
                    // Срок халявы вышел — жестко обнуляем стрик, выключаем бесплатный премиум и чистим дату
                    currentStreak = 0
                    UserDefaults.standard.set(false, forKey: isPremActiveKey)
                    UserDefaults.standard.removeObject(forKey: premActivationDateKey)
                    print("Premium халявный период окончен. Стрик сброшен, доступ закрыт.")
                }
            }
        }
        
        AmplitudeManager.shared.logEvent(name: "FreeMode currentStreak", properties: ["currentStreak":"\(currentStreak)"])
        
        // БЕЗУСЛОВНЫЙ ОРИГИНАЛЬНЫЙ ИНКРЕМЕНТ И СОХРАНЕНИЕ
        currentStreak += 1
        UserDefaults.standard.set(todayString, forKey: lastShowDateKey)
        UserDefaults.standard.set(currentStreak, forKey: streakCountKey)
        UserDefaults.standard.synchronize()
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
                        
            let selectedAssistant = AIGirlfriendsManager().getAllConfigs().first { $0.avatarImageName == avatarID }
            BaseManager.shared.currentAssistant = selectedAssistant
            BaseManager.shared.isFirstMessageInChat = true
            AmplitudeManager.shared.logEvent(name: "chat selected from stories", properties: ["index:":"\(avatarID)", "name:":"\(selectedAssistant?.assistantName ?? "")"])
            
            let aiChatViewController = AIGFChatViewController()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
            present(aiChatViewController, animated: false)
        }
    }

    private func showSubsIfNeeded() {
        if BaseManager.shared.needOpenPaywall {
            showSubs()
            BaseManager.shared.needOpenPaywall = false
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    private func showSubs() {
        let subsView = PaywallView(isOnboarding: true)
        subsView.vc = self
        
        subsView.onPaywallClosedHandler = { [weak self] in
            guard let self else { return }
            tabBarController?.tabBar.isHidden = false
        }
        
        AmplitudeManager.shared.logEvent(name: "showSubs from Onboarding", properties: ["":""])
        
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
        AmplitudeManager.shared.logEvent(name: "create new chat ButtonTapped", properties: ["":""])

        UserDefaults.standard.set(true, forKey: "hasAlreadyShownNewChatHighlight")

        let createGFVC = MyGFCreateCustomViewController()
        createGFVC.modalPresentationStyle = .fullScreen
        createGFVC.isModalInPresentation = true
//        createGFVC.completionHandler = { [weak self] in
//// todo что делаем когда создал?
//        }
        present(createGFVC, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ChatListVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel.shouldShowAdsBanner() ? 1 : 0
        } else {
            restoreChatList()
            return viewModel.chats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListCell.identifier, for: indexPath) as? ChatListCell else {
            return UITableViewCell()
        }
        
        // --- РЕКЛАМНАЯ ЯЧЕЙКА ---
        if indexPath.section == 0 {
            cell.configureForAd(
                title: "newChatName".localize(),
                message: "newChatMessage".localize(),
                avatarName: "addsBannerAvatar"
            )
            return cell
        }
        
        let chatIndexPath = IndexPath(row: indexPath.row, section: 0)
        let chat = viewModel.chat(at: chatIndexPath)
        cell.configure(with: chat)
        
        if UnreadMessageManager.shared.lasChatUnreadID == chat.id {
            cell.setUnread()
        }
        
        let didReceiveFirstMessage = UserDefaults.standard.bool(forKey: "didReceiveFirstMessage")
        
        if !didReceiveFirstMessage, chat.assistantAvatar == "mainAvatar1" {
            cell.setUnread()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Клик по рекламной ячейке
        if indexPath.section == 0 {
            print("Ad cell tapped! Handle redirect or deep link here.")

            let selectedAssistant: AIGirlfriendsConfig
            if let addsBannerAssistant = AIGirlfriendsManager().getAllConfigs().first(where: { $0.id == "addsBannerID" }) {
                selectedAssistant = addsBannerAssistant
            } else {
                let selectedAssistantID = "addsBannerID"
                selectedAssistant = AIGirlfriendsConfig(
                    id: selectedAssistantID,
                    assistantName: "newChatName".localize(),
                    assistantInfo: "",
                    avatarImageName: "addsBannerAvatar"
                )
                
                AIGirlfriendsManager().addConfig(selectedAssistant)
                AIGirlfriendMessagesManager().addMessage(
                    AIGFMessageModel(role: "assistant", content: "newChatMessage".localize()),
                    assistantId: selectedAssistantID
                )
            }
            BaseManager.shared.currentAssistant = selectedAssistant
            BaseManager.shared.isFirstMessageInChat = true
            AmplitudeManager.shared.logEvent(name: "addsBanner selected", properties: ["index:":"\(indexPath.row)", "name:":"Scarlett"])
            
            let aiChatViewController = AIGFChatViewController()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
            present(aiChatViewController, animated: false)
            
            return
        }
        
        // Корректный indexPath для viewModel (всегда section: 0 внутри модели)
        let chatIndexPath = IndexPath(row: indexPath.row, section: 0)
        let selectedChat = viewModel.chat(at: chatIndexPath)
        
        if UnreadMessageManager.shared.lasChatUnreadID == selectedChat.id {
            AmplitudeManager.shared.logEvent(name: "opened unread message", properties: ["":""])
            UnreadMessageManager.shared.lasChatUnreadID = nil
        }
        
        let didReceiveFirstMessage = UserDefaults.standard.bool(forKey: "didReceiveFirstMessage")
        
        if !didReceiveFirstMessage, selectedChat.assistantAvatar == "mainAvatar1" {
            UserDefaults.standard.set(true, forKey: "didReceiveFirstMessage")
        }
        
        let selectedAssistant = AIGirlfriendsManager().getAllConfigs().first(where: { $0.id == selectedChat.id })
        BaseManager.shared.currentAssistant = selectedAssistant
        BaseManager.shared.isFirstMessageInChat = true
        AmplitudeManager.shared.logEvent(name: "chat selected", properties: ["index:":"\(indexPath.row)", "name:":"\(selectedAssistant?.assistantName ?? "")"])
        
        let aiChatViewController = AIGFChatViewController()
        aiChatViewController.modalPresentationStyle = .fullScreen
        aiChatViewController.isModalInPresentation = true
        present(aiChatViewController, animated: false)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.isNeedBigTextForIPad() ? 130 : 80
    }
    
    // MARK: - SWIPE TO DELETE
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Запрещаем свайпать рекламную ячейку
        if indexPath.section == 0 { return nil }
        
        let chatIndexPath = IndexPath(row: indexPath.row, section: 0)
        
        let deleteAction = UIContextualAction(style: .destructive, title: "ClearChatHistory".localize()) { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let assistantsService = AIGirlfriendsManager()
            let selectedAssistant = assistantsService.getAllConfigs().first(where: { $0.id == self.viewModel.chat(at: chatIndexPath).id })
            AIGirlfriendMessagesManager().getAllMessages(forAssistantId: selectedAssistant?.id ?? "").forEach {
                AIGirlfriendMessagesManager().deleteMessage(id: $0.id ?? "")
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
        deleteAction.backgroundColor = MyColors.accentRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    
    private func restoreChatList() {
        allChatsView.tableView.backgroundView = nil
        allChatsView.tableView.separatorStyle = .none
    }
    
    private func showToastNotification(message: String) {
        // 1. Создаем контейнер для тоста в Telegram-стиле
        let toastContainer = UIView()
        toastContainer.backgroundColor = MyColors.messageBackground
        toastContainer.layer.cornerRadius = 16
        toastContainer.layer.borderWidth = 1
        toastContainer.layer.borderColor = MyColors.separator.cgColor
        toastContainer.alpha = 0
        
        // Легкая тень, чтобы выделялся над ячейками
        toastContainer.layer.shadowColor = MyColors.background.cgColor
        toastContainer.layer.shadowOpacity = 0.4
        toastContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        toastContainer.layer.shadowRadius = 6
        
        // 2. Иконка галочки (или инфо)
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
        iconImageView.tintColor = MyColors.primary
        iconImageView.contentMode = .scaleAspectFit
        
        // 3. Текст
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = MyColors.textPrimary
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
