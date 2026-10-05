import Foundation

struct ServiceDiagnosticDetails: Decodable {
    let internalError: GatewayErrorPayload?
    
    enum CodingKeys: String, CodingKey {
        case internalError = "error"
    }
    
    struct GatewayErrorPayload: Decodable {
        let text: String
        let statusNumericCode: Int
        let statusStringCode: String
        
        enum CodingKeys: String, CodingKey {
            case text = "message"
            case statusNumericCode = "code"
            case statusStringCode = "status"
        }
    }
}
