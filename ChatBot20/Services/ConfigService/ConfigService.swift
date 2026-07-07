import Foundation

struct Config: Codable { // todo новые поля обязательно опциональны должны быть иначе не распарситься json из кеша ???
    let configVersion: Int
    let isMode: Bool
    let isTestB: Bool
    let needWait24h: Bool
    let isProSubs: Bool
    let needAlwaysProSubs: Bool
    let isUSHaveDifferentPrice: Bool
    let useOnlyBillingApi: Bool
    let isVideoReady: Bool?
    let isFreeMode: Bool?
    let isMoodOn: Bool?
    let needResetData: Bool
    let dailyLimits: Int
    let initialLimit: Int
    let blondsVidCount: Int?
    let BrunetsVidCount: Int?
    let audioHalfKey: String?
    let topicRST: String
    let topicForGifts: String
    let messageFromDeveloper: String
    let additionalPhotos: String
    let baseServer: String?
    let additionalVideos: String?
    let additionalVideosCount: Int?
    let additionalPromptText: String?
}

final class ConfigService {
    static let shared = ConfigService()
    
    private(set) var needWait24h: Bool = false
    private(set) var isProSubs: Bool = true // только для онбординга
    private(set) var needAlwaysProSubs: Bool = false // только для лимитов
    private(set) var isUSHaveDifferentPrice: Bool = true // для нового пейволла новые цены на US
    private(set) var isTestB: Bool = false
    private(set) var useOnlyBillingApi: Bool = false
    private(set) var isVideoReady: Bool = false
    private(set) var isFreeMode: Bool = false
    private(set) var isMoodOn: Bool = false
    private(set) var needResetData: Bool = false
    private(set) var dailyLimits = 1
    private(set) var initialLimit = 3
    private(set) var blondsVidCount = 94
    private(set) var BrunetsVidCount = 99
    private(set) var audioHalfKey = ""
    private(set) var topicRST = ""
    private(set) var topicForGifts = ""
    private(set) var messageFromDeveloper = ""
    private(set) var additionalPhotos = "" {
        didSet {
            if isTestB && IAPService.shared.hasActiveSubscription {
                RemotePhotoService.shared.startFetching()
            }
        }
    }
    private(set) var baseServer = ""
    private(set) var additionalVideosCount = 35
    private(set) var additionalVideos = ""
    private(set) var additionalPromptText = ""
    
    private let configURL = URL(string: "https://raw.githubusercontent.com/Nikita318-creator/analitics-data/main/analitics628.json")
    private let cachedConfigKey = "cachedConfigKey"

    private init() {}
    
