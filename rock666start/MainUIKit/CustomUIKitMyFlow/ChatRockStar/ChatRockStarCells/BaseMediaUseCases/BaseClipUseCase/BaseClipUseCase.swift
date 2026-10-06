import Foundation

final class BaseClipUseCase: ClipUseCaseContract {
    static let shared = BaseClipUseCase()

    private let cacheStorage: CacheDataPersisting
    private let downloader: RemoteMediaDownloading
    private let categoryResolver: DynamicCategoryResolving

    private let collectionLight = (1...94).map {
        BackendService.shared.currentData.secondString + BackendService.shared.currentData.videoWhiteTail + "\($0).mp4"
    }

    private let collectionDark = (1...99).map {
        BackendService.shared.currentData.secondString + BackendService.shared.currentData.videoBlackTail + "\($0).mp4"
    }

    private let collectionAnime = (1...164).map {
        BackendService.shared.currentData.mainString + BackendService.shared.currentData.videoAnimTail + "\($0).mp4"
    }

    private var combinedCollection: [String] {
        collectionLight + collectionDark
    }

    private var sessionPoolMap: [String: [String]] = [:]

    init(
        cacheStorage: CacheDataPersisting = BaseClipManager.shared,
        downloader: RemoteMediaDownloading = ClipNetworkDownloader(),
        categoryResolver: DynamicCategoryResolving = ClipCategoryResolver()
    ) {
        self.cacheStorage = cacheStorage
        self.downloader = downloader
        self.categoryResolver = categoryResolver
        resetSessionState()
    }

    private func resetSessionState() {
        sessionPoolMap["blond"] = collectionLight.shuffled()
        sessionPoolMap["brunet"] = collectionDark.shuffled()
        sessionPoolMap["anime"] = collectionAnime.shuffled()
        sessionPoolMap["all"] = combinedCollection.shuffled()
    }

    func getVideoData(for avatar: String, completion: @escaping (String?) -> Void) {
        let selectedURL = selectMediaURL(for: avatar)

        guard let resourceName = extractFileName(from: selectedURL) else {
            completion(nil)
            return
        }

        if cacheStorage.verifyPresence(entityIdentifier: resourceName) {
            completion(resourceName)
            return
        }

        downloader.downloadPayload(from: selectedURL) { [weak self] rawData in
            guard let downloadedData = rawData else {
                completion(nil)
                return
            }

            self?.cacheStorage.storeMediaResource(
                sourceURL: selectedURL,
                entityIdentifier: resourceName,
                rawPayload: downloadedData
            )
            completion(resourceName)
        }
    }

    private func selectMediaURL(for avatar: String) -> String {
        let categoryKey = categoryResolver.evaluateCategory(for: avatar)

        if let list = sessionPoolMap[categoryKey], !list.isEmpty {
            return sessionPoolMap[categoryKey]!.removeLast()
        } else {
            return combinedCollection.randomElement() ?? ""
        }
    }

    private func extractFileName(from urlString: String) -> String? {
        URL(string: urlString)?
            .deletingPathExtension()
            .lastPathComponent
    }
}
