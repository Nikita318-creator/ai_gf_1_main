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

    private func downloadVideo(from urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        guard let name = extractVideoName(from: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Download Error: \(error?.localizedDescription ?? "Unknown")")
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

    private func extractVideoName(from urlString: String) -> String? {
        URL(string: urlString)?
            .deletingPathExtension()
            .lastPathComponent
    }
}
