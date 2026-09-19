import UIKit
import SnapKit

class GroupChatVC: UIViewController {
    
    override func loadView() {
        super.loadView()
        let groupsView = GroupChatView()
        groupsView.vc = self
        view = groupsView
        groupsView.setup()
    }
}
