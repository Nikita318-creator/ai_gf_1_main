import UIKit

enum PhotoCategory {
    case standard
    case anime
}

class GiftsPhotoService {

    static let shared = GiftsPhotoService()

    private var allLinks: [String] {
        (1...236).map { "\(ConfigService.shared.additionalPhotos)\($0).jpg" }
    }
    
    private var allLinksAnime: [String] {
        (1...236).map { "\(ConfigService.shared.additionalPhotosAnime)\($0).jpg" }
    }

    private var isTimeReady = false
    private let firstLaunchKey = "RemotePhotoServiceFirstLaunchDate"

    var isTestPhotosReady: Bool {
        GiftRealmPhotoService.shared.hasAnyCachedImages()
        && (isTimeReady || !ConfigService.shared.needWait24h)
        && IAPService.shared.hasActiveSubscription
        && ConfigService.shared.isTestB
    }
    
    var alreadyShownPics: [String] = []

    private init() {
        checkFirstLaunch()
    }

    private func checkFirstLaunch() {
        let defaults = UserDefaults.standard
        if let savedDate = defaults.object(forKey: firstLaunchKey) as? Date {
            isTimeReady = Date().timeIntervalSince(savedDate) > 24 * 60 * 60
        } else {
            defaults.set(Date(), forKey: firstLaunchKey)
            isTimeReady = false
        }
    }

    private func extractImageName(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let baseName = (url.lastPathComponent as NSString).deletingPathExtension
        
        // Префикс добавляется ТОЛЬКО для аниме. Обычные остаются без изменений.
        if urlString.contains(ConfigService.shared.additionalPhotosAnime) {
            return "anime_\(baseName)"
        } else {
            return baseName
        }
    }

    func startFetching() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let isFullDownload = UserDefaults.standard.bool(forKey: "didRequestSuchPhoto")
            
            let linksToDownload = isFullDownload ? self.allLinks : Array(self.allLinks.suffix(10))
            let animeLinksToDownload = isFullDownload ? self.allLinksAnime : Array(self.allLinksAnime.suffix(10))
            
            let totalLinksToDownload = linksToDownload + animeLinksToDownload

            for link in totalLinksToDownload {
                guard let imageName = self.extractImageName(from: link) else { continue }

                if GiftRealmPhotoService.shared.isImageCached(by: imageName) {
                    print("Image with name \(imageName) is already cached. Skipping.")
                    continue
                }

                self.fetchImageData(from: link) { data in
                    guard let data = data else {
                        print("Failed to download image from \(link).")
                        AnalyticService.shared.logEvent(
                            name: "Failed to download image",
                            properties: ["url: ": "\(link)"]
                        )
                        return
                    }

                    // Здесь передается imageName (для аниме это "anime_1", для обычных — "1")
                    // В Realm и на диск сохранение пойдет строго под этим именем.
                    print("Successfully downloaded image bytes for \(imageName). Saving...")
                    GiftRealmPhotoService.shared.saveImage(for: link, with: imageName, data: data)
                }
            }
        }
    }

    private func fetchImageData(from urlString: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                AnalyticService.shared.logEvent(
                    name: "Error downloading image",
                    properties: ["error: ": "\(error.localizedDescription)"]
                )
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
}
