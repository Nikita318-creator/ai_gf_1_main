import UIKit

class UnreadMessagesService {
    static let shared = UnreadMessagesService()

    private let lastCheckedKey = "UnreadMessagesService.lastChecked"
    private let intervalHours: TimeInterval = 24 * 60 * 60
    private let defaults = UserDefaults.standard
    
    var currentFilter: ChatFilterType? = nil
    var lasChatUnreadID: String? = nil
    
    private init() {}

    func needAddUnreadMessage() -> Bool {
        scheduleInactivityNotification()

        let now = Date()

        if let lastDate = defaults.object(forKey: lastCheckedKey) as? Date {
            let interval = now.timeIntervalSince(lastDate)
            defaults.set(now, forKey: lastCheckedKey)
            return interval >= intervalHours
        } else {
            defaults.set(now, forKey: lastCheckedKey)
            return false
        }
    }
    
    private func scheduleInactivityNotification() {
        // 1. Удаляем все предыдущие уведомления
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["inactivity_notification"])

        let bodyMessageKey = "unreadMessage.Push.Message" + ((1...12).map { String($0) }.randomElement() ?? "2")
        // 2. Создаем новое через 24 часа
        let content = UNMutableNotificationContent()
        content.title = "unreadMessage.Push.Title".localize()
        content.body = bodyMessageKey.localize()
        content.sound = .default
        content.badge = NSNumber(value: 1) // ← бейдж на иконку

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalHours, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity_notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
