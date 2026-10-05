import Foundation

// Алиас для обратной совместимости, если где-то остался
typealias MyCustomErr = NetworkTransferProtocolError

protocol RemoteConfigurationProviding {
    var endpointURLString: String { get }
}

final class DefaultRemoteConfigurationProvider: RemoteConfigurationProviding {
    var endpointURLString: String {
        return BackendService.shared.currentData.aiLink ?? ""
    }
}
