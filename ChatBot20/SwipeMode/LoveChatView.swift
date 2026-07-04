import UIKit
import SnapKit

class LoveChatView: AIChatView {
    var breakUpHandler: (() -> Void)?
    
    func setupLoveChatView() {
        AnalyticService.shared.logEvent(name: "setupLoveChatView", properties: ["":""])

        plusButton.setImage(nil, for: .normal)
        plusButton.setTitle("  " + "BreakUp".localize() + "  ", for: .normal)
        
        plusButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        inputTextView.promptsStackView.subviews.forEach { [weak self] in
            guard let self else { return }
            if $0.tag != 19 {
                inputTextView.promptsStackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }
        
        inputTextView.galleryButton.isHidden = true
        inputTextView.remakeConstraintsForloveChat()
        
        setLevelOfConnection()

        /// === ipad adjust ===
        
        guard isCurrentDeviceiPad() else { return }
        plusButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(60)
        }
    }
    
    override func plusButtonTapped() {
        breakUpHandler?()
    }
    
    override func scrollToBottomAnimated(isAnimated: Bool = true) {
        super.scrollToBottomAnimated(isAnimated: isAnimated)
        setLevelOfConnection()
    }
    
    func setLevelOfConnection() {
        let messagesCount = MessageHistoryService().getAllMessages(forAssistantId: MainHelper.shared.currentAssistant?.id ?? "").count

        let hartsCount: Int
        switch messagesCount {
        case 0..<5:
            print("Number of messages: \(messagesCount). >0.")
            hartsCount = 1
            
        case 5..<10:
            print("Number of messages: \(messagesCount). >5.")
            hartsCount = 2

        case 10..<20:
            print("Number of messages: \(messagesCount). >10.")
            hartsCount = 3

        case 20..<30:
            print("Number of messages: \(messagesCount). >20.")
            hartsCount = 4

        case 30..<40:
            print("Number of messages: \(messagesCount). >30.")
            hartsCount = 5

        case 40..<50:
            print("Number of messages: \(messagesCount). >40.")
            hartsCount = 6

        case 50..<Int.max:
            print("Number of messages: \(messagesCount). >50.")
            hartsCount = 7

        default:
            print("Unexpected number of messages: \(messagesCount)")
            hartsCount = 0

        }
        
        let giftCount = CoinsService.shared.getSentGifts(for: MainHelper.shared.loveAssistantId).count
        
        inputTextView.setHartsForLoveChat(count: hartsCount + min(giftCount, 3))
    }
}
