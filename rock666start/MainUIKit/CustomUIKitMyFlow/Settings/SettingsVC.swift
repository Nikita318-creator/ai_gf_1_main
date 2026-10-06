import UIKit
import RealmSwift
import SnapKit
import StoreKit

final class SettingsVC: UIViewController {

    // MARK: - Enums
    
    private enum SettingsSection: Int, CaseIterable {
        case general
        case data
    }
    
    private enum GeneralRow: Int, CaseIterable {
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
    
    private enum DataRow: Int, CaseIterable {
        case clearAllData
        
        var title: String {
            switch self {
            case .clearAllData: return "Clear All My Data"
            }
        }
        
        var iconName: String {
            switch self {
            case .clearAllData: return "trash.fill"
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
    
    private func showClearDataAlert() {
        let alert = UIAlertController(
            title: "Clear All My Data",
            message: "All your data in this app, including chat history, will be permanently erased. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let deleteAction = UIAlertAction(title: "Clear Data", style: .destructive) { [weak self] _ in
            self?.performClearData()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true)
    }
    
    private func performClearData() {
        let config = CharactersSchemaMigrationFactory.buildConfiguration()
        do {
            let realm = try Realm(configuration: config)
            try realm.write {
                realm.deleteAll()
            }
            print("Realm database successfully cleared")
        } catch {
            print("Failed to clear Realm database: \(error)")
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = SettingsSection(rawValue: section) else { return 0 }
        switch settingsSection {
        case .general:
            return GeneralRow.allCases.count
        case .data:
            return DataRow.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        guard let section = SettingsSection(rawValue: indexPath.section) else { return cell }
        
        var config = cell.defaultContentConfiguration()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        
        switch section {
        case .general:
            guard let row = GeneralRow(rawValue: indexPath.row) else { return cell }
            config.text = row.title
            config.textProperties.color = BasePalitColors.textPrimary
            config.image = UIImage(systemName: row.iconName, withConfiguration: symbolConfig)
            config.imageProperties.tintColor = BasePalitColors.primary
            cell.accessoryType = .disclosureIndicator
            
        case .data:
            guard let row = DataRow(rawValue: indexPath.row) else { return cell }
            config.text = row.title
            config.textProperties.color = .systemRed
            config.image = UIImage(systemName: row.iconName, withConfiguration: symbolConfig)
            config.imageProperties.tintColor = .systemRed
            cell.accessoryType = .none
        }
        
        config.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
        cell.contentConfiguration = config
        cell.backgroundColor = BasePalitColors.cardBackground
        
        let selectedView = UIView()
        selectedView.backgroundColor = BasePalitColors.selectedOption
        cell.selectedBackgroundView = selectedView
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = SettingsSection(rawValue: indexPath.section) else { return }
        
        switch section {
        case .general:
            guard let row = GeneralRow(rawValue: indexPath.row) else { return }
            switch row {
            case .privacyPolicy:
                openURL(urlString: PaywallView.Constants.privacyPolicyMainUrl)
            case .termsOfUse:
                openURL(urlString: PaywallView.Constants.termsMainUrl)
            case .rateUs:
                requestAppReview()
            }
        case .data:
            guard let row = DataRow(rawValue: indexPath.row) else { return }
            switch row {
            case .clearAllData:
                showClearDataAlert()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}
