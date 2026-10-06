import Foundation

final class CharactersUseCase {
    private let configStore: CharactersConfigDataStoreProtocol

    init(configStore: CharactersConfigDataStoreProtocol = CharactersConfigDataStore(
        realmProvider: DefaultRealmProvider(configuration: CharactersSchemaMigrationFactory.buildConfiguration())
    )) {
        self.configStore = configStore
    }

    func addConfig(_ config: CharactersDataModel) {
        configStore.storeConfiguration(config)
    }

    func updateConfig(id: String, config: CharactersDataModel) {
        configStore.modifyConfiguration(id: id, config: config)
    }

    func deleteConfig(id: String) {
        configStore.purgeConfiguration(id: id)
    }

    func getAllConfigs() -> [CharactersDataModel] {
        return configStore.retrieveAllConfigurations()
    }

    func getConfig(id: String) -> CharactersDataModel? {
        return configStore.retrieveConfiguration(id: id)
    }
}
