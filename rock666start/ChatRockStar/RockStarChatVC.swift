import UIKit
import SnapKit
import Foundation

class RockStarChatVC: UIViewController {
    
    private let rockStarChat = RockStarChat()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(rockStarChat)
        rockStarChat.vc = self
        rockStarChat.setup()
        rockStarChat.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        rockStarChat.fetchMessageHistory()
        rockStarChat.setNavView()
        
        if !NetworkMonitorManager.shared.isConnected {
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
}
