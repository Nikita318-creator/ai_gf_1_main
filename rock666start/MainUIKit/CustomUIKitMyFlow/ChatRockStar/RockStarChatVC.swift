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
    }
}
