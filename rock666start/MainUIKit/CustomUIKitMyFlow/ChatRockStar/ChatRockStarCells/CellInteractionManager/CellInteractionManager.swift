import UIKit
import StoreKit

final class CellInteractionManager {
    static let shared = CellInteractionManager()
    private init() {}

    func resolveAvatarImage(isUser: Bool) -> UIImage? {
        guard !isUser else { return nil }
        
        guard let key = MyGovnoSingltone.shared.selectedAICompanion?.avatarImageName else { return nil }
        let hasTextData = !BackendService.shared.currentData.aiText.isEmpty
        let finalKey = hasTextData ? (key + "_") : key
        return UIImage(named: finalKey) ?? UIImage(named: key)
    }

    func applyReactionSelection(messageID: String, reaction: ChatMessageReaction, completion: @escaping () -> Void) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        CharactersChatUseCase().updateReaction(id: messageID, reaction: reaction.rawValue)
        completion()

        if reaction.isPositive {
            triggerReviewIfEligible()
        }
    }

    func deleteChatMessage(id: String, completion: @escaping () -> Void) {
        CharactersChatUseCase().deleteMessage(id: id)
        completion()
    }

    private func triggerReviewIfEligible() {
        guard RequestReviewManager.shared.needShowRateUsAfterTappedReactions() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let activeScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: activeScene)
            }
        }
    }
}
