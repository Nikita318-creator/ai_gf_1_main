import Foundation

struct QuizQuestionModel {
    let questionText: String
    let options: [String]
    let correctIndex: Int
}

final class QuizViewModel {
    let topic: QuizTopic
    private(set) var questions: [QuizQuestionModel] = []
    private(set) var score: Int = 0
    private(set) var currentQuestionIndex: Int = 0
    
    init(topic: QuizTopic) {
        self.topic = topic
        loadQuestions()
    }
    
    var totalQuestions: Int {
        return questions.count
    }
    
    var currentQuestion: QuizQuestionModel? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    private func loadQuestions() {
        // Боевой массив вопросов для первого топика (Fashion Designer)
        if topic.title == "Fashion Designer" {
            questions = [
                QuizQuestionModel(
                    questionText: "What is a 'toile' in fashion design?",
                    options: [
                        "A test garment made from inexpensive fabric to check fit",
                        "A specialized tool for measuring sleeve length",
                        "A type of high-gloss leather finish",
                        "A digital pattern-making software"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What does 'haute couture' literally translate to from French?",
                    options: [
                        "Modern tailoring",
                        "High sewing / high dressmaking",
                        "Luxury street style",
                        "Exclusive handmade shoes"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the primary purpose of a fashion mood board?",
                    options: [
                        "To track production costs and inventory",
                        "To visualize design concepts, colors, and inspiration",
                        "To measure body proportions for tailoring",
                        "To display final pricing tags for retail"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What does a 'bias cut' mean in garment construction?",
                    options: [
                        "Cutting fabric at a 45-degree angle to the grain for drape",
                        "Trimming raw edges with a zigzag stitch",
                        "Stitching dual layers for extra warmth",
                        "Using asymmetrical hems for dramatic effect"
                    ],
                    correctIndex: 0
                ),
                QuizQuestionModel(
                    questionText: "What is 'grading' in apparel manufacturing?",
                    options: [
                        "Rating fabric quality from A to Z",
                        "Scaling a master pattern into various sizes",
                        "Inspecting stitching defects on the assembly line",
                        "Categorizing designer collections by season"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which iconic designer popularized the 'Little Black Dress' in the 1920s?",
                    options: ["Christian Dior", "Giorgio Armani", "Coco Chanel", "Yves Saint Laurent"],
                    correctIndex: 2
                ),
                QuizQuestionModel(
                    questionText: "What is a 'lookbook' used for in the fashion industry?",
                    options: [
                        "A portfolio of makeup looks for runway models",
                        "A promotional collection of photos showcasing outfits to buyers",
                        "A textbook on historical costume design",
                        "A catalog of sewing machine manuals"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "Which natural fiber comes from the cocoons of silkworm larvae?",
                    options: ["Linen", "Silk", "Cashmere", "Hemp"],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is the function of a basting stitch?",
                    options: [
                        "Permanent heavy-duty reinforcement along seams",
                        "Temporary stitching to hold pieces together before final sewing",
                        "Decorative embroidery on denim cuffs",
                        "Securing buttons and heavy zippers"
                    ],
                    correctIndex: 1
                ),
                QuizQuestionModel(
                    questionText: "What is 'fast fashion' primarily characterized by?",
                    options: [
                        "Handmade bespoke garments crafted over months",
                        "Rapid translation of runway trends into mass-market retail",
                        "Using exclusively organic, biodegradable textiles",
                        "High-priced luxury collections released weekly"
                    ],
                    correctIndex: 1
                )
            ]
        } else {
            // Заглушка-рандомизатор для остальных топиков (если понадобятся)
            questions = [
                QuizQuestionModel(questionText: "What is the core principle when working as a \(topic.title)?", options: ["Consistency and Practice", "Pure Luck", "Ignoring Feedback", "Working 2 hours a week"], correctIndex: 0),
                QuizQuestionModel(questionText: "Which tool or technique is most commonly used first?", options: ["Advanced Automation", "Basic Fundamentals", "Random Guessing", "Complex Frameworks"], correctIndex: 1),
                QuizQuestionModel(questionText: "How do professionals handle critical blockers?", options: ["Panic and Quit", "Analyze, Debug, and Iterate", "Blame the client", "Delete everything"], correctIndex: 1),
                QuizQuestionModel(questionText: "What defines a true expert in this field?", options: ["Years of continuous learning", "Having a fancy title", "Expensive equipment", "Natural born talent only"], correctIndex: 0),
                QuizQuestionModel(questionText: "Which metric best shows your daily progress?", options: ["Quality of output & skill growth", "Number of coffee cups", "Hours spent sleeping", "Social media followers"], correctIndex: 0),
                QuizQuestionModel(questionText: "What is a common beginner mistake to avoid?", options: ["Skipping basics for shortcuts", "Asking questions", "Practicing daily", "Taking notes"], correctIndex: 0),
                QuizQuestionModel(questionText: "How should you approach complex tasks?", options: ["Break them down into smaller steps", "Do them all at midnight", "Hope they resolve themselves", "Ignore them"], correctIndex: 0),
                QuizQuestionModel(questionText: "What is the best way to receive constructive feedback?", options: ["Take it and adapt", "Get defensive", "Ignore it completely", "Argue back"], correctIndex: 0),
                QuizQuestionModel(questionText: "What role does creativity play here?", options: ["Crucial for innovative solutions", "None at all", "Only on weekends", "Only for marketing"], correctIndex: 0),
                QuizQuestionModel(questionText: "What is the ultimate goal of mastering this craft?", options: ["Creating value and mastering skills", "Making fast money with zero effort", "Impressing friends on Instagram", "Passing time"], correctIndex: 0)
            ].shuffled()
        }
    }
    
    func validateAnswer(selectedIdx: Int) -> Bool {
        guard let question = currentQuestion else { return false }
        let isCorrect = (selectedIdx == question.correctIndex)
        if isCorrect {
            score += 1
        }
        return isCorrect
    }
    
    func nextQuestion() -> Bool {
        currentQuestionIndex += 1
        return currentQuestionIndex < questions.count
    }
}
