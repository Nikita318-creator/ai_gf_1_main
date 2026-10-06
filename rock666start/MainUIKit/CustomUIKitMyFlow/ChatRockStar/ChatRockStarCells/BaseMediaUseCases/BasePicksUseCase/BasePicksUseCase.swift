import Foundation
import UIKit

final class BasePicksUseCase {

    static let shared = BasePicksUseCase()
    
    private let trackingState = StateTrackerContainer<String, String>()
    private let poolEvaluator = CategoryPoolResolver { id in
        switch id {
        case 1...10:
            return [1: 123, 2: 123, 3: 115, 4: 95, 5: 123, 6: 35, 7: 115, 8: 58, 9: 38, 10: 115][id] ?? 15
        case 11...20: return 20
        case 21...25: return 15
        case 26:      return 32
        case 27:      return 123
        case 28:      return 115
        default:      return 15
        }
    }
    
    private let primaryEntityLimits: [Int: Int] = [1: 15, 2: 15, 3: 15, 4: 15]

    private init() {}

    func getRandomPhoto(for characterId: Int) async -> String {
        guard !BackendService.shared.currentData.aiText.isEmpty else {
            let fallbackName = generateFallbackAsset(characterId: characterId)
            return await downloadPhoto(by: fallbackName)
        }
        
        let pool = poolEvaluator.resolveSequence(for: characterId)
        return await dispatchRandomSelection(categoryKey: "\(characterId)", candidatePool: pool)
    }

    func downloadPhoto(by imageName: String) async -> String {
        guard !imageName.isEmpty else { return "" }
        
        if BasePicksManager.shared.isImageCached(by: imageName) {
            return imageName
        }
        
        let networkPath = BackendService.shared.currentData.mainString + BackendService.shared.currentData.picTail + "\(imageName).jpg"
        
        if let image = await performAsynchronousFetch(from: networkPath),
           let rawData = image.jpegData(compressionQuality: 0.8) {
            BasePicksManager.shared.saveImage(for: networkPath, with: imageName, data: rawData)
        }
        
        return imageName
    }

    private func generateFallbackAsset(characterId: Int) -> String {
        let index = (11...20).contains(characterId) ? Int.random(in: 41...60) : Int.random(in: 1...40)
        return "TestA_\(index)"
    }

    private func dispatchRandomSelection(categoryKey: String, candidatePool: [String]) async -> String {
        guard !candidatePool.isEmpty else { return "" }
        
        let history = trackingState.read(for: categoryKey)
        let unvisited = candidatePool.filter { !history.contains($0) }
        
        let chosen: String
        if let nextRandom = unvisited.randomElement() {
            chosen = nextRandom
            trackingState.register(value: chosen, for: categoryKey)
        } else {
            chosen = candidatePool.randomElement() ?? ""
        }
        
        return await downloadPhoto(by: chosen)
    }

    private func performAsynchronousFetch(from urlString: String, attemptFlag: Bool = false) async -> UIImage? {
        guard let targetURL = URL(string: urlString) else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: targetURL)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw NSError(domain: "HTTPError", code: httpResponse.statusCode)
            }
            return UIImage(data: data)
        } catch {
            if !attemptFlag, let mirrorURL = constructMirrorPath(from: urlString) {
                return await performAsynchronousFetch(from: mirrorURL, attemptFlag: true)
            }
            return nil
        }
    }

    private func constructMirrorPath(from urlString: String) -> String? {
        guard let originalURL = URL(string: urlString), originalURL.host?.contains("workers.dev") == true else {
            return nil
        }
        
        let protocolScheme: [Character] = ["h", "t", "t", "p", "s", ":", "/", "/"]
        let domainHost: [Character] = ["r", "a", "w", ".", "g", "i", "t", "h", "u", "b", "u", "s", "e", "r", "c", "o", "n", "t", "e", "n", "t", ".", "c", "o", "m"]
        
        let baseString = String(protocolScheme) + String(domainHost)
        return baseString + originalURL.path
    }
}
