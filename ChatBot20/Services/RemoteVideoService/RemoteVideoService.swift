import UIKit

final class RemoteVideoService {

    static let shared = RemoteVideoService()

    private let allLinksBlond = (1...ConfigService.shared.blondsVidCount).map {
        "https://raw.githubusercontent.com/npanezai9-ux/vidiosAIGF/main/blondvid/blondVid\($0).mp4"
    }
    
    private let allLinksBrunet = (1...ConfigService.shared.BrunetsVidCount).map {
        "https://raw.githubusercontent.com/npanezai9-ux/vidiosAIGF/main/brunetvid/brunetVid\($0).mp4"
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
        
        if ["1", "2", "4", "7", "10", "CustomAvatar1", "CustomAvatar4"].contains(avatar) {
            category = "blond"
        } else if ["3", "5", "6", "8", "9", "CustomAvatar2", "CustomAvatar6", "CustomAvatar9"].contains(avatar) {
            category = "brunet"
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
