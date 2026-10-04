import Foundation

final class AIRequestLimitManager {
    
    static let shared = AIRequestLimitManager()
    
    private let maxFreeRequests = 3
    private let countKey = "free_ai_requests_count"
    private let lastDateKey = "last_ai_request_date"
    
    private init() {}
    
    /// Проверяет, может ли пользователь сделать запрос (Премиум или осталось < 3 бесплатных)
    func canMakeRequest() -> Bool {
        if SubscriptionManager.shared.hasActiveSubscription {
            return true
        }
        
        resetCountIfNewDay()
        
        let currentCount = UserDefaults.standard.integer(forKey: countKey)
        return currentCount < maxFreeRequests
    }
    
    /// Вызывается при успешном отправлении запроса к ИИ
    func registerRequest() {
        guard !SubscriptionManager.shared.hasActiveSubscription else { return }
        
        resetCountIfNewDay()
        
        let currentCount = UserDefaults.standard.integer(forKey: countKey)
        UserDefaults.standard.set(currentCount + 1, forKey: countKey)
        UserDefaults.standard.set(Date(), forKey: lastDateKey)
    }
    
    /// Возвращает количество оставшихся бесплатных запросов на сегодня
    func remainingFreeRequests() -> Int {
        if SubscriptionManager.shared.hasActiveSubscription {
            return Int.max
        }
        
        resetCountIfNewDay()
        let currentCount = UserDefaults.standard.integer(forKey: countKey)
        return max(0, maxFreeRequests - currentCount)
    }
    
    // MARK: - Private Helpers
    
    /// Сбрасывает счётчик, если наступил новый календарный день
    private func resetCountIfNewDay() {
        guard let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date else {
            // Первый запуск — инициализируем дату
            UserDefaults.standard.set(Date(), forKey: lastDateKey)
            UserDefaults.standard.set(0, forKey: countKey)
            return
        }
        
        if !Calendar.current.isDateInToday(lastDate) {
            // День сменился — обнуляем счётчик и обновляем дату
            UserDefaults.standard.set(0, forKey: countKey)
            UserDefaults.standard.set(Date(), forKey: lastDateKey)
        }
    }
}
