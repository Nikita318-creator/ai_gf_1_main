import UIKit
import SnapKit

class SearchAIGFFeatureChatView: AIGFChatView {
    var breakUpHandler: (() -> Void)?
    
    func setupLoveChatView() {
        AmplitudeManager.shared.logEvent(name: "setupLoveChatView", properties: ["":""])

        plusButton.isHidden = true
        
        callButton.setImage(nil, for: .normal)
        callButton.setTitle("  " + "BreakUp".localize() + "  ", for: .normal)
        
        callButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
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
        callButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(60)
        }
        
        plusButton.snp.updateConstraints { make in
            make.width.height.equalTo(60)
        }
        
        plusButton.layer.cornerRadius = 30
        callButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .medium)
    }
    
    override func callButtonTapped() {
        breakUpHandler?()
    }
    
    override func scrollToBottomAnimated(isAnimated: Bool = true) {
        super.scrollToBottomAnimated(isAnimated: isAnimated)
        setLevelOfConnection()
    }
    
    func setLevelOfConnection() {
        let messagesCount = AIGirlfriendMessagesManager().getAllMessages(forAssistantId: BaseManager.shared.currentAssistant?.id ?? "").count

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
        
        let giftCount = CoinsService.shared.getSentGifts(for: BaseManager.shared.loveAssistantId).count
        
        inputTextView.setHartsForLoveChat(count: hartsCount + min(giftCount, 3))
    }
}
