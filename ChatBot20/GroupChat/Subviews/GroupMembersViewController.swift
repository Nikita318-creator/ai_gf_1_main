//
//  GroupMembersViewController.swift
//  ChatBot20
//
//  Created by Mikita on 09/06/2026.
//

import UIKit
import SnapKit

class GroupMembersViewController: UIViewController {
    
    private let members: [GroupChatModel]
    private let tableView = UITableView()
    
    struct Colors {
        static let background = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)    // #1C1C1E
        static let cellBackground = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0) // #2C2C2E
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.64, green: 0.64, blue: 0.66, alpha: 1.0)
        static let accent = UIColor(red: 0.20, green: 0.63, blue: 0.86, alpha: 1.0)       // #3390DC
    }
    
    init(members: [GroupChatModel]) {
        self.members = members
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = Colors.background
        
        // Заголовок шторки
        let headerLabel = UILabel()
        headerLabel.text = "Members".localize() // или "Members (\(members.count + 1))"
        headerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerLabel.textColor = Colors.textPrimary
        headerLabel.textAlignment = .center
        view.addSubview(headerLabel)
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview()
        }
        
        // Настройка таблицы
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(white: 0.2, alpha: 0.5)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 56
        tableView.register(MemberCell.self, forCellReuseIdentifier: "MemberCell")
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - UITableView Overrides
extension GroupMembersViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count + 1 // +1 для аккаунта "You"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as? MemberCell else {
            return UITableViewCell()
        }
        
        if indexPath.row == 0 {
            // Первая ячейка — текущий пользователь
            cell.configure(
                name: "you".localize(),
                avatarName: nil, // Передаем nil для дефолтного плейсхолдера
                status: "online".localize(),
                isUser: true
            )
        } else {
            // Вытаскиваем девчонок (смещаем индекс на -1 из-за "You")
            let waifu = members[indexPath.row - 1]
            cell.configure(
                name: waifu.name,
                avatarName: waifu.avatarName,
                status: "online".localize(),
                isUser: false
            )
        }
        
        return cell
    }
}
