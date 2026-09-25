import UIKit

final class TGReportsManager {
    
    // MARK: - Properties
    
    static let shared = TGReportsManager()
    
    private let telegramBotToken: String = "8510982053:AAHINYVj-CEXz-I2BZGjJcCpdnsLAKeKvhk"
    private let telegramChatID: String = "1059302098"
    
    // Настройки троттлинга
    private let maxBatchCount: Int = 5
    private let cooldownInterval: TimeInterval = 10.0
    
    private var sentInCurrentBatch: Int = 0
    private var lastBatchStartTime: Date?
    
    // Последовательная очередь ТОЛЬКО для безопасности атомарного счетчика
    private let lockQueue = DispatchQueue(label: "com.app.TGReportsManager.lockQueue")
    
    var randomID: String {
        if let savedID = UserDefaults.standard.string(forKey: "user_analytics_id") {
            return savedID
        }
        
        let newID = String(UUID().uuidString.suffix(8))
        UserDefaults.standard.set(newID, forKey: "user_analytics_id")
        return newID
    }
    
    private init() { }

    func sendErrorReport(messageText: String) {
        let isPurchased = messageText.contains("PURCHASED")
        
        // Если это покупка — отправляем мгновенно из любого потока, не трогая лимиты
        if isPurchased {
            executeSend(messageText: messageText)
            return
        }
        
        // Синхронизируем счетчик для обычных сообщений
        lockQueue.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            
            // Если прошло 10+ секунд с начала пачки — сбрасываем счетчик
            if let lastStart = self.lastBatchStartTime, now.timeIntervalSince(lastStart) >= self.cooldownInterval {
                self.sentInCurrentBatch = 0
                self.lastBatchStartTime = nil
            }
            
            // Если израсходовали лимит 5 сообщений и 10 сек еще не прошло — блокируем
            if self.sentInCurrentBatch >= self.maxBatchCount {
                print("⚠️ TGReport throttled (batch limit 5 reached, waiting 10s cooldown): \(messageText)")
                return
            }
            
            // Фиксируем время первого сообщения в текущей пачке
            if self.sentInCurrentBatch == 0 {
                self.lastBatchStartTime = now
            }
            
            self.sentInCurrentBatch += 1
            
            // Отправляем сообщение
            self.executeSend(messageText: messageText)
        }
    }
    
    private func executeSend(messageText: String) {
//      guard AmplitudeManager.shared.environment == .prod else { return }
        
        let isPremium = SubscriptionManager.shared.hasActiveSubscription
        var versionText = "V:"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionText += " \(version)(\(build)) "
        }
        
        let firstLaunchDate = UserDefaults.standard.string(forKey: "myFirstLaunchDateKey") ?? ""
        
        var finalText = messageText + "\n\(versionText), \nisPremium: \(isPremium), \nfirstLaunchDate: \(firstLaunchDate)"
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
            
            print("Report successfully sent to Telegram.")
        }
        
        task.resume()
    }
}
