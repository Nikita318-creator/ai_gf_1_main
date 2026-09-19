import Foundation

struct APIModel: Codable { // todo новые поля обязательно опциональны должны быть иначе не распарситься json из кеша ???
    let configVersion: Int
    let isTestB: Bool
    let isRemotePhoto: Bool
    let needWait24h: Bool
    let isVideoReady: Bool?
    let isFreeMode: Bool?
    let isMoodOn: Bool?
    let needRequestReview: Bool?
    let isYearSubActive: Bool?
    let needResetData: Bool
    let dailyLimits: Int
    let initialLimit: Int
    let blondsVidCount: Int?
    let BrunetsVidCount: Int?
    let audioHalfKey: String?
    let topicRST: String
    let messageFromDeveloper: String
    let additionalPhotos: String
    let additionalPhotosAnime: String
    let baseServer: String?
    let additionalVideos: String?
    let additionalVideosCount: Int?
    let additionalPromptText: String?
}

final class APIManager {
    static let shared = APIManager()
    
    private(set) var needWait24h: Bool = false
    private(set) var isTestB: Bool = false
    private(set) var isRemotePhoto: Bool = false
    private(set) var isVideoReady: Bool = false
    private(set) var isFreeMode: Bool = false
    private(set) var isMoodOn: Bool = false
    private(set) var needRequestReview: Bool = false
    private(set) var isYearSubActive: Bool = true
    private(set) var needResetData: Bool = false
    private(set) var dailyLimits = 1
    private(set) var initialLimit = 3
    private(set) var blondsVidCount = 94
    private(set) var BrunetsVidCount = 99
    private(set) var audioHalfKey = ""
    private(set) var topicRST = ""
    private(set) var messageFromDeveloper = ""
    private(set) var additionalPhotos = "" {
        didSet {
            if isTestB && SubscriptionManager.shared.hasActiveSubscription {
                GiftsPhotoService.shared.startFetching()
            }
        }
    }
    private(set) var additionalPhotosAnime = "" {
        didSet {
            if isTestB && SubscriptionManager.shared.hasActiveSubscription {
                GiftsPhotoService.shared.startFetching()
            }
        }
    }
    
    private(set) var baseServer = ""
    private(set) var additionalVideosCount = 35
    private(set) var additionalVideos = ""
    private(set) var additionalPromptText = ""
    
    private let configURL = URL(string: "https://raw.githubusercontent.com/romanbystrov392-bit/AnaliticaTests/main/testData1.json")
    private let cachedConfigKey = "cachedConfigKey"

    private init() {}
    
    func fetchConfig(completion: ((Bool) -> Void)? = nil) {
        guard let configURL else { return }
        
        let request = URLRequest(url: configURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, error == nil,
                  let remoteConfig = try? JSONDecoder().decode(APIModel.self, from: data) else {
                // Если не удалось загрузить, пробуем достать из кеша то, что есть
                DispatchQueue.main.async {
                    self.loadFromCacheOnly()
                    completion?(false)
                }
                return
            }

            DispatchQueue.main.async {
                self.processConfig(remoteConfig, completion: completion)
            }
        }.resume()
    }
    
    private func loadFromCacheOnly() {
        if let data = UserDefaults.standard.data(forKey: cachedConfigKey),
           let cached = try? JSONDecoder().decode(APIModel.self, from: data) {
            self.setFrom(cached)
        }
    }
    
    private func processConfig(_ remoteConfig: APIModel, completion: ((Bool) -> Void)?) {
        var cachedConfig: APIModel? = nil
        if let data = UserDefaults.standard.data(forKey: cachedConfigKey) {
            cachedConfig = try? JSONDecoder().decode(APIModel.self, from: data)
        }
        
        let cachedIsMode = cachedConfig?.isTestB ?? false
        let remoteIsMode = remoteConfig.isTestB
        let finalIsMode = remoteIsMode || cachedIsMode
        completion?(remoteConfig.needResetData ? remoteIsMode : finalIsMode)
        
        mergeAndApply(remote: remoteConfig, cached: cachedConfig)
    }
    
