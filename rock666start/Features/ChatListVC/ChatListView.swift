import UIKit
import SnapKit

class ChatListView: UIView {
    let tableView = UITableView()
    private let listSeparatorView = UIView()
    private let gradientLayer = CAGradientLayer()

    private var needScrollTotTheEnd: Bool = true
    
    var goToChatHandler: ((String) -> Void)?
    var storyOpenedHandler: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        setupBackground()
        setupTableView()
        setupConstraints()

        iPadCheck()
    }
    
    private func setupBackground() {
        backgroundColor = BasePalitColors.background

        gradientLayer.colors = [
            BasePalitColors.background.cgColor,
            BasePalitColors.gradientEnd.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 70, right: 0)
        listSeparatorView.backgroundColor = BasePalitColors.separator.withAlphaComponent(0.6)
        addSubview(listSeparatorView)
        tableView.register(ChatListCell.self, forCellReuseIdentifier: ChatListCell.identifier)
        addSubview(tableView)
    }

    private func setupConstraints() {
        listSeparatorView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(listSeparatorView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

extension ChatListView {
    func iPadCheck() {
        guard isIPad() else { return }
    }
}
