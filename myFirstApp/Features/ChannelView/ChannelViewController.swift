import UIKit
import SnapKit

class ChannelViewController: UIViewController {
    private enum RowType {
        case customHeader
        case emptyState
        case chat(index: Int)
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let viewModel = ChannelViewModel()
    private var rows: [RowType] = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        setupViewModel()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupNavigationBar()
        setupTableView()
        viewModel.loadGroupChats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadGroupChats()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupBaseUI() {
        view.backgroundColor = MyColors.background
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(ChannelCell.self, forCellReuseIdentifier: ChannelCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptyCell")
        
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44, left: 0, bottom: 100, right: 0)
    }

    private func updateRows() {
        rows = [.customHeader]
        
        if viewModel.chats.isEmpty {
            rows.append(.emptyState)
        } else {
            for i in 0..<viewModel.chats.count {
                rows.append(.chat(index: i))
            }
        }
    }

    private func setupViewModel() {
        viewModel.onChatsUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateRows()
                self.tableView.reloadData()
            }
        }
    }
    
    private func createEmptyStateView() -> UIView {
        let container = UIView()
        
        let iconContainer = UIView()
        iconContainer.backgroundColor = MyColors.cardBackground
        iconContainer.layer.cornerRadius = view.isNeedBigTextForIPad() ? 50 : 35
        container.addSubview(iconContainer)
        
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "bubble.left.and.bubble.right.fill")
        iconView.tintColor = MyColors.textSecondary
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        
        let label = UILabel()
        label.text = "NoMessagesYet".localize()
        label.textColor = MyColors.textSecondary
        label.font = .systemFont(ofSize: view.isNeedBigTextForIPad() ? 22 : 16, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .center
        container.addSubview(label)
        
        iconContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.centerX.equalToSuperview()
            make.size.equalTo(view.isNeedBigTextForIPad() ? 100 : 70)
        }
        
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(view.isNeedBigTextForIPad() ? 50 : 34)
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        return container
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ChannelViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        switch row {
        case .customHeader:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            if cell.contentView.subviews.isEmpty {
                let label = UILabel()
                label.text = "Groups".localize()
                label.font = .systemFont(ofSize: view.isNeedBigTextForIPad() ? 40 : 34, weight: .bold)
                label.textColor = MyColors.textPrimary
                cell.contentView.addSubview(label)
                label.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.bottom.equalToSuperview().offset(-8)
                    make.top.equalToSuperview().offset(16)
                }
            }
            return cell
            
        case .chat(let index):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ChannelCell.identifier, for: indexPath) as? ChannelCell else { return UITableViewCell() }
            let chat = viewModel.chats[index]
            cell.configure(with: chat)
            return cell
            
        case .emptyState:
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            if cell.contentView.subviews.isEmpty {
                let emptyView = createEmptyStateView()
                cell.contentView.addSubview(emptyView)
                emptyView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        switch row {
        case .customHeader:
            return UITableView.automaticDimension
        case .chat:
            return view.isNeedBigTextForIPad() ? 100 : 76
        case .emptyState:
            return 300
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRowAt(indexPath, animated: true)
        
        let groups = BaseManager.shared.allWaifuGroups

        if indexPath.row - 1 < groups.count {
            BaseManager.shared.currentWaifuNameFromeGroupeChat = groups[indexPath.row - 1].randomElement()
            BaseManager.shared.currentWaifuIndex = indexPath.row - 1
        }

        if case .chat(let index) = rows[indexPath.row] {
            var chat = viewModel.chats[index]
            
            let selectedAssistant = viewModel.assistantsService.getAllConfigs().first { $0.id == chat.id }
            BaseManager.shared.currentAssistant = selectedAssistant
            BaseManager.shared.isFirstMessageInChat = false
            
            AmplitudeManager.shared.logEvent(name: "GROUP chat selected", properties: [
                "index:": "\(index)",
                "name:": "\(selectedAssistant?.assistantName ?? "")"
            ])
            
            let groupChatVC = ChannelChatViewController()
            groupChatVC.modalPresentationStyle = .fullScreen
            groupChatVC.isModalInPresentation = true
            present(groupChatVC, animated: true)
        }
    }
}
