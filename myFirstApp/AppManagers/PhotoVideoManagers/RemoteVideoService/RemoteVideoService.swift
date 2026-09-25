import UIKit

final class RemoteVideoService {

    static let shared = RemoteVideoService()

    private let allLinksBlond = (1...APIManager.shared.blondsVidCount).map {
        APIManager.shared.secondPhotoPath + "vidiosAIGF/main/blondvid/blondVid\($0).mp4"
    }
    
    private let allLinksBrunet = (1...APIManager.shared.BrunetsVidCount).map {
        APIManager.shared.secondPhotoPath + "vidiosAIGF/main/brunetvid/brunetVid\($0).mp4"
    }
    
    private let allLinksAnime = (1...164).map {
        APIManager.shared.mainPhotoPath + "anime_rol/main/rolVid\($0).mp4"
    }
    
    private var allLinks: [String] {
        allLinksBlond + allLinksBrunet
    }

    private var sessionRemainingLinks: [String: [String]] = [:]

    private init() {
        resetSession()
    }
    
    // MARK: - Setup Logic
    
    private func resetSession() {
        sessionRemainingLinks["blond"] = allLinksBlond.shuffled()
        sessionRemainingLinks["brunet"] = allLinksBrunet.shuffled()
        sessionRemainingLinks["anime"] = allLinksAnime.shuffled()
        sessionRemainingLinks["all"] = allLinks.shuffled()
    }

    // MARK: - Public API
    
    func getVideoData(for avatar: String, completion: @escaping (String?) -> Void) {
        let urlString = selectVideoUrl(for: avatar)
        
        guard let name = extractVideoName(from: urlString) else {
            print("Error: Could not extract name from URL: \(urlString)")
            completion(nil)
            return
        }
        
        if RemoteRealmVideoService.shared.isVideoCached(name: name) {
            print("Video found in Realm: \(name)")
            completion(name)
            return
        }
        
        print("Video not cached, downloading: \(urlString)")
        downloadVideo(from: urlString) { name in
            completion(name)
        }
    }
    
    // MARK: - Private Logic
    
    private func selectVideoUrl(for avatar: String) -> String {
        let category: String
        
        if ["mainAvatar1", "mainAvatar2", "mainAvatar4", "mainAvatar5", "mainAvatar6", "mainAvatar27", "mainAvatar21", "mainAvatar23", "mainAvatar24"].contains(avatar) {
            category = "blond"
        } else if ["mainAvatar3", "mainAvatar7", "mainAvatar8", "mainAvatar9", "mainAvatar10", "mainAvatar28", "mainAvatar26", "mainAvatar22", "mainAvatar25"].contains(avatar) {
            category = "brunet"
        } else if ["mainAvatar11", "mainAvatar12", "mainAvatar13", "mainAvatar14", "mainAvatar15", "mainAvatar16", "mainAvatar17", "mainAvatar18", "mainAvatar19", "mainAvatar20"].contains(avatar) {
            category = "anime"
        } else {
            category = "all"
        }
        
        if let remaining = sessionRemainingLinks[category], !remaining.isEmpty {
            let link = sessionRemainingLinks[category]!.removeLast()
            return link
        } else {
            return allLinks.randomElement() ?? ""
        }
    }

    private func downloadVideo(from urlString: String, isRetry: Bool = false, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        guard let name = extractVideoName(from: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            
            // Если произошла ошибка сети или статус ответа не OK (200...299)
            if error != nil || !(200...299).contains(statusCode) {
                print("Download Error (Status: \(statusCode)): \(error?.localizedDescription ?? "HTTP Error")")
                
                // Подстраховка: если это был запрос к Cloudflare и мы ещё не пробовали повторно
                if !isRetry, let fallbackUrlString = self?.makeDirectGitHubUrl(from: urlString) {
                    let alertMessage = "⚠️🚨 Cloudflare error! GitHub TRIGGERED! 🚨⚠️\n\nCloudflare улетел в ошибку! Работаем на gitHub напрямую.\n\n"
                    TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
                    AmplitudeManager.shared.logEvent(
                        name: "⚠️🚨 Cloudflare error! GitHub TRIGGERED!",
                        properties: ["":""]
                    )
                    print("⚠️ Cloudflare failed. Retrying directly via GitHub: \(fallbackUrlString)")
                    self?.downloadVideo(from: fallbackUrlString, isRetry: true, completion: completion)
                    return
                }
                
                let alertMessage = "⚠️🚨 Cloudflare error! GitHub error! 🚨⚠️\n\nCloudflare and GitHub конфиг улетел в ошибку! все пропало!.\n\n"
                AmplitudeManager.shared.logEvent(
                    name: "⚠️🚨 Cloudflare error! GitHub error! 🚨⚠️",
                    properties: ["":""]
                )
                TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async {
                RemoteRealmVideoService.shared.saveVideo(
                    urlString: urlString,
                    name: name,
                    data: data
                )
                completion(name)
            }
        }.resume()
    }

    // Вспомогательный метод: превращает URL вида "https://summer-leaf-c988...workers.dev/xxxxxxx/..."
    // в прямой URL "https://raw.githubusercontent.com/xxxxxxx/..."
    private func makeDirectGitHubUrl(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Преобразуем только если запрос шёл через наш Cloudflare Worker
        if url.host?.contains("workers.dev") == true {
            let path = url.path // Получим "/xxxxxxx/..."
            return "https://raw.githubusercontent.com" + path
        }
        
        return nil
    }

    private func extractVideoName(from urlString: String) -> String? {
        URL(string: urlString)?
            .deletingPathExtension()
            .lastPathComponent
    }
}
