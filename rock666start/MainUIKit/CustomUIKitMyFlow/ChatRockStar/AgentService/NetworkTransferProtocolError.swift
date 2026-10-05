import Foundation

// MARK: - Нейтральные ошибки и протоколы

enum NetworkTransferProtocolError: Error {
    case invalidEndpoint
    case transportFailure(Error)
    case serverContractError(String)
    case parsingPayloadFailed(Error)
    case emptyStreamResponse
    case quotaThrottled
    
    var localizedDescription: String {
        switch self {
        case .invalidEndpoint: return "Resource endpoint unreachable."
        case .transportFailure(let error): return "Transport error: \(error.localizedDescription)"
        case .serverContractError(let message): return "Contract mismatch: \(message)"
        case .parsingPayloadFailed(let error): return "Payload parsing error: \(error.localizedDescription)"
        case .emptyStreamResponse: return "Empty response payload."
        case .quotaThrottled: return "Rate limit throttled."
        }
    }
}
