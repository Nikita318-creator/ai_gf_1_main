import Foundation
import FirebaseDatabase
import Network

final class BackendService {
    static let shared = BackendService()
    
    // Ссылка на Realtime Database
    private let ref = Database.database().reference()
    private let cacheKey = "cached_base_data_model"
    private let monitor = NWPathMonitor()
    private var isConnectedToNetwork: Bool = true

    // Default fallback values
    var currentData: BaseDataModel = .default

    private init() {
        startNetworkMonitoring()
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnectedToNetwork = path.status == .satisfied
        }
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        monitor.start(queue: queue)
    }

    /// Главная функция получения данных
    func fetchBaseData() async -> BaseDataModel {
        // 1. Сразу проверяем и подтягиваем кэш
        if let cachedData = loadFromCache() {
            self.currentData = cachedData
            print("ℹ️ [BackendService] Сразу применили данные из кэша.")
        }

        // 2. Идем в сетевой запрос, если есть интернет
        if isConnectedToNetwork {
            do {
                let freshData = try await fetchFromRealtimeDatabase()
                
                // Если пришел флаг сброса (reset/force update)
                if freshData.isExpectReset {
                    print("⚠️ [BackendService] Получен isExpectReset = true. Обновляем данные.")
                    saveToCache(freshData)
                    self.currentData = freshData
                    return freshData
                } else {
                    // Если сброс не нужен — сохраняем поведение (оставляем текущие данные/кэш)
                    print("ℹ️ [BackendService] isExpectReset = false, оставляем текущий кэш.")
                    return self.currentData
                }
                
            } catch {
                print("⚠️ [BackendService] Ошибка загрузки с RTDB: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ [BackendService] Нет подключения к интернету.")
        }

        // 3. Fallback: если кэша не было вообще и сеть упала — возвращаем default
        return self.currentData
    }

    // MARK: - Firebase Realtime Database Fetching

    private func fetchFromRealtimeDatabase() async throws -> BaseDataModel {
        // Укажи свой путь в RTDB (например, root -> config -> baseData)
        let snapshot = try await ref.child("config").child("myData1").getData()
        
        guard snapshot.exists(), let dict = snapshot.value as? [String: Any] else {
            throw NSError(
                domain: "BackendService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Данные в RTDB отсутствуют или имеют неверный формат"]
            )
        }
        
        // Преобразуем Dictionary из RTDB в Data для работы Decodable
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        let model = try JSONDecoder().decode(BaseDataModel.self, from: jsonData)
        
        return model
    }

    // MARK: - Cache Handling (UserDefaults)

    private func saveToCache(_ model: BaseDataModel) {
        guard let encoded = try? JSONEncoder().encode(model) else { return }
        UserDefaults.standard.set(encoded, forKey: cacheKey)
    }

    private func loadFromCache() -> BaseDataModel? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(BaseDataModel.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Default Values Extension

extension BaseDataModel {
    static var `default`: BaseDataModel {
        BaseDataModel(
            isLimitesSpent: true,
            isExpectReset: false,
            aiLink: "",
            mainString: "",
            secondString: "",
            audioToken: "",
            aiText: "",
            aiTextM: "",
            aiTextE: "",
            aiTextA: "",
            aiTextToUser: "",
            picTail: "",
            videoWhiteTail: "",
            videoBlackTail: "",
            videoAnimTail: "",
        )
    }
}

struct BaseDataModel: Codable {
    let isLimitesSpent: Bool
    let isExpectReset: Bool
    let aiLink: String
    let mainString: String
    let secondString: String
    let audioToken: String
    let aiText: String
    let aiTextM: String
    let aiTextE: String
    let aiTextA: String
    let aiTextToUser: String
    let picTail: String
    let videoWhiteTail: String
    let videoBlackTail: String
    let videoAnimTail: String
}
