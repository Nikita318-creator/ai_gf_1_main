//
//  AdditionalRemotePhotoService.swift
//  ChatBot20
//
//  Created by Mikita on 21/03/2026.
//

import UIKit

class AdditionalRemotePhotoService {

    static let shared = AdditionalRemotePhotoService()

    // Сохраняем эти массивы, так как они используются в других частях кода
    let picMilfDs1 = (1...15).map { "milf1_\($0)" }
    let picMilfDs2 = (1...15).map { "milf2_\($0)" }
    let picMilfDs3 = (1...15).map { "milf3_\($0)" }
    let picMilfDs4 = (1...15).map { "milf4_\($0)" }
    let picMilfDs5 = (1...15).map { "milf5_\($0)" }
    
    private var shownPicsByCategory: [Int: Set<String>] = [
        1: [], 2: [], 3: [], 4: [], 5: []
    ]
    
    func getRandomPhoto(for milfId: Int) async -> String {
        // 1. Определяем целевой массив имен (без изменений)
        let currentPool: [String]
        switch milfId {
        case 1: currentPool = picMilfDs1
        case 2: currentPool = picMilfDs2
        case 3: currentPool = picMilfDs3
        case 4: currentPool = picMilfDs4
        case 5: currentPool = picMilfDs5
        default: return ""
        }
        
        // 2. Логика выбора имени файла (без изменений)
        let alreadyShown = shownPicsByCategory[milfId] ?? []
        let notShownYet = currentPool.filter { !alreadyShown.contains($0) }
        
        let imageName: String
        if let randomNewName = notShownYet.randomElement() {
            imageName = randomNewName
            shownPicsByCategory[milfId]?.insert(imageName)
        } else {
            imageName = currentPool.randomElement() ?? ""
        }
        
        // 3. Проверяем Realm. Если есть — отдаем сразу
        if AdditionalRemoteRealmPhotoService.shared.isImageCached(by: imageName) {
            return imageName
        }
        
        // 4. Если в кэше нет — ЖДЕМ скачивания
        let urlString = "https://raw.githubusercontent.com/uvarovn771-blip/ai_gf_remote_photos/main/\(imageName).jpg"
        
        // Код замирает на этой строке до завершения загрузки
        if let downloadedImage = await fetchImage(from: urlString) {
            // Сохраняем в Realm
            if let imageData = downloadedImage.jpegData(compressionQuality: 0.8) {
                AdditionalRemoteRealmPhotoService.shared.saveImage(for: urlString, with: imageName, data: imageData)
            }
        }
        
        // Только теперь возвращаем имя
        return imageName
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
