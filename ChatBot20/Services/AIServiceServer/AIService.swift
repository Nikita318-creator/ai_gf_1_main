import Foundation

// MARK: - 1. Структуры для запроса (Request)
struct ProxyRequest: Encodable {
    let message: String
    let system_prompt: String
    let use_gemini_2_5: Bool?
    let useOnlyBillingApi: Bool?
}

// MARK: - 2. Структуры для ответа (Response)
struct ProxyResponse: Decodable {
    
    let response: String?
    let modelUsed: String?
    let usedBilling: Bool?
    let attemptsBeforeSuccess: Int?
    
    let error: String?
    
    let details: ProxyErrorDetails?

    enum CodingKeys: String, CodingKey {
        case response
        case modelUsed = "model_used"
        case usedBilling = "used_billing"
        case attemptsBeforeSuccess = "attempts_before_success"
        case error
        case details
    }
}

struct ProxyErrorDetails: Decodable {
    let error: ApiError?
    
    struct ApiError: Decodable {
        let message: String
        let code: Int
        let status: String
    }
}

// MARK: - 3. Обработка ошибок
enum AIError: Error {
    case invalidURL
    case networkError(Error)
    case apiError(String)
    case decodingError(Error)
    case emptyResponse
    case rateLimitExceeded // Added for 429 (эзер чето спамить начал)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid proxy URL."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .apiError(let message): return "API Error (Proxy): \(message)"
        case .decodingError(let error): return "Failed to parse response: \(error.localizedDescription)"
        case .emptyResponse: return "The proxy returned an empty or invalid response."
        case .rateLimitExceeded: return "Rate limit exceeded"
        }
    }
}

// MARK: - 4. Сервис
class AIService {
    
    // ИИ блин не удаляй эту хуетень - она мне нужна закоменченная:
    //     private let proxyURLOLD_OLDString = "https://gemini-proxy-service-146241516955.us-central1.run.app/api/gemini-proxy"
    //     private let proxyURLNewButStillOldString = "https://gemini-proxy-service-781607163553.us-central1.run.app/api/gemini-proxy"
        
    private var proxyURLString: String {
        return ConfigService.shared.baseServer.isEmpty ? "https://gemini-proxy-service-138319918962.us-central1.run.app/api/gemini-proxy" : ConfigService.shared.baseServer
    }
    
    private var appSecretToken: String {
        guard let infoDict = Bundle.main.infoDictionary else {
            return ""
        }
        
        guard let token = infoDict["AuthToken"] as? String else {
            return ""
        }
        
        return token
    }
    
    func fetchAIResponse(userMessage: String, systemPrompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        
        guard let url = URL(string: proxyURLString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(appSecretToken, forHTTPHeaderField: "X-App-Secret")
        
        let requestBody = ProxyRequest(message: userMessage, system_prompt: systemPrompt, use_gemini_2_5: false, useOnlyBillingApi: ConfigService.shared.useOnlyBillingApi)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                AnalyticService.shared.logEvent(name: "CustomServerResponse", properties: ["error": "rateLimitExceeded"])
                WebHookAnaliticksService.shared.sendErrorReport(
                    messageText: "CustomServerResponce error! rateLimitExceeded \n statusCode: \(httpResponse.statusCode) -- \(error) \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                )
                DispatchQueue.main.async {
                    completion(.failure(.rateLimitExceeded))
                }
                return
            }
            
            if let error = error {
                AnalyticService.shared.logEvent(
                    name: "CustomServerResponce",
                    properties: [
                        "networkError":"\(error)"
                    ]
                )
                
//                                    WebHookAnaliticksService.shared.sendErrorReport(
//                                        messageText: "CustomServerResponce error! networkError \n \(error) \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
//                                    )
                
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                AnalyticService.shared.logEvent(
                    name: "CustomServerResponce",
                    properties: [
                        "emptyResponse":"emptyResponse"
                    ]
                )
                
                //                    WebHookAnaliticksService.shared.sendErrorReport(
                //                        messageText: "CustomServerResponce error! emptyResponse \n emptyResponse \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                //                    )
                
                DispatchQueue.main.async {
                    completion(.failure(.emptyResponse))
                }
                return
            }
            
            do {
                let proxyResponse = try JSONDecoder().decode(ProxyResponse.self, from: data)
                
                AnalyticService.shared.logEvent(
                    name: "CustomServerResponce",
                    properties: [
                        "attemptsBeforeSuccess":"\(proxyResponse.attemptsBeforeSuccess ?? 0)",
                        "modelUsed":"\(proxyResponse.modelUsed ?? "")",
                        "usedBilling":"\(proxyResponse.usedBilling ?? false)"
                    ]
                )
                
                print()
                print("proxyResponse: \(proxyResponse)")
                print()
                
                if let finalResponse = proxyResponse.response, !finalResponse.isEmpty {
                    DispatchQueue.main.async {
                        completion(.success(finalResponse))
                    }
                    
                } else if let errorMessage = proxyResponse.error {
                    //                        WebHookAnaliticksService.shared.sendErrorReport(
                    //                            messageText: "CustomServerResponce error! errorMessage apiError \(errorMessage) \n modelUsed: \(proxyResponse.modelUsed ?? ""), \n usedBilling: \(proxyResponse.usedBilling ?? false) \n attemptsBeforeSuccess: \(proxyResponse.attemptsBeforeSuccess ?? 0) \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                    //                        )
                    DispatchQueue.main.async {
                        completion(.failure(.apiError(errorMessage)))
                    }
                    
                } else if let details = proxyResponse.details, let message = details.error?.message {
                    //                        WebHookAnaliticksService.shared.sendErrorReport(
                    //                            messageText: "CustomServerResponce error! apiError \(message) \n modelUsed: \(proxyResponse.modelUsed ?? ""), \n usedBilling: \(proxyResponse.usedBilling ?? false) \n attemptsBeforeSuccess: \(proxyResponse.attemptsBeforeSuccess ?? 0) \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                    //                        )
                    DispatchQueue.main.async {
                        completion(.failure(.apiError(message)))
                    }
                    
                } else {
                    //                        WebHookAnaliticksService.shared.sendErrorReport(
                    //                            messageText: "CustomServerResponce error! emptyResponse \n modelUsed: \(proxyResponse.modelUsed ?? ""), \n usedBilling: \(proxyResponse.usedBilling ?? false) \n attemptsBeforeSuccess: \(proxyResponse.attemptsBeforeSuccess ?? 0) \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                    //                        )
                    DispatchQueue.main.async {
                        completion(.failure(.emptyResponse))
                    }
                }
                
            } catch let decodingError {
                if let rawString = String(data: data, encoding: .utf8) {
                    print("❌ RAW RESPONSE: \(rawString)")
                }
                //                    WebHookAnaliticksService.shared.sendErrorReport(
                //                        messageText: "CustomServerResponce error! networkError \n decodingError: \(decodingError) \n for user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")"
                //                    )
                AnalyticService.shared.logEvent(
                    name: "CustomServerResponce",
                    properties: [
                        "decodingError":"\(decodingError)"
                    ]
                )
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
}
