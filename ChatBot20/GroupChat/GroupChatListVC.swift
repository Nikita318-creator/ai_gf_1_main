//
//  GroupChatListVC.swift
//  ChatBot20
//
//  Created by Mikita on 05/06/2026.
//

import UIKit
import SnapKit

class GroupChatListVC: UIViewController {
    private enum RowType {
        case customHeader
        case emptyState
        case chat(index: Int)
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let viewModel = GroupChatListViewModel()
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
        // Прячем стандартный системный бар для кастомного заголовка
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
        tableView.separatorStyle = .none // Используем наш кастомный сепаратор из ячейки
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(GroupChatListItemCell.self, forCellReuseIdentifier: GroupChatListItemCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HeaderCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EmptyCell")
        
        tableView.contentInsetAdjustmentBehavior = .never
        // Сделали верхний инсет аккуратнее, так как ячейки теперь плотные
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 100, right: 0)
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
        
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "bubble.left.and.bubble.right.fill")
        iconView.tintColor = .gray
        iconView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "NoMessagesYet".localize() // Локализация остается твоя
        label.textColor = .gray
        label.font = .systemFont(ofSize: view.isCurrentDeviceiPad() ? 26 : 16, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        
        container.addSubview(iconView)
        container.addSubview(label)
        
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(50)
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalToSuperview()
        }
        
        return container
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension GroupChatListVC: UITableViewDataSource, UITableViewDelegate {
    
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
                label.text = "Groups".localize() // Изменил заголовок на Группы
                label.font = .systemFont(ofSize: 34, weight: .bold)
                label.textColor = .white
                cell.contentView.addSubview(label)
                label.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(16)
                    make.bottom.equalToSuperview().offset(-10)
                }
            }
            return cell
            
        case .chat(let index):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatListItemCell.identifier, for: indexPath) as? GroupChatListItemCell else { return UITableViewCell() }
            let chat = viewModel.chats[index]
            cell.configure(with: chat)
//            cell.setUnread(chat.isUnread)
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
            let topPadding = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
            return 50 + topPadding
        case .chat:
            return view.isCurrentDeviceiPad() ? 150 : 100
        case .emptyState:
            return 250
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRowAt(indexPath, animated: true)
        
        let groups = MainHelper.shared.allWaifuGroups

        if indexPath.row - 1 < groups.count {
            MainHelper.shared.currentWaifuNameFromeGroupeChat = groups[indexPath.row - 1].randomElement()
            MainHelper.shared.currentWaifuIndex = indexPath.row - 1
        }

        if case .chat(let index) = rows[indexPath.row] {
            var chat = viewModel.chats[index]
            
            // Если чат был непрочитан — сбрасываем локально флаг
//            if chat.isUnread {
//                chat.isUnread = false
//                // Дополнительная логика сброса unread-флага в твоем сервисе, если нужно
//            }
            
            // Вытаскиваем конфигурацию группового ассистента/комнаты из Realm по новому id
            let selectedAssistant = viewModel.assistantsService.getAllConfigs().first { $0.id == chat.id }
            MainHelper.shared.currentAssistant = selectedAssistant
            MainHelper.shared.isFirstMessageInChat = false
            
            AnalyticService.shared.logEvent(name: "GROUP chat selected", properties: [
                "index:": "\(index)",
                "name:": "\(selectedAssistant?.assistantName ?? "")"
            ])
            
            // Запуск твоего нового экрана группового чата
            let groupChatVC = GroupChatVC()
            groupChatVC.modalPresentationStyle = .fullScreen
            groupChatVC.isModalInPresentation = true
            present(groupChatVC, animated: true)
        }
    }
}
