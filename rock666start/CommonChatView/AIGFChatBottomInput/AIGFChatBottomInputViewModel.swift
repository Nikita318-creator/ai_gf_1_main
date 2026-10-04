import UIKit

// MARK: - 1. ViewModel
class AIGFChatBottomInputViewModel: NSObject {
    // Хэндлеры проксируются из View
    var sendMessageHandler: ((String) -> Void)?
    var showInternetErrorAlertHandler: (() -> Void)?
    var giftSendedHandler: ((GirlfriendGiftModel) -> Void)?
    var pleaseWaitHandler: (() -> Void)?
    var needPremiumForAudioHandler: (() -> Void)?
    var textDidChangedHandler: (() -> Void)?

    weak var vc: UIViewController?
    var isHandlingImage = false
    var canSendMessage = true

    func sendText(_ text: String, onSuccess: @escaping () -> Void) {
        guard canSendMessage, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            pleaseWaitHandler?()
            return
        }
        
        guard NetworkMonitorManager.shared.isConnected else {
            showInternetErrorAlertHandler?()
            return
        }
        
        canSendMessage = false
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        sendMessageHandler?(text.trimmingCharacters(in: .whitespacesAndNewlines))
        onSuccess()
    }
    
    func openGiftController() {
        let giftVC = GirlfriendGiftsViewController()
        giftVC.sendGiftHandler = { [weak self] gift in
            self?.giftSendedHandler?(gift)
            giftVC.dismiss(animated: true)
        }
        vc?.present(giftVC, animated: true, completion: nil)
    }
}
