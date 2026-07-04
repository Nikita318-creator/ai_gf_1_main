import UIKit
import SnapKit

class CreateGFFromTabBarVC: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MainHelper.shared.needOpenCreateNewAI = true
        tabBarController?.selectedIndex = 0
    }
}
