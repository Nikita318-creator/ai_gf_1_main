import UIKit

extension String {
    func localize() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localize(attribut: String, arguments: CVarArg...) -> String {
        let localizedString = NSLocalizedString(attribut, comment: "")
        return String(format: localizedString, arguments: arguments)
    }
}
