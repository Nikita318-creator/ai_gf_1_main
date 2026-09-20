import Foundation

struct MyGFScreenData {
    let title: String
    let marketingText: String
    let imageName: String
    let questions: [MyGFQuestionModel]
}

struct MyGFQuestionModel {
    let id: String // Уникальный ID для сохранения выбора
    let title: String
    let options: [String] // Массив опций для выбора
    let allowMultipleSelection: Bool // Можно ли выбрать несколько
}


class CreateMyGFUseCase {
    static let shared = CreateMyGFUseCase()
    
    private var selections: [String: [String]] = [:]
    
    func saveSelection(questionId: String, options: [String]) {
        selections[questionId] = options
    }
    
    func getSelection(questionId: String) -> [String] {
        return selections[questionId] ?? []
    }
    
    func clearAll() {
        selections.removeAll()
    }
    
    func getFinalConfiguration() -> [String: Any] {
        return [
            "waifu_config": selections,
            "timestamp": Date().timeIntervalSince1970,
            "completed": true
        ]
    }
    
    func isSlideComplete(questions: [MyGFQuestionModel]) -> Bool {
        return questions.allSatisfy { question in
            !getSelection(questionId: question.id).isEmpty
        }
    }
}
