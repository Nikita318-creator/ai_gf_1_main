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
        let cached = loadFromCache()

        // 2. Если требуется обновление ИЛИ кэша нет — пытаемся запросить Realtime Database
        if isConnectedToNetwork {
            do {
                let freshData = try await fetchFromRealtimeDatabase()
                saveToCache(freshData)
                self.currentData = freshData
                print("⚠️ [BackendService] успех: \(freshData)")
                return freshData
            } catch {
                print("⚠️ [BackendService] Ошибка загрузки с RTDB: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ [BackendService] Нет подключения к интернету.")
        }

        // 3. Fallback: если произошла ошибка сети/RTDB или нет интернета,
        // отдаем кэш, даже если `isForceReset == true`
        if let cachedData = cached {
            print("ℹ️ [BackendService] Использование кэша как fallback.")
            self.currentData = cachedData
            return cachedData
        }

        // 4. Если нет ни сети, ни кэша — отдаем дефолтные значения
        print("⚠️ [BackendService] Кэш пуст, сеть недоступна. Возврат дефолтных значений.")
        self.currentData = .default
        return .default
    }

    // MARK: - Firebase Realtime Database Fetching

    private func fetchFromRealtimeDatabase() async throws -> BaseDataModel {
        // Укажи свой путь в RTDB (например, root -> config -> baseData)
        let snapshot = try await ref.child("config").child("baseData").getData()
        
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
            mainPhotoPath: "",
            secondPhotoPath: "",
            someHalfSafeKey: "",
            userPromptMain: "",
            myMessageToUsers: "",
            testPicks: "",
            testPicksAnime: "",
            geminiAPILink: "",
            testClips: "",
            secondUserPrompt: "",
            isABTestRandom: false,
            isForceReset: false
        )
    }
}

struct BaseDataModel: Codable {
    let mainPhotoPath: String
    let secondPhotoPath: String
    let someHalfSafeKey: String
    let userPromptMain: String
    let myMessageToUsers: String
    let testPicks: String
    let testPicksAnime: String
    let geminiAPILink: String
    let testClips: String
    let secondUserPrompt: String
    let isABTestRandom: Bool
    let isForceReset: Bool
}
