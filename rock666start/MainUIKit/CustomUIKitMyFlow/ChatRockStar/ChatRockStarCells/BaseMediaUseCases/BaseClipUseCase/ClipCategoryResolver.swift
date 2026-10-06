import Foundation

final class ClipCategoryResolver: DynamicCategoryResolving {
    private let categoryGroupA: Set<String> = ["mainAvatar1", "mainAvatar2", "mainAvatar4", "mainAvatar5", "mainAvatar6", "mainAvatar27", "mainAvatar21", "mainAvatar23", "mainAvatar24"]
    private let categoryGroupB: Set<String> = ["mainAvatar3", "mainAvatar7", "mainAvatar8", "mainAvatar9", "mainAvatar10", "mainAvatar28", "mainAvatar26", "mainAvatar22", "mainAvatar25"]
    private let categoryGroupC: Set<String> = ["mainAvatar11", "mainAvatar12", "mainAvatar13", "mainAvatar14", "mainAvatar15", "mainAvatar16", "mainAvatar17", "mainAvatar18", "mainAvatar19", "mainAvatar20"]

    func evaluateCategory(for key: String) -> String {
        if categoryGroupA.contains(key) { return "blond" }
        if categoryGroupB.contains(key) { return "brunet" }
        if categoryGroupC.contains(key) { return "anime" }
        return "all"
    }
}
