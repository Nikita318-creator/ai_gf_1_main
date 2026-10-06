import Foundation

protocol RemoteMediaDownloading: AnyObject {
    func downloadPayload(from endpoint: String, completion: @escaping (Data?) -> Void)
}

protocol DynamicCategoryResolving: AnyObject {
    func evaluateCategory(for key: String) -> String
}

protocol ClipUseCaseContract: AnyObject {
    func getVideoData(for avatar: String, completion: @escaping (String?) -> Void)
}
