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
        
        title = "My Chats"
        
        setupTableView()
        setupViewModel()
        setupActions()
        showSubsIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.loadChats()
        
        allChatsView.storyOpenedHandler = { [weak self] isVisible in
            self?.tabBarController?.tabBar.isHidden = !isVisible
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        allChatsView.updateForRLTIfNeeded()
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
        viewModel.loadChats()
    }

    private func setupActions() {
        allChatsView.goToChatHandler = { [weak self] avatarID in
            guard let self else { return }
            
            let currentAssistant = viewModel.chats.first { $0.assistantAvatar == avatarID }
                        
            let selectedAssistant = AIGirlfriendsManager().getAllConfigs().first { $0.avatarImageName == avatarID }
            MyGovnoSingltone.shared.currentAssistant = selectedAssistant
            MyGovnoSingltone.shared.isFirstMessageInChat = true
            
            let aiChatViewController = AIGFChatViewController()
            aiChatViewController.modalPresentationStyle = .fullScreen
            aiChatViewController.isModalInPresentation = true
            present(aiChatViewController, animated: false)
        }
    }

    private func showSubsIfNeeded() {
        if MyGovnoSingltone.shared.needOpenPaywall {
            showSubs()
            MyGovnoSingltone.shared.needOpenPaywall = false
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    private func showSubs() {
        let subsView = PaywallView()
        subsView.vc = self
        
        subsView.onPaywallClosedHandler = { [weak self] in
            guard let self else { return }
            tabBarController?.tabBar.isHidden = false
        }
                
        view.addSubview(subsView)

        subsView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ChatListVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        restoreChatList()
        return viewModel.chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatListCell.identifier, for: indexPath) as? ChatListCell else {
            return UITableViewCell()
        }
        
        let chatIndexPath = IndexPath(row: indexPath.row, section: 0)
        let chat = viewModel.chat(at: chatIndexPath)
        cell.configure(with: chat)

        // test111
//        let didReceiveFirstMessage = UserDefaults.standard.bool(forKey: "didReceiveFirstMessage")
//        if !didReceiveFirstMessage, chat.assistantAvatar == "mainAvatar1" {
//            cell.setUnread()
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatIndexPath = IndexPath(row: indexPath.row, section: 0)
        let selectedChat = viewModel.chat(at: chatIndexPath)
        
        // test111
//        let didReceiveFirstMessage = UserDefaults.standard.bool(forKey: "didReceiveFirstMessage")
//        if !didReceiveFirstMessage, selectedChat.assistantAvatar == "mainAvatar1" {
//            UserDefaults.standard.set(true, forKey: "didReceiveFirstMessage")
//        }
        
        let selectedAssistant = AIGirlfriendsManager().getAllConfigs().first(where: { $0.id == selectedChat.id })
        MyGovnoSingltone.shared.currentAssistant = selectedAssistant
        MyGovnoSingltone.shared.isFirstMessageInChat = true
        
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
        let chatIndexPath = IndexPath(row: indexPath.row, section: 0)
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Clear") { [weak self] (action, view, completionHandler) in
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
            self.showToastNotification(message: "Chat history cleared")
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
