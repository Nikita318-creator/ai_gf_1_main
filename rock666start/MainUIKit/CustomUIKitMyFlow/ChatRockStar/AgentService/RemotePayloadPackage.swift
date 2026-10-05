import Foundation

// MARK: - DTO  (Payload Models)

struct RemotePayloadPackage: Encodable {
    let payloadText: String
    let contextInstruction: String

    enum CodingKeys: String, CodingKey {
        case payloadText = "message"
        case contextInstruction = "system_prompt"
    }
}
