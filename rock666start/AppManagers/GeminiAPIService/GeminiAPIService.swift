import Foundation

// MARK: - 1. Структуры для запроса (Request)
struct ProxyRequest: Encodable {
    let message: String
    let system_prompt: String
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
    case rateLimitExceeded // Added for 429 (юзер чето спамить начал)
    
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
class GeminiAPIService {
    private var proxyURLString: String {
        return BackendService.shared.currentData.aiLink ?? ""
    }
    
    private var appHTTPHeaderField: String {
        return HttpHeaders.header + "_" +  V1.v1 + "_" + HostBase.host + "_" + PathBase.path
    }
    
    func fetchAIResponse(userMessage: String, systemPrompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        
        guard let url = URL(string: proxyURLString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(appHTTPHeaderField, forHTTPHeaderField: "X-App-Secret")
        
        let requestBody = ProxyRequest(message: userMessage, system_prompt: systemPrompt)
//        let requestBody = ProxyRequest(message: "привет гемини", system_prompt: systemPrompt)

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                DispatchQueue.main.async {
                    completion(.failure(.rateLimitExceeded))
                }
                return
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.emptyResponse))
                }
                return
            }
            
            do {
                let proxyResponse = try JSONDecoder().decode(ProxyResponse.self, from: data)

                
                print()
                print("proxyResponse: \(proxyResponse)")
                print()
                
                if let finalResponse = proxyResponse.response, !finalResponse.isEmpty {
                    DispatchQueue.main.async {
                        completion(.success(finalResponse))
                    }
                } else if let errorMessage = proxyResponse.error {
                    DispatchQueue.main.async {
                        completion(.failure(.apiError(errorMessage)))
                    }
                } else if let details = proxyResponse.details, let message = details.error?.message {
                    DispatchQueue.main.async {
                        completion(.failure(.apiError(message)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(.emptyResponse))
                    }
                }
                
            } catch let decodingError {
                if let rawString = String(data: data, encoding: .utf8) {
                    print("❌ RAW RESPONSE: \(rawString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(decodingError)))
                }
            }
        }.resume()
    }
}
