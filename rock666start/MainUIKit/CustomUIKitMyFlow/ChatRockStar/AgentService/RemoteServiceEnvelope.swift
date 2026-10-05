import Foundation

struct RemoteServiceEnvelope: Decodable {
    let contentBody: String?
    let engineIdentifier: String?
    let billedFlag: Bool?
    let retryAttempts: Int?
    let rawErrorMessage: String?
    let diagnosticDetails: ServiceDiagnosticDetails?

    enum CodingKeys: String, CodingKey {
        case contentBody = "response"
        case engineIdentifier = "model_used"
        case billedFlag = "used_billing"
        case retryAttempts = "attempts_before_success"
        case rawErrorMessage = "error"
        case diagnosticDetails = "details"
    }
}
