import UIKit
import SnapKit

class ChannelChatViewController: UIViewController {
    
    override func loadView() {
        super.loadView()
        let groupsView = ChannelChatView()
        groupsView.vc = self
        view = groupsView
        groupsView.setup()
    }
}
