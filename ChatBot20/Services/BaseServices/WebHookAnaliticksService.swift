import UIKit

final class WebHookAnaliticksService {
    
    // MARK: - Properties
    
    static let shared = WebHookAnaliticksService()
    
    private let telegramBotToken: String
    private let telegramChatID: String
    var randomID: String // one per user-session
    
    private init() {
        telegramBotToken = "8166651042:AAH4PGznpoauA7TWIXga2VWgQHgw9cIsXg0"
        telegramChatID = "1059302098"
        randomID = UUID().uuidString
    }

    func sendErrorReport(messageText: String) {
        guard AnalyticService.shared.environment == .prod else { return }
        
        let isPremium = IAPService.shared.hasActiveSubscription
        var versionText = "V:"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionText += " \(version)(\(build)) "
        }
        
        let firstLaunchDate: String
        if let firstLaunch = UserDefaults.standard.string(forKey: "firstLaunchDate") {
            firstLaunchDate = firstLaunch
        } else {
            firstLaunchDate = ""
        }
        
        var finalText: String

        finalText = messageText + "\n\(versionText), \nisPremium: \(isPremium), \nfirstLaunchDate: \(firstLaunchDate)"

        finalText = finalText.replacingOccurrences(of: "_", with: "-")

        let parameters: [String: Any] = [
            "chat_id": telegramChatID,
            "text": finalText,
            "parse_mode": "Markdown"
        ]

        let urlString = "https://api.telegram.org/bot\(telegramBotToken)/sendMessage"
        guard let telegramURL = URL(string: urlString) else {
            print("Invalid Telegram API URL.")
            return
        }

        var request = URLRequest(url: telegramURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode request body: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, taskError in
            if let taskError = taskError {
                print("Error sending report to Telegram: \(taskError.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Telegram API request failed with unexpected status code.")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Telegram API response: \(responseString)")
                }
                return
            }
            
            print("Error report successfully sent to Telegram.")
        }
        
        task.resume()
    }
}
