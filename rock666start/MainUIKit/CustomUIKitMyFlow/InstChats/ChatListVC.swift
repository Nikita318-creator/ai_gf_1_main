import UIKit
import SnapKit

class InstChatListViewController: UIViewController {
    private let primaryContainerView = ChatListView()
    private let listDataViewModel = ChatListVM()

    override func loadView() {
        view = primaryContainerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Chats"
        
        configureTableDisplay()
        configureViewModelObservers()
        configureUserInteractions()
        evaluateSubscriptionState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        listDataViewModel.loadChats()
        
        primaryContainerView.storyOpenedHandler = { [weak self] isElementVisible in
            self?.tabBarController?.tabBar.isHidden = !isElementVisible
        }
    }
    
    private func configureTableDisplay() {
        primaryContainerView.tableView.delegate = self
        primaryContainerView.tableView.dataSource = self
    }

    private func configureViewModelObservers() {
        listDataViewModel.onChatsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.primaryContainerView.tableView.reloadData()
            }
        }
        listDataViewModel.loadChats()
    }

    private func configureUserInteractions() {
        primaryContainerView.goToChatHandler = { [weak self] targetAvatarIdentifier in
            guard let self else { return }
                                    
            let targetAssistantConfiguration = AIGirlfriendsManager().getAllConfigs().first { $0.avatarImageName == targetAvatarIdentifier }
            MyGovnoSingltone.shared.selectedAICompanion = targetAssistantConfiguration
            MyGovnoSingltone.shared.currentMessageFirst = true
            
            let targetChatFlowController = AIGFChatViewController()
            targetChatFlowController.modalPresentationStyle = .fullScreen
            targetChatFlowController.isModalInPresentation = true
            present(targetChatFlowController, animated: false)
        }
    }

    private func evaluateSubscriptionState() {
        if MyGovnoSingltone.shared.isExpectedPaywall {
            displayPaywallController()
            MyGovnoSingltone.shared.isExpectedPaywall = false
        } else {
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    private func displayPaywallController() {
        let subscriptionOverlayView = PaywallView()
        subscriptionOverlayView.vc = self
        
        subscriptionOverlayView.onPaywallClosedHandler = { [weak self] in
            guard let self else { return }
            tabBarController?.tabBar.isHidden = false
        }
                
        view.addSubview(subscriptionOverlayView)

        subscriptionOverlayView.snp.remakeConstraints { layoutMaker in
            layoutMaker.edges.equalToSuperview()
        }
    }
}

extension InstChatListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        refreshTableBackgroundState()
        return listDataViewModel.chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let customCellInstance = tableView.dequeueReusableCell(withIdentifier: InstChatCell.identifier, for: indexPath) as? InstChatCell else {
            return UITableViewCell()
        }
        
        let calculatedIndexPath = IndexPath(row: indexPath.row, section: 0)
        let chatModelObject = listDataViewModel.chat(at: calculatedIndexPath)
        customCellInstance.configure(with: chatModelObject)

        return customCellInstance
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let targetIndexPath = IndexPath(row: indexPath.row, section: 0)
        let activeChatEntity = listDataViewModel.chat(at: targetIndexPath)
        let currentAssistantConfig = AIGirlfriendsManager().getAllConfigs().first(where: { $0.id == activeChatEntity.id })
        MyGovnoSingltone.shared.selectedAICompanion = currentAssistantConfig
        MyGovnoSingltone.shared.currentMessageFirst = true
        
        let activeChatNavigationController = AIGFChatViewController()
        activeChatNavigationController.modalPresentationStyle = .fullScreen
        activeChatNavigationController.isModalInPresentation = true
        present(activeChatNavigationController, animated: false)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.isIPad() ? 130 : 80
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let currentSwipeIndexPath = IndexPath(row: indexPath.row, section: 0)
        
        let primaryDeleteAction = UIContextualAction(style: .destructive, title: "Clear") { [weak self] (actionContext, sourceView, completionDelegate) in
            guard let self = self else {
                completionDelegate(false)
                return
            }
            
            let localAssistantManager = AIGirlfriendsManager()
            let matchedAssistantConfig = localAssistantManager.getAllConfigs().first(where: { $0.id == self.listDataViewModel.chat(at: currentSwipeIndexPath).id })
            AIGirlfriendMessagesManager().getAllMessages(forAssistantId: matchedAssistantConfig?.id ?? "").forEach {
                AIGirlfriendMessagesManager().deleteMessage(id: $0.id ?? "")
            }
            
            localAssistantManager.getAllConfigs().reversed().forEach { itemConfig in
                if itemConfig.id != matchedAssistantConfig?.id {
                    localAssistantManager.updateConfig(id: itemConfig.id ?? "", config: itemConfig)
                }
            }

            let hapticFeedbackEngine = UIImpactFeedbackGenerator(style: .medium)
            hapticFeedbackEngine.impactOccurred()
            
            listDataViewModel.loadChats()
            tableView.reloadData()
            completionDelegate(true)
            self.displayStatusAlert(textMessage: "Chat history cleared")
        }
        
        primaryDeleteAction.image = UIImage(systemName: "trash")
        primaryDeleteAction.backgroundColor = BasePalitColors.accentRed
        
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [primaryDeleteAction])
        swipeConfiguration.performsFirstActionWithFullSwipe = true
        
        return swipeConfiguration
    }

    private func refreshTableBackgroundState() {
        if listDataViewModel.chats.isEmpty {
            constructEmptyStateLayout()
        } else {
            primaryContainerView.tableView.backgroundView = nil
        }
    }

    private func constructEmptyStateLayout() {
        let baseEmptyWrapperView = UIView()
        
        let primaryIconImageView = UIImageView()
        primaryIconImageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
        primaryIconImageView.tintColor = BasePalitColors.textSecondary.withAlphaComponent(0.5)
        primaryIconImageView.contentMode = .scaleAspectFit
        
        let mainTitleTextLabel = UILabel()
        mainTitleTextLabel.text = "No Conversations Yet"
        mainTitleTextLabel.textColor = BasePalitColors.textPrimary
        mainTitleTextLabel.font = .systemFont(ofSize: view.isIPad() ? 24 : 18, weight: .bold)
        mainTitleTextLabel.textAlignment = .center
        
        let descriptionTextLabel = UILabel()
        descriptionTextLabel.text = "You haven't chatted with anyone yet.\nAll your active chats will appear here."
        descriptionTextLabel.textColor = BasePalitColors.textSecondary
        descriptionTextLabel.font = .systemFont(ofSize: view.isIPad() ? 18 : 14, weight: .regular)
        descriptionTextLabel.textAlignment = .center
        descriptionTextLabel.numberOfLines = 0
        
        let contentArrangedStackView = UIStackView(arrangedSubviews: [primaryIconImageView, mainTitleTextLabel, descriptionTextLabel])
        contentArrangedStackView.axis = .vertical
        contentArrangedStackView.spacing = 12
        contentArrangedStackView.alignment = .center
        
        baseEmptyWrapperView.addSubview(contentArrangedStackView)
        
        let calculatedIconDimension: CGFloat = view.isIPad() ? 80 : 56
        primaryIconImageView.snp.makeConstraints { constraintMaker in
            constraintMaker.size.equalTo(CGSize(width: calculatedIconDimension, height: calculatedIconDimension))
        }
        
        contentArrangedStackView.snp.makeConstraints { constraintMaker in
            constraintMaker.centerY.equalToSuperview().offset(-40)
            constraintMaker.leading.trailing.equalToSuperview().inset(32)
        }
        
        primaryContainerView.tableView.backgroundView = baseEmptyWrapperView
    }
    
    private func displayStatusAlert(textMessage: String) {
        let notificationBannerView = UIView()
        notificationBannerView.backgroundColor = BasePalitColors.messageBackground
        notificationBannerView.layer.cornerRadius = 16
        notificationBannerView.layer.borderWidth = 1
        notificationBannerView.layer.borderColor = BasePalitColors.separator.cgColor
        notificationBannerView.alpha = 0
        
        notificationBannerView.layer.shadowColor = BasePalitColors.background.cgColor
        notificationBannerView.layer.shadowOpacity = 0.4
        notificationBannerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        notificationBannerView.layer.shadowRadius = 6
        
        let statusSymbolImageView = UIImageView()
        statusSymbolImageView.image = UIImage(systemName: "checkmark.circle.fill")
        statusSymbolImageView.tintColor = BasePalitColors.primary
        statusSymbolImageView.contentMode = .scaleAspectFit
        
        let detailTitleLabel = UILabel()
        detailTitleLabel.text = textMessage
        detailTitleLabel.textColor = BasePalitColors.textPrimary
        detailTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        detailTitleLabel.numberOfLines = 0
        
        notificationBannerView.addSubview(statusSymbolImageView)
        notificationBannerView.addSubview(detailTitleLabel)
        view.addSubview(notificationBannerView)
        
        statusSymbolImageView.snp.makeConstraints { constraintMaker in
            constraintMaker.leading.equalToSuperview().offset(16)
            constraintMaker.centerY.equalToSuperview()
            constraintMaker.size.equalTo(22)
        }
        
        detailTitleLabel.snp.makeConstraints { constraintMaker in
            constraintMaker.leading.equalTo(statusSymbolImageView.snp.trailing).offset(12)
            constraintMaker.trailing.equalToSuperview().offset(-16)
            constraintMaker.centerY.equalToSuperview()
        }
        
        notificationBannerView.snp.makeConstraints { constraintMaker in
            constraintMaker.centerX.equalToSuperview()
            constraintMaker.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(20)
            constraintMaker.height.equalTo(50)
            constraintMaker.width.greaterThanOrEqualTo(200)
            constraintMaker.width.lessThanOrEqualTo(view.snp.width).offset(-40)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            notificationBannerView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseIn, animations: {
                notificationBannerView.alpha = 0
            }) { _ in
                notificationBannerView.removeFromSuperview()
            }
        }
    }
}
