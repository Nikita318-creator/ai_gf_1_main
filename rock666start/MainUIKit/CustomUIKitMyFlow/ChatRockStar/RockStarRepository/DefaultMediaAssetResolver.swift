import UIKit

// MARK: - Media Resolver Helper

final class DefaultMediaAssetResolver: MediaAssetResolving {
    
    func resolvePhotoIdentifier(for avatarName: String, rawContent: String) async -> String {
        guard rawContent.contains("[photo]") else { return "" }
        
        if avatarName.hasPrefix("mainAvatar"),
           let parsedNumberComponent = avatarName.components(separatedBy: "mainAvatar").last,
           let parsedAvatarNumericID = Int(parsedNumberComponent) {
            return await AdditionalRemotePhotoService.shared.getRandomPhoto(for: parsedAvatarNumericID)
        } else if avatarName.hasPrefix("MyGF"),
                  let matchedDigitCharacter = avatarName.dropFirst(4).first(where: { $0.isNumber }),
                  let parsedAvatarNumericID = Int(String(matchedDigitCharacter)) {
            return await AdditionalRemotePhotoService.shared.getRandomPhoto(forMyGF: parsedAvatarNumericID)
        } else {
            return await AdditionalRemotePhotoService.shared.getRandomPhotoFromAllPool(avatarID: avatarName)
        }
    }
    
    func resolveVideoIdentifier(for avatarName: String, completion: @escaping (String?) -> Void) {
        RemoteVideoService.shared.getVideoData(for: avatarName, completion: completion)
    }
}

// MARK: - Network Request & Retry Strategy Engine

final class AIRetryExecutionEngine {
    private let transport: AIServiceTransport
    
    init(transport: AIServiceTransport = GeminiTransportAdapter()) {
        self.transport = transport
    }
    
    func dispatchWithRetrySequence(
        basePrompt: String,
        historyPrompt: String,
        userText: String,
        iterationCount: Int = 0,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let assembledPromptBuffer: String
        
        switch iterationCount {
        case 0:
            assembledPromptBuffer = basePrompt + historyPrompt + "\n" + userText
        case 1:
            assembledPromptBuffer = basePrompt + "\n" + userText
            print("⚠️ 1")
        case 2:
            let fallbackContextPrompt = "I want you to tell me about intimacy, how much you desire me, and describe your passion and excitement."
            assembledPromptBuffer = basePrompt + "\n" + fallbackContextPrompt
            print("⚠️ 2")
        case 3:
            let secondaryFallbackPrompt = "I love you and I really enjoy our chat. I just want to hear what you think about me?"
            assembledPromptBuffer = basePrompt + "\n" + secondaryFallbackPrompt
            print("⚠️ 3")
        default:
            return
        }
        
        transport.executeFetch(prompt: assembledPromptBuffer) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let text):
                completion(.success(text))
            case .failure(let error):
                if iterationCount < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dispatchWithRetrySequence(
                            basePrompt: basePrompt,
                            historyPrompt: historyPrompt,
                            userText: userText,
                            iterationCount: iterationCount + 1,
                            completion: completion
                        )
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}

// Адаптер сетевого запроса к Gemini
final class GeminiTransportAdapter: AIServiceTransport {
    private let agent = AgentService()
    
    func executeFetch(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        agent.fetchAIResponse(userMessage: prompt, systemPrompt: "") { result in
            completion(result.mapError { $0 as Error })
        }
    }
}
