import UIKit

extension UIView {
    func isCurrentDeviceiPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