    // MARK: - Core Logic (Merge Strategy)
    private func mergeAndApply(remote: APIModel, cached: APIModel?) {
        let mergedConfig: APIModel
        
        if remote.needResetData {
            mergedConfig = remote
        } else {
            // 1. Logic for isTestB (Sticky True)
            let cachedIsTestB = cached?.isTestB ?? false
            let remoteIsTestB = remote.isTestB
            let finalIsTestB = cachedIsTestB || remoteIsTestB
            
            let cachedIsRemotePhoto = cached?.isRemotePhoto ?? false
            let remoteIsRemotePhoto = remote.isRemotePhoto
            let finalIsRemotePhoto = cachedIsRemotePhoto || remoteIsRemotePhoto
            
            // 2. Logic for additionalPhotos (Never become empty if was populated)
            let cachedPhotos = cached?.additionalPhotos ?? ""
            let remotePhotos = remote.additionalPhotos
            
            let finalAdditionalPhotos: String
            if !cachedPhotos.isEmpty && remotePhotos.isEmpty {
                finalAdditionalPhotos = cachedPhotos
            } else {
                finalAdditionalPhotos = remotePhotos
            }
            
            let cachedPhotosAnime = cached?.additionalPhotosAnime ?? ""
            let remotePhotosAnime = remote.additionalPhotosAnime
            let finalAdditionalPhotosAnime: String
            if !cachedPhotosAnime.isEmpty && remotePhotosAnime.isEmpty {
                finalAdditionalPhotosAnime = cachedPhotosAnime
            } else {
                finalAdditionalPhotosAnime = remotePhotosAnime
            }
            
            // 3. Logic for topicRST
            let cachedTopicRST = cached?.topicRST ?? ""
            let remoteTopicRST = remote.topicRST
            
            let finalTopicRST: String
            if remoteIsTestB {
                finalTopicRST = remoteTopicRST
            } else {
                if !cachedTopicRST.isEmpty {
                    finalTopicRST = cachedTopicRST
                } else {
                    finalTopicRST = remoteTopicRST
                }
            }
            
            let finalAdditionalVideos: String
            if let cachedVideos = cached?.additionalVideos, !cachedVideos.isEmpty {
                finalAdditionalVideos = cachedVideos
            } else {
                finalAdditionalVideos = remote.additionalVideos ?? ""
            }
            
            mergedConfig = APIModel(
                configVersion: remote.configVersion,
                isTestB: finalIsTestB,
                isRemotePhoto: finalIsRemotePhoto,
                needWait24h: remote.needWait24h,
                isVideoReady: remote.isVideoReady,
                isFreeMode: remote.isFreeMode,
                isMoodOn: remote.isMoodOn,
                needRequestReview: remote.needRequestReview,
                isYearSubActive: remote.isYearSubActive,
                needResetData: remote.needResetData,
                dailyLimits: remote.dailyLimits,
                initialLimit: remote.initialLimit,
                blondsVidCount: remote.blondsVidCount,
                BrunetsVidCount: remote.BrunetsVidCount,
                audioHalfKey: remote.audioHalfKey,
                topicRST: finalTopicRST,
                messageFromDeveloper: remote.messageFromDeveloper,
                additionalPhotos: finalAdditionalPhotos,
                additionalPhotosAnime: finalAdditionalPhotosAnime,
                baseServer: remote.baseServer,
                additionalVideos: finalAdditionalVideos,
                additionalVideosCount: remote.additionalVideosCount,
                additionalPromptText: remote.additionalPromptText
            )
        }
        
        setFrom(mergedConfig)
        cacheConfig(mergedConfig)
    }

    private func setFrom(_ config: APIModel) {
        self.isTestB = config.isTestB
        self.isRemotePhoto = config.isRemotePhoto
        self.needWait24h = config.needWait24h
        self.isVideoReady = config.isVideoReady ?? false
        self.isFreeMode = config.isFreeMode ?? false
        self.isMoodOn = config.isMoodOn ?? false
        self.needRequestReview = config.needRequestReview ?? false
        self.isYearSubActive = config.isYearSubActive ?? true
        self.needResetData = config.needResetData
        self.dailyLimits = config.dailyLimits
        self.initialLimit = config.initialLimit
        self.blondsVidCount = config.blondsVidCount ?? 94
        self.BrunetsVidCount = config.BrunetsVidCount ?? 99
        self.audioHalfKey = config.audioHalfKey ?? ""
        self.topicRST = config.topicRST
        self.messageFromDeveloper = config.messageFromDeveloper
        self.additionalPhotos = config.additionalPhotos
        self.additionalPhotosAnime = config.additionalPhotosAnime
        self.baseServer = config.baseServer ?? ""
        self.additionalVideosCount = config.additionalVideosCount ?? 35
        self.additionalVideos = config.additionalVideos ?? ""
        self.additionalPromptText = config.additionalPromptText ?? ""
    }

    private func cacheConfig(_ config: APIModel) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: cachedConfigKey)
        }
    }
}
