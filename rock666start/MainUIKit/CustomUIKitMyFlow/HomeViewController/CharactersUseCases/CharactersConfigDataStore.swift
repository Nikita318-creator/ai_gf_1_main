import Foundation
import RealmSwift

final class CharactersConfigDataStore: CharactersConfigDataStoreProtocol {
    private let realmProvider: RealmProviderProtocol

    init(realmProvider: RealmProviderProtocol) {
        self.realmProvider = realmProvider
    }

    func storeConfiguration(_ config: CharactersDataModel) {
        guard let activeRealm = realmProvider.provideRealmInstance() else { return }

        let identifier = config.id ?? UUID().uuidString
        var preparedConfig = config
        preparedConfig.id = identifier
        let entityObject = CharactersObject(id: identifier, config: preparedConfig)

        do {
            try activeRealm.write {
                activeRealm.add(entityObject, update: .modified)
            }
        } catch {
            print("Failed add config transaction: \(error)")
        }
    }

    func modifyConfiguration(id: String, config: CharactersDataModel) {
        guard let activeRealm = realmProvider.provideRealmInstance(),
              let targetEntity = activeRealm.object(ofType: CharactersObject.self, forPrimaryKey: id) else { return }

        do {
            try activeRealm.write {
                targetEntity.name = config.name
                targetEntity.baseInfo = config.baseInfo
                targetEntity.dateOfUpdation = Date()
            }
        } catch {
            print("Failed update config transaction: \(error)")
        }
    }

    func purgeConfiguration(id: String) {
        guard let activeRealm = realmProvider.provideRealmInstance(),
              let targetEntity = activeRealm.object(ofType: CharactersObject.self, forPrimaryKey: id) else { return }

        do {
            try activeRealm.write {
                activeRealm.delete(targetEntity)
            }
        } catch {
            print("Failed delete config transaction: \(error)")
        }
    }

    func retrieveAllConfigurations() -> [CharactersDataModel] {
        guard let activeRealm = realmProvider.provideRealmInstance() else { return [] }

        let retrievedEntities = activeRealm.objects(CharactersObject.self)
            .sorted(byKeyPath: "dateOfUpdation", ascending: false)

        return retrievedEntities.map { $0.toAssistantConfig() }
    }

    func retrieveConfiguration(id: String) -> CharactersDataModel? {
        guard let activeRealm = realmProvider.provideRealmInstance() else { return nil }
        return activeRealm.object(ofType: CharactersObject.self, forPrimaryKey: id)?.toAssistantConfig()
    }
}
