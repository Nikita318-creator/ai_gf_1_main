import UIKit

final class AdditionalRemotePhotoService {

    static let shared = AdditionalRemotePhotoService()
    
    private init() {}

    private var shownPicsByCategory: [String: Set<String>] = [:]
    
    private let customPhotoCounts: [Int: Int] = [
        1: 123, 2: 123, 3: 115, 4: 95, 5: 123,
        6: 35, 7: 115, 8: 58, 9: 38, 10: 115
    ]
    
    // Для MyGF 1..4 ровно по 10 фоток
    private let myGFPhotoCounts: [Int: Int] = [
        1: 15,
        2: 15,
        3: 15,
        4: 15
    ]

    func getRandomPhoto(for characterId: Int) async -> String {
        guard APIManager.shared.isABTestRandom else {
            let imageName = getTestAPhotoName(for: characterId)
            return await downloadPhoto(by: imageName)
        }
        
        let count = getPhotoCount(for: characterId)
        let pool = (1...count).map { "\(characterId)_\($0)" }
        return await getRandomPhoto(categoryKey: "\(characterId)", pool: pool)
    }

    func getRandomPhoto(forMyGF id: Int) async -> String {
        guard APIManager.shared.isABTestRandom else {
            let imageName = "TestA_\(Int.random(in: 1...60))"
            return await downloadPhoto(by: imageName)
        }
        
        let count = myGFPhotoCounts[id] ?? 10
        let pool = (1...count).map { "MyGF_\(id)_\($0)" }
        return await getRandomPhoto(categoryKey: "MyGF_\(id)", pool: pool)
    }

    func getRandomPhotoFromAllPool(avatarID: String) async -> String {
        guard APIManager.shared.isABTestRandom else {
            let imageName = "TestA_\(Int.random(in: 1...60))"
            return await downloadPhoto(by: imageName)
        }

        // 1. Собираем фотографии стандартных персонажей (1...20)
        var fullPool: [String] = []

        if avatarID == "groupChat4" {
            for characterId in 1...10 {
                let count = getPhotoCount(for: characterId)
                let characterPool = (1...count).map { "\(characterId)_\($0)" }
                fullPool.append(contentsOf: characterPool)
            }
        } else {
            for characterId in 11...20 {
                let count = getPhotoCount(for: characterId)
                let characterPool = (1...count).map { "\(characterId)_\($0)" }
                fullPool.append(contentsOf: characterPool)
            }
        }
        
        // Используем общую логику ротации с трекингом показанных фото
        return await getRandomPhoto(categoryKey: "GlobalAllPool", pool: fullPool)
    }
    
    // Вспомогательный метод выбора -картинки для Test A
    private func getTestAPhotoName(for characterId: Int) -> String {
        let index: Int
        if (11...20).contains(characterId) {
            index = Int.random(in: 41...60)
        } else {
            index = Int.random(in: 1...40)
        }
        return "TestA_\(index)"
    }

    // Общая логика рандома и исключения повторов (только для Test B / Production)
    private func getRandomPhoto(categoryKey: String, pool: [String]) async -> String {
        guard !pool.isEmpty else { return "" }
        
        let alreadyShown = shownPicsByCategory[categoryKey] ?? []
        let notShownYet = pool.filter { !alreadyShown.contains($0) }
        
        let imageName: String
        if let randomNewName = notShownYet.randomElement() {
            imageName = randomNewName
            shownPicsByCategory[categoryKey, default: []].insert(imageName)
        } else {
            imageName = pool.randomElement() ?? ""
        }
        
        return await downloadPhoto(by: imageName)
    }

    func downloadPhoto(by imageName: String) async -> String {
        guard !imageName.isEmpty else { return "" }
        
        if AdditionalRemoteRealmPhotoService.shared.isImageCached(by: imageName) {
            return imageName
        }
        
        let urlString = APIManager.shared.mainPhotoPath +  "ai_gf_remote_photos/main/\(imageName).jpg"
        
        if let downloadedImage = await fetchImage(from: urlString),
           let imageData = downloadedImage.jpegData(compressionQuality: 0.8) {
            AdditionalRemoteRealmPhotoService.shared.saveImage(for: urlString, with: imageName, data: imageData)
        }
        
        return imageName
    }
    
    private func getPhotoCount(for characterId: Int) -> Int {
        switch characterId {
        case 1...10:  return customPhotoCounts[characterId] ?? 15
        case 11...20: return 20
        case 21...25: return 15
        case 26:      return 32
        case 27:      return 123
        case 28:      return 115
        default:      return 15
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
