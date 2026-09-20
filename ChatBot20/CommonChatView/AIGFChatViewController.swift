
import UIKit
import SnapKit

class AIGFChatViewController: UIViewController {
    
    private let chatView = AIGFChatView()
    private var needGetMainHistoryFact = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(chatView)
        chatView.vc = self
        chatView.setup()
        chatView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        chatView.setMessagesFromDB()
        chatView.setupNavTitleAndAvatar()
        
        if !NetworkMonitorManager.shared.isConnected {
            showInternetErrorAlert()
        }
        
        if needGetMainHistoryFact {
            chatView.getMainHistoryFact()
            needGetMainHistoryFact = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        chatView.updateForRLTIfNeeded()
    }
    
    func showInternetErrorAlert() {
        let alertController = UIAlertController(
            title: "InternetError.title".localize(),
            message: "InternetError.message".localize(),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK".localize(), style: .default)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}
