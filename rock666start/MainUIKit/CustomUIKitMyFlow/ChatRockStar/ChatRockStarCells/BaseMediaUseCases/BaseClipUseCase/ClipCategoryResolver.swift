import Foundation

final class ClipCategoryResolver: DynamicCategoryResolving {
    private let categoryGroupA: Set<String> = ["icon1", "icon2", "icon4", "icon5", "icon6", "icon27", "icon21", "icon23", "icon24"]
    private let categoryGroupB: Set<String> = ["icon3", "icon7", "icon8", "icon9", "icon10", "icon28", "icon26", "icon22", "icon25"]
    private let categoryGroupC: Set<String> = ["icon11", "icon12", "icon13", "icon14", "icon15", "icon16", "icon17", "icon18", "icon19", "icon20"]

    func evaluateCategory(for key: String) -> String {
        if categoryGroupA.contains(key) { return "blond" }
        if categoryGroupB.contains(key) { return "brunet" }
        if categoryGroupC.contains(key) { return "anime" }
        return "all"
    }
}
