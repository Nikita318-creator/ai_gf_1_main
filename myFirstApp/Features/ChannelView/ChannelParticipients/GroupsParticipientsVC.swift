import UIKit
import SnapKit

class GroupsParticipientsVC: UIViewController {
    
    private let members: [ChannelModel]
    private let tableView = UITableView()
    
    init(members: [ChannelModel]) {
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
        view.backgroundColor = MyColors.background
        
        let headerLabel = UILabel()
        headerLabel.text = "ui_members_label".localize()
        headerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerLabel.textColor = MyColors.textPrimary
        headerLabel.textAlignment = .center
        view.addSubview(headerLabel)
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview()
        }
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor(white: 0.2, alpha: 0.5)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 68, bottom: 0, right: 0) // Отступ сепаратора под ТГ
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60 // Чуть просторнее для касания
        tableView.register(GroupsParticipientsCell.self, forCellReuseIdentifier: "MemberCell")
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

// MARK: - UITableView Overrides
extension GroupsParticipientsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath) as? GroupsParticipientsCell else {
            return UITableViewCell()
        }
        
        if indexPath.row == 0 {
            cell.configure(
                name: "you".localize(),
                avatarName: nil,
                status: "ui_online_status".localize(),
                isUser: true
            )
        } else {
            let waifu = members[indexPath.row - 1]
            cell.configure(
                name: waifu.name,
                avatarName: waifu.avatarName,
                status: "ui_online_status".localize(),
                isUser: false
            )
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRowAt(indexPath, animated: true)
    }
}
