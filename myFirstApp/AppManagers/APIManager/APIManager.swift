import Foundation

// добавляешь поле? -- опционал! иначе парсинг json упадет!
struct APIModel: Codable {
    let messagesDailyCount: Int
    let messagesFirstOpenCount: Int
    let mainPhotoPath: String?
    let secondPhotoPath: String?
    let blondsVidCount: Int?
    let BrunetsVidCount: Int?
    let someHalfSafeKey: String?
    let userPromptMain: String
    let myMessageToUsers: String
    let testPicks: String
    let testPicksAnime: String
    let baseServer: String?
    let testClips: String?
    let testClipsCount: Int?
    let secondUserPrompt: String?
    
    let configVersion: Int
    let isABTestRandom: Bool
    let isRemotePhoto: Bool
    let isWaiting24: Bool
    let videoLoaded: Bool?
    let canGotPremiumForDailyLogin: Bool?
    let shouldSwitchMoods: Bool?
    let needRequestReview: Bool?
    let isYearSubActive: Bool?
    let isForceReset: Bool
}

final class APIManager {
    static let shared = APIManager()
    
    private let primaryConfigURL = URL(string: "https://raw.githubusercontent.com/romanbystrov392-bit/AnaliticaTests/main/testData1.json")
    private let fallbackConfigURL = URL(string: "https://raw.githubusercontent.com/my-projext-test-gh-all/AnaliticaTests/main/testData1.json")
    private let myDBKey = "myDBKey"
    
    private(set) var mainPhotoPath = ""
    private(set) var secondPhotoPath = ""
    private(set) var messagesDailyCount = 2
    private(set) var messagesFirstOpenCount = 3
    private(set) var blondsVidCount = 94
    private(set) var BrunetsVidCount = 99
    private(set) var someHalfSafeKey = ""
    private(set) var userPromptMain = ""
    private(set) var myMessageToUsers = ""
    private(set) var testPicks = "" {
        didSet {
            if isABTestRandom && SubscriptionManager.shared.hasActiveSubscription {
                GiftsPhotoService.shared.startFetching()
            }
        }
    }
    private(set) var testPicksAnime = "" {
        didSet {
            if isABTestRandom && SubscriptionManager.shared.hasActiveSubscription {
                GiftsPhotoService.shared.startFetching()
            }
        }
    }
    private(set) var baseServer = ""
    private(set) var testClipsCount = 35
    private(set) var testClips = ""
    private(set) var secondUserPrompt = ""
    
    private(set) var isWaiting24: Bool = false
    private(set) var isABTestRandom: Bool = false
    private(set) var isRemotePhoto: Bool = false
    private(set) var videoLoaded: Bool = false
    private(set) var canGotPremiumForDailyLogin: Bool = false
    private(set) var shouldSwitchMoods: Bool = false
    private(set) var needRequestReview: Bool = false
    private(set) var isYearSubActive: Bool = true
    private(set) var isForceReset: Bool = false

    private init() {}
    
    func fetchConfig(completion: ((Bool) -> Void)? = nil) {
        guard let primaryConfigURL else {
            self.fetchFallbackConfig(completion: completion)
            return
        }
        
        let request = URLRequest(url: primaryConfigURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, error == nil,
                  let remoteConfig = try? JSONDecoder().decode(APIModel.self, from: data) else {
                // Если основной конфиг отвалился — идём в фоллбек
                self.fetchFallbackConfig(completion: completion)
                return
            }

            DispatchQueue.main.async {
                self.processConfig(remoteConfig, completion: completion)
            }
        }.resume()
    }
    
