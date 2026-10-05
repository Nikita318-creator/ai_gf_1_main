import Foundation

// MARK: - Сервис синхронизации (DataSyncTransportDispatcher)

final class DataSyncTransportDispatcher {
    
    private let configProvider: RemoteConfigurationProviding
    private let urlSession: URLSession
    
    init(
        configProvider: RemoteConfigurationProviding = DefaultRemoteConfigurationProvider(),
        session: URLSession = .shared
    ) {
        self.configProvider = configProvider
        self.urlSession = session
    }
    
    //  вычисление HTTP заголовка
    private var headerSecretKey: String {
        let componentA = HttpHeaders.header
        let componentB = V1.v1
        let componentC = HostBase.host
        let componentD = PathBase.path
        return "\(componentA)_\(componentB)_\(componentC)_\(componentD)"
    }
    
    private var httpMethodPOST: String { String(["P", "O", "S", "T"]) }
    private var contentTypeHeader: String { String(["C", "o", "n", "t", "e", "n", "t", "-", "T", "y", "p", "e"]) }
    private var jsonMimeType: String { String(["a", "p", "p", "l", "i", "c", "a", "t", "i", "o", "n", "/", "j", "s", "o", "n"]) }
    private var secretHeaderKey: String { String(["X", "-", "A", "p", "p", "-", "S", "e", "c", "r", "e", "t"]) }

    func dispatchPayloadTransaction(
        messageContent: String,
        instructionContext: String,
        completion: @escaping (Result<String, NetworkTransferProtocolError>) -> Void
    ) {
        guard let url = URL(string: configProvider.endpointURLString) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethodPOST
        request.addValue(jsonMimeType, forHTTPHeaderField: contentTypeHeader)
        request.addValue(headerSecretKey, forHTTPHeaderField: secretHeaderKey)
        
        let payload = RemotePayloadPackage(payloadText: messageContent, contextInstruction: instructionContext)
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(.parsingPayloadFailed(error)))
            return
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                DispatchQueue.main.async {
                    completion(.failure(.quotaThrottled))
                }
                return
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.transportFailure(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.emptyStreamResponse))
                }
                return
            }
            
            self.processResponseData(data, completion: completion)
        }
        
        task.resume()
    }

    private func processResponseData(
        _ data: Data,
        completion: @escaping (Result<String, NetworkTransferProtocolError>) -> Void
    ) {
        do {
            let envelope = try JSONDecoder().decode(RemoteServiceEnvelope.self, from: data)
            
            if let content = envelope.contentBody, !content.isEmpty {
                DispatchQueue.main.async {
                    completion(.success(content))
                }
            } else if let errMessage = envelope.rawErrorMessage {
                DispatchQueue.main.async {
                    completion(.failure(.serverContractError(errMessage)))
                }
            } else if let detailsMessage = envelope.diagnosticDetails?.internalError?.text {
                DispatchQueue.main.async {
                    completion(.failure(.serverContractError(detailsMessage)))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(.emptyStreamResponse))
                }
            }
        } catch let parsingError {
            #if DEBUG
            if let rawString = String(data: data, encoding: .utf8) {
                print("⚠️ [SyncEngine] Raw payload: \(rawString)")
            }
            #endif
            DispatchQueue.main.async {
                completion(.failure(.parsingPayloadFailed(parsingError)))
            }
        }
    }
}
