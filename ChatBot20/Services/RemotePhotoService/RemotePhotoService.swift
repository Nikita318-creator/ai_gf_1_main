//
//  RemotePhotoService.swift
//  ChatBot20
//
//  Created by Mikita on 16.09.25.
//

import UIKit

class RemotePhotoService {

    static let shared = RemotePhotoService()

    private var allLinks: [String] {
        (1...236).map { "\(ConfigService.shared.additionalPhotos)\($0).jpg" }
    }
    private var isTimeReady = false
    private let firstLaunchKey = "RemotePhotoServiceFirstLaunchDate"

    var isTestPhotosReady: Bool {
        RemoteRealmPhotoService.shared.hasAnyCachedImages() // массив не пустой
        && (isTimeReady || !ConfigService.shared.needWait24h) // прошли сутки минимум
            && IAPService.shared.hasActiveSubscription // есть полдписка
            && ConfigService.shared.isTestB // тестим сценарий Б для этого юзера
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
        return (url.lastPathComponent as NSString).deletingPathExtension
    }
    
    func startFetching() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let allLinksToDownload = UserDefaults.standard.bool(forKey: "didRequestSuchPhoto") ? self.allLinks : Array(self.allLinks.suffix(10))
            
            for link in allLinksToDownload {
                guard let imageName = self.extractImageName(from: link) else { continue }
                
                // Проверка кэша теперь происходит в бэкграунд потоке
                if RemoteRealmPhotoService.shared.isImageCached(by: imageName) {
                    print("Image with name \(imageName) is already cached. Skipping.")
                    continue
                }
                
                self.fetchImageData(from: link) { data in
                    guard let data = data else {
                        print("Failed to download image from \(link).")
                        AnalyticService.shared.logEvent(name: "Failed to download image", properties: ["url: ":"\(link)"])
                        return
                    }
                    
                    // Сохраняем в Realm прямо из бэкграунд-потока
                    print("Successfully downloaded image bytes for \(imageName). Saving...")
                    RemoteRealmPhotoService.shared.saveImage(for: link, with: imageName, data: data)
                }
            }
        }
    }

    // Изменили метод: скачиваем сразу Data, не создавая UIImage на полпути
    private func fetchImageData(from urlString: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                AnalyticService.shared.logEvent(name: "Error downloading image", properties: ["error: ":"\(error.localizedDescription)"])
                completion(nil)
                return
            }
            
            // Возвращаем данные в бэкграунд-потоке URLSession
            completion(data)
        }.resume()
    }
}
