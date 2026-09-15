import UIKit

final class AdditionalRemotePhotoService {

    static let shared = AdditionalRemotePhotoService()
    
    private init() {}

    private var shownPicsByCategory: [Int: Set<String>] = [:]
    
    private let customPhotoCounts: [Int: Int] = [
        1: 123,
        2: 123,
        3: 115,
        4: 95,
        5: 123,
        6: 24,
        7: 115,
        8: 40,
        9: 23,
        10: 115
    ]

    func getRandomPhoto(for characterId: Int) async -> String {
        guard (1...26).contains(characterId) else { return "" }
        
        let photoCount = getPhotoCount(for: characterId)
        let currentPool = (1...photoCount).map { "\(characterId)_\($0)" }
        
        let alreadyShown = shownPicsByCategory[characterId] ?? []
        let notShownYet = currentPool.filter { !alreadyShown.contains($0) }
        
        let imageName: String
        if let randomNewName = notShownYet.randomElement() {
            imageName = randomNewName
            shownPicsByCategory[characterId, default: []].insert(imageName)
        } else {
            imageName = currentPool.randomElement() ?? ""
        }
        
        return await downloadPhoto(by: imageName)
    }

    func downloadPhoto(by imageName: String) async -> String {
        guard !imageName.isEmpty else { return "" }
        
        if AdditionalRemoteRealmPhotoService.shared.isImageCached(by: imageName) {
            return imageName
        }
        
        let urlString = "https://raw.githubusercontent.com/uvarovn771-blip/ai_gf_remote_photos/main/\(imageName).jpg"
        
        if let downloadedImage = await fetchImage(from: urlString),
           let imageData = downloadedImage.jpegData(compressionQuality: 0.8) {
            AdditionalRemoteRealmPhotoService.shared.saveImage(for: urlString, with: imageName, data: imageData)
        }
        
        return imageName
    }
    
    private func getPhotoCount(for characterId: Int) -> Int {
        switch characterId {
        case 1...10:
            return customPhotoCounts[characterId] ?? 15
        case 11...20:
            return 20
        case 21...26:
            return 15
        default:
            return 15
        }
    }

    private func fetchImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
}
