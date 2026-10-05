
import UIKit
import SnapKit

class AIGFChatViewController: UIViewController {
    
    private let chatView = AIGFChatView()
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        chatView.updateForRLTIfNeeded()
    }
    
    func showInternetErrorAlert() {
        let alertController = UIAlertController(
            title: "No Internet Connection",
            message: "Please check your network settings and try again.",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}