    private func fetchFallbackConfig(completion: ((Bool) -> Void)?) {
        guard let fallbackConfigURL else {
            DispatchQueue.main.async {
                self.loadFromCacheOnly()
                completion?(false)
            }
            return
        }
        
        let request = URLRequest(url: fallbackConfigURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, error == nil,
                  let fallbackConfig = try? JSONDecoder().decode(APIModel.self, from: data) else {
                DispatchQueue.main.async {
                    self.loadFromCacheOnly()
                    completion?(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                // Отправляем репорт в Телеграм
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                let lang = Locale.preferredLanguages.first ?? "???"
                let alertMessage = "⚠️🚨 FALLBACK CONFIG TRIGGERED! 🚨⚠️\n\nОсновной конфиг улетел в ошибку! Работаем на резервном.\n\nVersion: \(currentVersion)\nLang: \(lang)"
                TGReportsManager.shared.sendErrorReport(messageText: alertMessage)
                AmplitudeManager.shared.logEvent(
                    name: "⚠️🚨 FALLBACK CONFIG TRIGGERED! 🚨⚠️",
                    properties: ["":""]
                )

                
                self.processConfig(fallbackConfig, completion: completion)
            }
        }.resume()
    }
    
    private func loadFromCacheOnly() {
        if let data = UserDefaults.standard.data(forKey: myDBKey),
           let cached = try? JSONDecoder().decode(APIModel.self, from: data) {
            self.setFrom(cached)
        }
    }
    
    private func processConfig(_ remoteConfig: APIModel, completion: ((Bool) -> Void)?) {
        var cachedConfig: APIModel? = nil
        if let data = UserDefaults.standard.data(forKey: myDBKey) {
            cachedConfig = try? JSONDecoder().decode(APIModel.self, from: data)
        }
        
        let cachedIsMode = cachedConfig?.isABTestRandom ?? false
        let remoteIsMode = remoteConfig.isABTestRandom
        let finalIsMode = remoteIsMode || cachedIsMode
        completion?(remoteConfig.isForceReset ? remoteIsMode : finalIsMode)
        
        mergeAndApply(remote: remoteConfig, cached: cachedConfig)
    }
    
    // MARK: - Core Logic (Merge Strategy)
    private func mergeAndApply(remote: APIModel, cached: APIModel?) {
        let mergedConfig: APIModel
        
        if remote.isForceReset {
            mergedConfig = remote
        } else {
            // 1. Logic for isTestB (Sticky True)
            let cachedIsTestB = cached?.isABTestRandom ?? false
            let remoteIsTestB = remote.isABTestRandom
            let finalIsTestB = cachedIsTestB || remoteIsTestB
            
            let cachedIsRemotePhoto = cached?.isRemotePhoto ?? false
            let remoteIsRemotePhoto = remote.isRemotePhoto
            let finalIsRemotePhoto = cachedIsRemotePhoto || remoteIsRemotePhoto
            
            // 2. Logic for additionalPhotos (Never become empty if was populated)
            let cachedPhotos = cached?.testPicks ?? ""
            let remotePhotos = remote.testPicks
            
            let finalAdditionalPhotos: String
            if !cachedPhotos.isEmpty && remotePhotos.isEmpty {
                finalAdditionalPhotos = cachedPhotos
            } else {
                finalAdditionalPhotos = remotePhotos
            }
            
            let cachedPhotosAnime = cached?.testPicksAnime ?? ""
            let remotePhotosAnime = remote.testPicksAnime
            let finalAdditionalPhotosAnime: String
            if !cachedPhotosAnime.isEmpty && remotePhotosAnime.isEmpty {
                finalAdditionalPhotosAnime = cachedPhotosAnime
            } else {
                finalAdditionalPhotosAnime = remotePhotosAnime
            }
            
            // 3. Logic for topicRST
            let cachedTopicRST = cached?.userPromptMain ?? ""
            let remoteTopicRST = remote.userPromptMain
            
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
            if let cachedVideos = cached?.testClips, !cachedVideos.isEmpty {
                finalAdditionalVideos = cachedVideos
            } else {
                finalAdditionalVideos = remote.testClips ?? ""
            }
            
            mergedConfig = APIModel(
                messagesDailyCount: remote.messagesDailyCount,
                messagesFirstOpenCount: remote.messagesFirstOpenCount,
                mainPhotoPath: remote.mainPhotoPath,
                secondPhotoPath: remote.secondPhotoPath,
                blondsVidCount: remote.blondsVidCount,
                BrunetsVidCount: remote.BrunetsVidCount,
                someHalfSafeKey: remote.someHalfSafeKey,
                userPromptMain: finalTopicRST,
                myMessageToUsers: remote.myMessageToUsers,
                testPicks: finalAdditionalPhotos,
                testPicksAnime: finalAdditionalPhotosAnime,
                baseServer: remote.baseServer,
                testClips: finalAdditionalVideos,
                testClipsCount: remote.testClipsCount,
                secondUserPrompt: remote.secondUserPrompt,
                configVersion: remote.configVersion,
                isABTestRandom: finalIsTestB,
                isRemotePhoto: finalIsRemotePhoto,
                isWaiting24: remote.isWaiting24,
                videoLoaded: remote.videoLoaded,
                canGotPremiumForDailyLogin: remote.canGotPremiumForDailyLogin,
                shouldSwitchMoods: remote.shouldSwitchMoods,
                needRequestReview: remote.needRequestReview,
                isYearSubActive: remote.isYearSubActive,
                isForceReset: remote.isForceReset
            )
        }
        
        setFrom(mergedConfig)
        cacheConfig(mergedConfig)
    }

    private func setFrom(_ config: APIModel) {
        self.isABTestRandom = config.isABTestRandom
        self.isRemotePhoto = config.isRemotePhoto
        self.isWaiting24 = config.isWaiting24
        self.videoLoaded = config.videoLoaded ?? false
        self.canGotPremiumForDailyLogin = config.canGotPremiumForDailyLogin ?? false
        self.shouldSwitchMoods = config.shouldSwitchMoods ?? false
        self.needRequestReview = config.needRequestReview ?? false
        self.isYearSubActive = config.isYearSubActive ?? true
        self.isForceReset = config.isForceReset
        self.messagesDailyCount = config.messagesDailyCount
        self.messagesFirstOpenCount = config.messagesFirstOpenCount
        self.blondsVidCount = config.blondsVidCount ?? 94
        self.BrunetsVidCount = config.BrunetsVidCount ?? 99
        self.mainPhotoPath = config.mainPhotoPath ?? ""
        self.secondPhotoPath = config.secondPhotoPath ?? ""
        self.someHalfSafeKey = config.someHalfSafeKey ?? ""
        self.userPromptMain = config.userPromptMain
        self.myMessageToUsers = config.myMessageToUsers
        self.testPicks = config.testPicks
        self.testPicksAnime = config.testPicksAnime
        self.baseServer = config.baseServer ?? ""
        self.testClipsCount = config.testClipsCount ?? 35
        self.testClips = config.testClips ?? ""
        self.secondUserPrompt = config.secondUserPrompt ?? ""
    }

    private func cacheConfig(_ config: APIModel) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: myDBKey)
        }
    }
}
