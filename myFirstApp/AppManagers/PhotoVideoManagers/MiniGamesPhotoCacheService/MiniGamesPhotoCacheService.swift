import UIKit

final class MiniGamesPhotoCacheService {
    
    static let shared = MiniGamesPhotoCacheService()
    
    private init() {}
    
    private let baseURL = "https://raw.githubusercontent.com/uvarovn771-blip/ai_gf_remote_photos/main/"
    
    // Флаг, чтобы избегать параллельных запускa процесса кеширования
    private var isCachingInProgress = false
    
    // MARK: - Full Image Pool
    
    /// Динамический расчет всех необходимых имен файлов для мини-игр
    var requiredImageNames: [String] {
        var names: [String] = [
            "reversiPreview",
            "checkersPteview",
            "2048preview",
            "jigsawPreview",
            "rockPaperPreview",
            "tictacPreview",
            "banner_wardrob_bg",
            "waifuInOutfit_start"
        ]
        
        // novel1_1 ... novel1_13
        names.append(contentsOf: (1...13).map { "novel1_\($0)" })
        
        // novel2_1 ... novel2_16
        names.append(contentsOf: (1...16).map { "novel2_\($0)" })
        
        // novel3_1 ... novel3_15
        names.append(contentsOf: (1...15).map { "novel3_\($0)" })
        
        // AAvatarForGeme1 ... AAvatarForGeme9
        names.append(contentsOf: (1...9).map { "AAvatarForGeme\($0)" })
        
        // AvatarForGeme1 ... AvatarForGeme8
        names.append(contentsOf: (1...8).map { "AvatarForGeme\($0)" })
        
        // CAvatarForGeme1 ... CAvatarForGeme9
        names.append(contentsOf: (0...9).map { "CAvatarForGeme\($0)" })
        
        // outfit_1 ... outfit_19
        names.append(contentsOf: (1...19).map { "outfit_\($0)" })
        
        // waifuInOutfit_1 ... waifuInOutfit_19
        names.append(contentsOf: (1...19).map { "waifuInOutfit_\($0)" })
        
        return names
    }
    
    // MARK: - Public API
    
    /// Проверяет, закешированы ли ВСЕ картинки из пула.
    /// Если нет — возвращает `false` и запускает фоновый процесс скачивания отсутствующих фото.
    /// Если да — возвращает `true`.
    @discardableResult
    func isCacheReadyAndPreloadIfNeeded() -> Bool {
        guard APIManager.shared.isABTestRandom else { return false }
        
        let missingImages = requiredImageNames.filter {
            !AdditionalRemoteRealmPhotoService.shared.isImageCached(by: $0)
        }
        
        if missingImages.isEmpty {
            return true
        } else {
            startBackgroundCaching(for: missingImages)
            return false
        }
    }
    
    /// Достает готовую картинку из локального кэша по ее имени
    func getImage(named imageName: String) -> UIImage? {
        return AdditionalRemoteRealmPhotoService.shared.getImage(by: imageName)
    }
    
    // MARK: - Private Helper Methods
    
    private func startBackgroundCaching(for imageNames: [String]) {
        guard !isCachingInProgress else { return }
        isCachingInProgress = true
        
        Task(priority: .background) {
            // Использование TaskGroup дает параллельное скачивание с контролем сети
            await withTaskGroup(of: Void.self) { group in
                for name in imageNames {
                    group.addTask {
                        await self.downloadAndSavePhoto(imageName: name)
                    }
                }
            }
            
            await MainActor.run {
                self.isCachingInProgress = false
            }
        }
    }
    
    private func downloadAndSavePhoto(imageName: String) async {
        guard !imageName.isEmpty else { return }
        
        // Повторная проверка на случай, если файл скачался параллельно
        if AdditionalRemoteRealmPhotoService.shared.isImageCached(by: imageName) {
            return
        }
        
        let urlString = "\(baseURL)\(imageName).jpg"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = UIImage(data: data),
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                return
            }
            
            AdditionalRemoteRealmPhotoService.shared.saveImage(
                for: urlString,
                with: imageName,
                data: imageData
            )
        } catch {
            print("Failed to preload image: \(imageName), error: \(error)")
        }
    }
}


//final class MiniGameViewModel {
//    
//    func checkCacheStatus() {
//        let isReady = MiniGamesPhotoCacheService.shared.isCacheReadyAndPreloadIfNeeded()
//        
//        if isReady {
//            // Весь кэш на месте, можно сразу отображать контент без скелетонов/плейсхолдеров
//        } else {
//            // Кэш не полный: сервис уже автоматически запустил скачивание недостающих ресурсов в фоновом потоке
//        }
//    }
//    
//    /// Получение картинки для UI
//    func getPhoto(named name: String) -> UIImage? {
//        return MiniGamesPhotoCacheService.shared.getImage(named: name)
//    }
//}
