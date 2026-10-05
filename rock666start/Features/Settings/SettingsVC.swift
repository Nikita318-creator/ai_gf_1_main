import UIKit
import SnapKit
import StoreKit

final class SettingsVC: UIViewController {

    // MARK: - Enums
    
    private enum SettingsRow: Int, CaseIterable {
        case privacyPolicy
        case termsOfUse
        case rateUs
        
        var title: String {
            switch self {
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfUse: return "Terms of Use"
            case .rateUs: return "Rate Us"
            }
        }
        
        var iconName: String {
            switch self {
            case .privacyPolicy: return "hand.raised.fill"
            case .termsOfUse: return "doc.text.fill"
            case .rateUs: return "star.fill"
            }
        }
    }

    // MARK: - UI Elements
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = BasePalitColors.background
        table.separatorColor = BasePalitColors.separator
        table.showsVerticalScrollIndicator = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        table.delegate = self
        table.dataSource = self
        return table
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    // MARK: - Setup
    
    private func setupNavigationBar() {
        title = "More"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BasePalitColors.background
        appearance.titleTextAttributes = [.foregroundColor: BasePalitColors.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: BasePalitColors.textPrimary]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = BasePalitColors.primary
    }
    
    private func setupUI() {
        view.backgroundColor = BasePalitColors.background
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Logic Actions
    
    private func openURL(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func requestAppReview() {
        if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsRow.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        guard let row = SettingsRow(rawValue: indexPath.row) else { return cell }
        
        var config = cell.defaultContentConfiguration()
        config.text = row.title
        config.textProperties.color = BasePalitColors.textPrimary
        config.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        config.image = UIImage(systemName: row.iconName, withConfiguration: symbolConfig)
        config.imageProperties.tintColor = BasePalitColors.primary
        
        cell.contentConfiguration = config
        cell.backgroundColor = BasePalitColors.cardBackground
        cell.accessoryType = .disclosureIndicator
        
        let selectedView = UIView()
        selectedView.backgroundColor = BasePalitColors.selectedOption
        cell.selectedBackgroundView = selectedView
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let row = SettingsRow(rawValue: indexPath.row) else { return }
        
        switch row {
        case .privacyPolicy:
            openURL(urlString: PaywallView.Constants.privacyPolicyMainUrl)
        case .termsOfUse:
            openURL(urlString: PaywallView.Constants.termsMainUrl)
        case .rateUs:
            requestAppReview()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}
