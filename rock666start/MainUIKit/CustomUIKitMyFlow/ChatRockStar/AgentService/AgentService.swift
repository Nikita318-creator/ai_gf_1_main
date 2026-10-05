import Foundation

// MARK: - Адаптер 

final class AgentService {
    private let dispatcher = DataSyncTransportDispatcher()
    
    func fetchAIResponse(userMessage: String, systemPrompt: String, completion: @escaping (Result<String, NetworkTransferProtocolError>) -> Void) {
        dispatcher.dispatchPayloadTransaction(
            messageContent: userMessage,
            instructionContext: systemPrompt,
            completion: completion
        )
    }
}
