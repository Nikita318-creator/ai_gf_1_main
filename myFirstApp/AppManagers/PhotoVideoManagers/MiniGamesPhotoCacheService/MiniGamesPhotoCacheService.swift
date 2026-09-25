import UIKit

final class MiniGamesPhotoCacheService {
    
    static let shared = MiniGamesPhotoCacheService()
    
    private init() {}
    
    private var baseURL: String {
        APIManager.shared.mainPhotoPath + "ai_gf_remote_photos/main/"
    }
    
    // Флаг, чтобы избегать параллельного запуска процесса кеширования
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
                        let initialUrlString = "\(self.baseURL)\(name).jpg"
                        await self.downloadAndSavePhoto(imageName: name, urlString: initialUrlString)
                    }
                }
            }
            
            await MainActor.run {
                self.isCachingInProgress = false
            }
        }
    }
    
    private func downloadAndSavePhoto(imageName: String, urlString: String, isRetry: Bool = false) async {
        guard !imageName.isEmpty else { return }
        
        // Повторная проверка на случай, если файл скачался параллельно
        if AdditionalRemoteRealmPhotoService.shared.isImageCached(by: imageName) {
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            // Если статус ответа не OK (200), перехватываем для подстраховки
            guard statusCode == 200,
                  let image = UIImage(data: data),
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                
                // Пробуем перезапросить напрямую с GitHub, если это была Cloudflare ссылка
                if !isRetry, let fallbackUrlString = makeDirectGitHubUrl(from: urlString) {
                    let alertMessage = "⚠️🚨 Cloudflare error! GitHub TRIGGERED! 🚨⚠️\n\nCloudflare улетел в ошибку! Работаем на gitHub напрямую.\n\n"
                    TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
                    AmplitudeManager.shared.logEvent(
                        name: "⚠️🚨 Cloudflare error! GitHub TRIGGERED!",
                        properties: ["":""]
                    )
                    print("⚠️ Cloudflare image download failed (\(statusCode)). Retrying directly via GitHub: \(fallbackUrlString)")
                    await downloadAndSavePhoto(imageName: imageName, urlString: fallbackUrlString, isRetry: true)
                    return
                }
                
                let alertMessage = "⚠️🚨 Cloudflare error! GitHub error! 🚨⚠️\n\nCloudflare and GitHub конфиг улетел в ошибку! все пропало!.\n\n"
                TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
                AmplitudeManager.shared.logEvent(
                    name: "⚠️🚨 Cloudflare error! GitHub error! 🚨⚠️",
                    properties: ["":""]
                )
                return
            }
            
            AdditionalRemoteRealmPhotoService.shared.saveImage(
                for: urlString,
                with: imageName,
                data: imageData
            )
        } catch {
            print("Failed to download image: \(imageName), error: \(error)")
            
            // В случае сетевой ошибки провайдера пробуем сходить напрямую на GitHub
            if !isRetry, let fallbackUrlString = makeDirectGitHubUrl(from: urlString) {
                let alertMessage = "⚠️🚨 Cloudflare error! GitHub TRIGGERED! 🚨⚠️\n\nCloudflare улетел в ошибку! Работаем на gitHub напрямую.\n\n"
                TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
                AmplitudeManager.shared.logEvent(
                    name: "⚠️🚨 Cloudflare error! GitHub TRIGGERED!",
                    properties: ["":""]
                )
                print("⚠️ Network error on Cloudflare. Retrying directly via GitHub: \(fallbackUrlString)")
                await downloadAndSavePhoto(imageName: imageName, urlString: fallbackUrlString, isRetry: true)
                return
            }
            
            let alertMessage = "⚠️🚨 Cloudflare error! GitHub error! 🚨⚠️\n\nCloudflare and GitHub конфиг улетел в ошибку! все пропало!.\n\n"
            TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
            AmplitudeManager.shared.logEvent(
                name: "⚠️🚨 Cloudflare error! GitHub error! 🚨⚠️",
                properties: ["":""]
            )
        }
    }
    
    // Вспомогательный метод: превращает URL Worker'а в прямой URL на GitHub Raw
    private func makeDirectGitHubUrl(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        if url.host?.contains("workers.dev") == true {
            let path = url.path
            return "https://raw.githubusercontent.com" + path
        }
        
        return nil
    }
}
