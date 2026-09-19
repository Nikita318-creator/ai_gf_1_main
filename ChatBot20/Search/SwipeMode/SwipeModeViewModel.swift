import UIKit

struct Profile: Codable {
    let id: Int
    let name: String
    let age: Int
    let bio: String
    let imageName: String
    let interests: [String]
}

class SwipeModeViewModel {
    static let avatarsA = [
        "swipeModeAvatar1",
        "swipeModeAvatar2",
        "swipeModeAvatar3",
        "swipeModeAvatar4",
        "swipeModeAvatar5",
        "swipeModeAvatar6",
        "swipeModeAvatar9",
        "swipeModeAvatar10",
        "swipeModeAvatar15",
        "swipeModeAvatar17",
        "swipeModeAvatar18",
        "swipeModeAvatar19",
        "swipeModeAvatar20",
        "swipeModeAvatar21",
        "swipeModeAvatar22",
        "swipeModeAvatar23",
        "swipeModeAvatar24",
        "swipeModeAvatar25",
        "swipeModeAvatar26",
        "swipeModeAvatar27",
        "swipeModeAvatar28",
        "swipeModeAvatar29",
        "swipeModeAvatar30",
        "swipeModeAvatar35",
        "swipeModeAvatar36",
        "swipeModeAvatar37",
        "swipeModeAvatar42"
    ]
    
    private var avatars: [String] = []
    var profiles: [Profile] = []
    
    init() {
        loadAvatars()
        setProfiles()
    }
    
    func loadAvatars() {
        let combined: [String] = ConfigService.shared.isTestB ? (1...87).map { "swipeModeAvatar\($0)" } : SwipeModeViewModel.avatarsA
        avatars = combined
    }
    
    private func setProfiles() {
        let maxN = avatars.count
        profiles = (1...maxN).enumerated().map { index, number in
            Profile(
                id: index,
                name: "swipeModeName\(number)".localize(),
                age: (19...26).randomElement() ?? 19,
                bio: "swipeModeBio\(number)".localize(),
                imageName: avatars[index],
                interests: "swipeModeInterests\(number)".localizeInterests()
            )
        }.shuffled()
    }
}

extension String {
    func localizeInterests() -> [String] {
        NSLocalizedString(self, comment: "").components(separatedBy: "|")
    }
}
