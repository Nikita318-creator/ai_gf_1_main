import UIKit

struct Profile {
    let id: Int
    let name: String
    let age: Int
    let bio: String
    let imageName: String
    let interests: [String]
}

class SwipeModeViewModel {
    private let defaults = UserDefaults.standard
    private let avatarsKey = "shuffledAvatars"
    private var avatars: [String] = []
    var profiles: [Profile] = []
    
    init() {
        loadAvatars()
        setProfiles()
    }
    
    func loadAvatars() {
        if let savedAvatars = defaults.array(forKey: avatarsKey) as? [String] {
            avatars = savedAvatars
        } else {
            let combined = MainHelper.shared.picIBlondDs +
                           MainHelper.shared.picIBrunetdDs +
                           MainHelper.shared.picAsionIDs
            avatars = combined.shuffled()
            defaults.set(avatars, forKey: avatarsKey)
        }
    }
    
    private func setProfiles() {
        guard avatars.count >= 64 else { return }

        profiles = (1...64).enumerated().map { index, number in
            Profile(
                id: index,
                name: "LoveChat.name\(number)".localize(),
                age: (19...26).randomElement() ?? 19,
                bio: "LoveChat.bio\(number)".localize(),
                imageName: avatars[index],
                interests: "LoveChat.interests\(number)".localizeInterests()
            )
        }
    }
    
    func resetAvatars() {
        // todo убрал так как создает баги со сменой аватара
//        let combined = MainHelper.shared.picIBlondDs +
//                       MainHelper.shared.picIBrunetdDs +
//                       MainHelper.shared.picAsionIDs
//        avatars = combined.shuffled()
//        defaults.set(avatars, forKey: avatarsKey)
    }
}

extension String {
    func localizeInterests() -> [String] {
        NSLocalizedString(self, comment: "").components(separatedBy: "|")
    }
}
