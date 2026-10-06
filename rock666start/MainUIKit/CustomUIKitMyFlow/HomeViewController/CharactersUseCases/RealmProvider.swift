import Foundation
import RealmSwift
import UIKit

protocol RealmProviderProtocol {
    func provideRealmInstance() -> Realm?
}

final class DefaultRealmProvider: RealmProviderProtocol {
    private let targetConfiguration: Realm.Configuration

    init(configuration: Realm.Configuration) {
        self.targetConfiguration = configuration
        self.setupMemoryPressureHandler()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func provideRealmInstance() -> Realm? {
        do {
            return try Realm(configuration: targetConfiguration)
        } catch {
            var secondaryConfig = Realm.Configuration(inMemoryIdentifier: "CharactersFallbackCache")
            secondaryConfig.deleteRealmIfMigrationNeeded = true

            do {
                return try Realm(configuration: secondaryConfig)
            } catch {
                let emergencyToken = "UltraCharactersCache_\(UUID().uuidString)"
                var emergencyConfig = Realm.Configuration(inMemoryIdentifier: emergencyToken)
                emergencyConfig.deleteRealmIfMigrationNeeded = true

                do {
                    return try Realm(configuration: emergencyConfig)
                } catch {
                    return nil
                }
            }
        }
    }

    private func setupMemoryPressureHandler() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLowMemoryEvent),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleLowMemoryEvent() {
        let _ = try? Realm().invalidate()
    }
}