    func fetchConfig(completion: ((Bool) -> Void)? = nil) {
        guard let configURL else { return }
        
        let request = URLRequest(url: configURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, error == nil,
                  let remoteConfig = try? JSONDecoder().decode(Config.self, from: data) else {
                // Если не удалось загрузить, пробуем достать из кеша то, что есть
                DispatchQueue.main.async {
                    self.loadFromCacheOnly()
                    completion?(true)
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
           let cached = try? JSONDecoder().decode(Config.self, from: data) {
            self.setFrom(cached)
        }
    }
    
    private func processConfig(_ remoteConfig: Config, completion: ((Bool) -> Void)?) {
        var cachedConfig: Config? = nil
        if let data = UserDefaults.standard.data(forKey: cachedConfigKey) {
            cachedConfig = try? JSONDecoder().decode(Config.self, from: data)
        }
        
        let cachedIsMode = cachedConfig?.isMode ?? true // Default: true, чтобы "липкое false" работало
        let remoteIsMode = remoteConfig.isMode
        // Если кеш уже False, он остается False. Иначе берем значение из remote.
        let finalIsMode = !cachedIsMode ? false : remoteIsMode
        completion?(remoteConfig.needResetData ? remoteIsMode : finalIsMode)
        
        mergeAndApply(remote: remoteConfig, cached: cachedConfig)
    }
    
    // MARK: - Core Logic (Merge Strategy)
    private func mergeAndApply(remote: Config, cached: Config?) {
        let mergedConfig: Config
        
        if remote.needResetData {
            mergedConfig = remote
        } else {
            let cachedIsMode = cached?.isMode ?? true
            let remoteIsMode = remote.isMode
            let finalIsMode = !cachedIsMode ? false : remoteIsMode
            
            // 1. Logic for isTestB (Sticky True)
            let cachedIsTestB = cached?.isTestB ?? false
            let remoteIsTestB = remote.isTestB
            let finalIsTestB = cachedIsTestB || remoteIsTestB
            
            // 2. Logic for additionalPhotos (Never become empty if was populated)
            let cachedPhotos = cached?.additionalPhotos ?? ""
            let remotePhotos = remote.additionalPhotos
            
            let finalAdditionalPhotos: String
            if !cachedPhotos.isEmpty && remotePhotos.isEmpty {
                finalAdditionalPhotos = cachedPhotos
            } else {
                finalAdditionalPhotos = remotePhotos
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
            
            mergedConfig = Config(
                configVersion: remote.configVersion,
                isMode: finalIsMode,
                isTestB: finalIsTestB,
                needWait24h: remote.needWait24h,
                isProSubs: remote.isProSubs,
                needAlwaysProSubs: remote.needAlwaysProSubs,
                isUSHaveDifferentPrice: remote.isUSHaveDifferentPrice,
                useOnlyBillingApi: remote.useOnlyBillingApi,
                isVideoReady: remote.isVideoReady,
                isFreeMode: remote.isFreeMode,
                isMoodOn: remote.isMoodOn,
                needResetData: remote.needResetData,
                dailyLimits: remote.dailyLimits,
                initialLimit: remote.initialLimit,
                blondsVidCount: remote.blondsVidCount,
                BrunetsVidCount: remote.BrunetsVidCount,
                audioHalfKey: remote.audioHalfKey,
                topicRST: finalTopicRST,
                topicForGifts: remote.topicForGifts,
                messageFromDeveloper: remote.messageFromDeveloper,
                additionalPhotos: finalAdditionalPhotos,
                baseServer: remote.baseServer,
                additionalVideos: finalAdditionalVideos,
                additionalVideosCount: remote.additionalVideosCount,
                additionalPromptText: remote.additionalPromptText
            )
        }
        
        setFrom(mergedConfig)
        cacheConfig(mergedConfig)
    }

    private func setFrom(_ config: Config) {
        self.isTestB = config.isTestB
        self.needWait24h = config.needWait24h
        self.isProSubs = config.isProSubs
        self.needAlwaysProSubs = config.needAlwaysProSubs
        self.isUSHaveDifferentPrice = config.isUSHaveDifferentPrice
        self.useOnlyBillingApi = config.useOnlyBillingApi
        self.isVideoReady = config.isVideoReady ?? false
        self.isFreeMode = config.isFreeMode ?? false
        self.isMoodOn = config.isMoodOn ?? false
        self.needResetData = config.needResetData
        self.dailyLimits = config.dailyLimits
        self.initialLimit = config.initialLimit
        self.blondsVidCount = config.blondsVidCount ?? 94
        self.BrunetsVidCount = config.BrunetsVidCount ?? 99
        self.audioHalfKey = config.audioHalfKey ?? ""
        self.topicRST = config.topicRST
        self.topicForGifts = config.topicForGifts
        self.messageFromDeveloper = config.messageFromDeveloper
        self.additionalPhotos = config.additionalPhotos
        self.baseServer = config.baseServer ?? ""
        self.additionalVideosCount = config.additionalVideosCount ?? 35
        self.additionalVideos = config.additionalVideos ?? ""
        self.additionalPromptText = config.additionalPromptText ?? ""
    }

    private func cacheConfig(_ config: Config) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: cachedConfigKey)
        }
    }
}
