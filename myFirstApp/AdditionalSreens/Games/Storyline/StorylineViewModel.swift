import Foundation

struct StoryOption {
    let text: String
    let nextPageIndex: Int
}

struct StoryPage {
    let imageName: String
    let narrationText: String
    let questionText: String
    let options: [StoryOption]
}

struct Storyline {
    let title: String
    let pages: [StoryPage]
}

class StorylineViewModel {
    
    var stories: [Storyline] = []
    
    init() {
        setupStories()
    }
    
    private func setupStories() {
        let maidPages: [StoryPage] = [
            // 0: Вход
            StoryPage(imageName: "novel1_1", narrationText: "NovelMaidContentZero".localize(), questionText: "NovelMaidPromptZero".localize(), options: [
                StoryOption(text: "NovelMaidActionZeroA".localize(), nextPageIndex: 1),
                StoryOption(text: "NovelMaidActionZeroB".localize(), nextPageIndex: 2)
            ]),
            // 1 & 2: Разветвление
            StoryPage(imageName: "novel1_2", narrationText: "NovelMaidContentOne".localize(), questionText: "NovelMaidPromptOne".localize(), options: [
                StoryOption(text: "NovelMaidActionOneA".localize(), nextPageIndex: 3),
                StoryOption(text: "NovelMaidActionOneB".localize(), nextPageIndex: 4)
            ]),
            StoryPage(imageName: "novel1_2", narrationText: "NovelMaidContentTwo".localize(), questionText: "NovelMaidPromptTwo".localize(), options: [
                StoryOption(text: "NovelMaidActionTwoA".localize(), nextPageIndex: 3),
                StoryOption(text: "NovelMaidActionTwoB".localize(), nextPageIndex: 4)
            ]),
            // 3 & 4: Схождение
            StoryPage(imageName: "novel1_3", narrationText: "NovelMaidContentThree".localize(), questionText: "NovelMaidPromptThree".localize(), options: [
                StoryOption(text: "NovelMaidActionThreeA".localize(), nextPageIndex: 5),
                StoryOption(text: "NovelMaidActionThreeB".localize(), nextPageIndex: 6)
            ]),
            StoryPage(imageName: "novel1_3", narrationText: "NovelMaidContentFour".localize(), questionText: "NovelMaidPromptFour".localize(), options: [
                StoryOption(text: "NovelMaidActionFourA".localize(), nextPageIndex: 5),
                StoryOption(text: "NovelMaidActionFourB".localize(), nextPageIndex: 6)
            ]),
            // 5 & 6: Развитие
            StoryPage(imageName: "novel1_4", narrationText: "NovelMaidContentFive".localize(), questionText: "NovelMaidPromptFive".localize(), options: [
                StoryOption(text: "NovelMaidActionFiveA".localize(), nextPageIndex: 7),
                StoryOption(text: "NovelMaidActionFiveB".localize(), nextPageIndex: 8)
            ]),
            StoryPage(imageName: "novel1_4", narrationText: "NovelMaidContentSix".localize(), questionText: "NovelMaidPromptSix".localize(), options: [
                StoryOption(text: "NovelMaidActionSixA".localize(), nextPageIndex: 7),
                StoryOption(text: "NovelMaidActionSixB".localize(), nextPageIndex: 8)
            ]),
            // 7 & 8: Схождение
            StoryPage(imageName: "novel1_5", narrationText: "NovelMaidContentSeven".localize(), questionText: "NovelMaidPromptSeven".localize(), options: [
                StoryOption(text: "NovelMaidActionSevenA".localize(), nextPageIndex: 9),
                StoryOption(text: "NovelMaidActionSevenB".localize(), nextPageIndex: 10)
            ]),
            StoryPage(imageName: "novel1_5", narrationText: "NovelMaidContentEight".localize(), questionText: "NovelMaidPromptEight".localize(), options: [
                StoryOption(text: "NovelMaidActionEightA".localize(), nextPageIndex: 9),
                StoryOption(text: "NovelMaidActionEightB".localize(), nextPageIndex: 10)
            ]),
            // 9 & 10: Поиск улик
            StoryPage(imageName: "novel1_6", narrationText: "NovelMaidContentNine".localize(), questionText: "NovelMaidPromptNine".localize(), options: [
                StoryOption(text: "NovelMaidActionNineA".localize(), nextPageIndex: 11),
                StoryOption(text: "NovelMaidActionNineB".localize(), nextPageIndex: 12)
            ]),
            StoryPage(imageName: "novel1_6", narrationText: "NovelMaidContentTen".localize(), questionText: "NovelMaidPromptTen".localize(), options: [
                StoryOption(text: "NovelMaidActionTenA".localize(), nextPageIndex: 11),
                StoryOption(text: "NovelMaidActionTenB".localize(), nextPageIndex: 12)
            ]),
            // 11 & 12: Напряжение
            StoryPage(imageName: "novel1_7", narrationText: "NovelMaidContentEleven".localize(), questionText: "NovelMaidPromptEleven".localize(), options: [
                StoryOption(text: "NovelMaidActionElevenA".localize(), nextPageIndex: 13),
                StoryOption(text: "NovelMaidActionElevenB".localize(), nextPageIndex: 14)
            ]),
            StoryPage(imageName: "novel1_7", narrationText: "NovelMaidContentTwelve".localize(), questionText: "NovelMaidPromptTwelve".localize(), options: [
                StoryOption(text: "NovelMaidActionTwelveA".localize(), nextPageIndex: 13),
                StoryOption(text: "NovelMaidActionTwelveB".localize(), nextPageIndex: 14)
            ]),
            // 13 & 14: В шкафу
            StoryPage(imageName: "novel1_8", narrationText: "NovelMaidContentThirteen".localize(), questionText: "NovelMaidPromptThirteen".localize(), options: [
                StoryOption(text: "NovelMaidActionThirteenA".localize(), nextPageIndex: 15),
                StoryOption(text: "NovelMaidActionThirteenB".localize(), nextPageIndex: 16)
            ]),
            StoryPage(imageName: "novel1_8", narrationText: "NovelMaidContentFourteen".localize(), questionText: "NovelMaidPromptFourteen".localize(), options: [
                StoryOption(text: "NovelMaidActionFourteenA".localize(), nextPageIndex: 15),
                StoryOption(text: "NovelMaidActionFourteenB".localize(), nextPageIndex: 16)
            ]),
            // 15 & 16: Откровенность
            StoryPage(imageName: "novel1_9", narrationText: "NovelMaidContentFifteen".localize(), questionText: "NovelMaidPromptFifteen".localize(), options: [
                StoryOption(text: "NovelMaidActionFifteenA".localize(), nextPageIndex: 17),
                StoryOption(text: "NovelMaidActionFifteenB".localize(), nextPageIndex: 18)
            ]),
            StoryPage(imageName: "novel1_9", narrationText: "NovelMaidContentSixteen".localize(), questionText: "NovelMaidPromptSixteen".localize(), options: [
                StoryOption(text: "NovelMaidActionSixteenA".localize(), nextPageIndex: 17),
                StoryOption(text: "NovelMaidActionSixteenB".localize(), nextPageIndex: 18)
            ]),
            // 17 & 18: Кульминация
            StoryPage(imageName: "novel1_10", narrationText: "NovelMaidContentSeventeen".localize(), questionText: "NovelMaidPromptSeventeen".localize(), options: [
                StoryOption(text: "NovelMaidActionSeventeenA".localize(), nextPageIndex: 19),
                StoryOption(text: "NovelMaidActionSeventeenB".localize(), nextPageIndex: 20)
            ]),
            StoryPage(imageName: "novel1_10", narrationText: "NovelMaidContentEighteen".localize(), questionText: "NovelMaidPromptEighteen".localize(), options: [
                StoryOption(text: "NovelMaidActionEighteenA".localize(), nextPageIndex: 19),
                StoryOption(text: "NovelMaidActionEighteenB".localize(), nextPageIndex: 20)
            ]),
            // 19 & 20: Препятствие
            StoryPage(imageName: "novel1_11", narrationText: "NovelMaidContentNineteen".localize(), questionText: "NovelMaidPromptNineteen".localize(), options: [
                StoryOption(text: "NovelMaidActionNineteenA".localize(), nextPageIndex: 21),
                StoryOption(text: "NovelMaidActionNineteenB".localize(), nextPageIndex: 22)
            ]),
            StoryPage(imageName: "novel1_11", narrationText: "NovelMaidContentTwenty".localize(), questionText: "NovelMaidPromptTwenty".localize(), options: [
                StoryOption(text: "NovelMaidActionTwentyA".localize(), nextPageIndex: 21),
                StoryOption(text: "NovelMaidActionTwentyB".localize(), nextPageIndex: 22)
            ]),
            // 21 & 22: Подготовка к финалу
            StoryPage(imageName: "novel1_12", narrationText: "NovelMaidContentTwentyOne".localize(), questionText: "NovelMaidPromptTwentyOne".localize(), options: [
                StoryOption(text: "NovelMaidActionTwentyOneA".localize(), nextPageIndex: 23),
                StoryOption(text: "NovelMaidActionTwentyOneB".localize(), nextPageIndex: 23)
            ]),
            StoryPage(imageName: "novel1_12", narrationText: "NovelMaidContentTwentyTwo".localize(), questionText: "NovelMaidPromptTwentyTwo".localize(), options: [
                StoryOption(text: "NovelMaidActionTwentyTwoA".localize(), nextPageIndex: 24),
                StoryOption(text: "NovelMaidActionTwentyTwoB".localize(), nextPageIndex: 24)
            ]),
            // 23: Финал 1
            StoryPage(imageName: "novel1_13", narrationText: "NovelMaidContentTwentyThree".localize(), questionText: "NovelMaidPromptTwentyThree".localize(), options: [
                StoryOption(text: "NovelMaidActionTwentyThreeA".localize(), nextPageIndex: 0),
                StoryOption(text: "NovelMaidActionTwentyThreeB".localize(), nextPageIndex: -1)
            ]),
            // 24: Финал 2
            StoryPage(imageName: "novel1_13", narrationText: "NovelMaidContentTwentyFour".localize(), questionText: "NovelMaidPromptTwentyFour".localize(), options: [
                StoryOption(text: "NovelMaidActionTwentyFourA".localize(), nextPageIndex: 0),
                StoryOption(text: "NovelMaidActionTwentyFourB".localize(), nextPageIndex: -1)
            ])
        ]
        
        let tokyoPages: [StoryPage] = [
            /* 0 */ StoryPage(imageName: "novel2_1", narrationText: "NovelTokyoContentZero".localize(), questionText: "NovelTokyoPromptZero".localize(), options: [
                StoryOption(text: "NovelTokyoActionZeroA".localize(), nextPageIndex: 1),
                StoryOption(text: "NovelTokyoActionZeroB".localize(), nextPageIndex: 2)
            ]),
            /* 1 */ StoryPage(imageName: "novel2_2", narrationText: "NovelTokyoContentOne".localize(), questionText: "NovelTokyoPromptOne".localize(), options: [
                StoryOption(text: "NovelTokyoActionOneA".localize(), nextPageIndex: 3),
                StoryOption(text: "NovelTokyoActionOneB".localize(), nextPageIndex: 4)
            ]),
            /* 2 */ StoryPage(imageName: "novel2_2", narrationText: "NovelTokyoContentTwo".localize(), questionText: "NovelTokyoPromptTwo".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwoA".localize(), nextPageIndex: 3),
                StoryOption(text: "NovelTokyoActionTwoB".localize(), nextPageIndex: 4)
            ]),
            /* 3 */ StoryPage(imageName: "novel2_3", narrationText: "NovelTokyoContentThree".localize(), questionText: "NovelTokyoPromptThree".localize(), options: [
                StoryOption(text: "NovelTokyoActionThreeA".localize(), nextPageIndex: 5),
                StoryOption(text: "NovelTokyoActionThreeB".localize(), nextPageIndex: 6)
            ]),
            /* 4 */ StoryPage(imageName: "novel2_3", narrationText: "NovelTokyoContentFour".localize(), questionText: "NovelTokyoPromptFour".localize(), options: [
                StoryOption(text: "NovelTokyoActionFourA".localize(), nextPageIndex: 5),
                StoryOption(text: "NovelTokyoActionFourB".localize(), nextPageIndex: 6)
            ]),
            /* 5 */ StoryPage(imageName: "novel2_4", narrationText: "NovelTokyoContentFive".localize(), questionText: "NovelTokyoPromptFive".localize(), options: [
                StoryOption(text: "NovelTokyoActionFiveA".localize(), nextPageIndex: 7),
                StoryOption(text: "NovelTokyoActionFiveB".localize(), nextPageIndex: 8)
            ]),
            /* 6 */ StoryPage(imageName: "novel2_4", narrationText: "NovelTokyoContentSix".localize(), questionText: "NovelTokyoPromptSix".localize(), options: [
                StoryOption(text: "NovelTokyoActionSixA".localize(), nextPageIndex: 7),
                StoryOption(text: "NovelTokyoActionSixB".localize(), nextPageIndex: 8)
            ]),
            /* 7 */ StoryPage(imageName: "novel2_5", narrationText: "NovelTokyoContentSeven".localize(), questionText: "NovelTokyoPromptSeven".localize(), options: [
                StoryOption(text: "NovelTokyoActionSevenA".localize(), nextPageIndex: 9),
                StoryOption(text: "NovelTokyoActionSevenB".localize(), nextPageIndex: 10)
            ]),
            /* 8 */ StoryPage(imageName: "novel2_5", narrationText: "NovelTokyoContentEight".localize(), questionText: "NovelTokyoPromptEight".localize(), options: [
                StoryOption(text: "NovelTokyoActionEightA".localize(), nextPageIndex: 9),
                StoryOption(text: "NovelTokyoActionEightB".localize(), nextPageIndex: 10)
            ]),
            /* 9 */ StoryPage(imageName: "novel2_6", narrationText: "NovelTokyoContentNine".localize(), questionText: "NovelTokyoPromptNine".localize(), options: [
                StoryOption(text: "NovelTokyoActionNineA".localize(), nextPageIndex: 11),
                StoryOption(text: "NovelTokyoActionNineB".localize(), nextPageIndex: 12)
            ]),
            /* 10 */ StoryPage(imageName: "novel2_6", narrationText: "NovelTokyoContentTen".localize(), questionText: "NovelTokyoPromptTen".localize(), options: [
                StoryOption(text: "NovelTokyoActionTenA".localize(), nextPageIndex: 11),
                StoryOption(text: "NovelTokyoActionTenB".localize(), nextPageIndex: 12)
            ]),
            /* 11 */ StoryPage(imageName: "novel2_7", narrationText: "NovelTokyoContentEleven".localize(), questionText: "NovelTokyoPromptEleven".localize(), options: [
                StoryOption(text: "NovelTokyoActionElevenA".localize(), nextPageIndex: 13),
                StoryOption(text: "NovelTokyoActionElevenB".localize(), nextPageIndex: 14)
            ]),
            /* 12 */ StoryPage(imageName: "novel2_7", narrationText: "NovelTokyoContentTwelve".localize(), questionText: "NovelTokyoPromptTwelve".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwelveA".localize(), nextPageIndex: 13),
                StoryOption(text: "NovelTokyoActionTwelveB".localize(), nextPageIndex: 14)
            ]),
            /* 13 */ StoryPage(imageName: "novel2_8", narrationText: "NovelTokyoContentThirteen".localize(), questionText: "NovelTokyoPromptThirteen".localize(), options: [
                StoryOption(text: "NovelTokyoActionThirteenA".localize(), nextPageIndex: 15),
                StoryOption(text: "NovelTokyoActionThirteenB".localize(), nextPageIndex: 16)
            ]),
            /* 14 */ StoryPage(imageName: "novel2_8", narrationText: "NovelTokyoContentFourteen".localize(), questionText: "NovelTokyoPromptFourteen".localize(), options: [
                StoryOption(text: "NovelTokyoActionFourteenA".localize(), nextPageIndex: 15),
                StoryOption(text: "NovelTokyoActionFourteenB".localize(), nextPageIndex: 16)
            ]),
            /* 15 */ StoryPage(imageName: "novel2_9", narrationText: "NovelTokyoContentFifteen".localize(), questionText: "NovelTokyoPromptFifteen".localize(), options: [
                StoryOption(text: "NovelTokyoActionFifteenA".localize(), nextPageIndex: 17),
                StoryOption(text: "NovelTokyoActionFifteenB".localize(), nextPageIndex: 18)
            ]),
            /* 16 */ StoryPage(imageName: "novel2_9", narrationText: "NovelTokyoContentSixteen".localize(), questionText: "NovelTokyoPromptSixteen".localize(), options: [
                StoryOption(text: "NovelTokyoActionSixteenA".localize(), nextPageIndex: 17),
                StoryOption(text: "NovelTokyoActionSixteenB".localize(), nextPageIndex: 18)
            ]),
            /* 17 */ StoryPage(imageName: "novel2_10", narrationText: "NovelTokyoContentSeventeen".localize(), questionText: "NovelTokyoPromptSeventeen".localize(), options: [
                StoryOption(text: "NovelTokyoActionSeventeenA".localize(), nextPageIndex: 19),
                StoryOption(text: "NovelTokyoActionSeventeenB".localize(), nextPageIndex: 20)
            ]),
            /* 18 */ StoryPage(imageName: "novel2_10", narrationText: "NovelTokyoContentEighteen".localize(), questionText: "NovelTokyoPromptEighteen".localize(), options: [
                StoryOption(text: "NovelTokyoActionEighteenA".localize(), nextPageIndex: 19),
                StoryOption(text: "NovelTokyoActionEighteenB".localize(), nextPageIndex: 20)
            ]),
            /* 19 */ StoryPage(imageName: "novel2_11", narrationText: "NovelTokyoContentNineteen".localize(), questionText: "NovelTokyoPromptNineteen".localize(), options: [
                StoryOption(text: "NovelTokyoActionNineteenA".localize(), nextPageIndex: 21),
                StoryOption(text: "NovelTokyoActionNineteenB".localize(), nextPageIndex: 22)
            ]),
            /* 20 */ StoryPage(imageName: "novel2_11", narrationText: "NovelTokyoContentTwenty".localize(), questionText: "NovelTokyoPromptTwenty".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyA".localize(), nextPageIndex: 21),
                StoryOption(text: "NovelTokyoActionTwentyB".localize(), nextPageIndex: 22)
            ]),
            /* 21 */ StoryPage(imageName: "novel2_12", narrationText: "NovelTokyoContentTwentyOne".localize(), questionText: "NovelTokyoPromptTwentyOne".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyOneA".localize(), nextPageIndex: 23),
                StoryOption(text: "NovelTokyoActionTwentyOneB".localize(), nextPageIndex: 24)
            ]),
            /* 22 */ StoryPage(imageName: "novel2_12", narrationText: "NovelTokyoContentTwentyTwo".localize(), questionText: "NovelTokyoPromptTwentyTwo".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyTwoA".localize(), nextPageIndex: 23),
                StoryOption(text: "NovelTokyoActionTwentyTwoB".localize(), nextPageIndex: 24)
            ]),
            /* 23 */ StoryPage(imageName: "novel2_13", narrationText: "NovelTokyoContentTwentyThree".localize(), questionText: "NovelTokyoPromptTwentyThree".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyThreeA".localize(), nextPageIndex: 25),
                StoryOption(text: "NovelTokyoActionTwentyThreeB".localize(), nextPageIndex: 26)
            ]),
            /* 24 */ StoryPage(imageName: "novel2_13", narrationText: "NovelTokyoContentTwentyFour".localize(), questionText: "NovelTokyoPromptTwentyFour".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyFourA".localize(), nextPageIndex: 25),
                StoryOption(text: "NovelTokyoActionTwentyFourB".localize(), nextPageIndex: 26)
            ]),
            /* 25 */ StoryPage(imageName: "novel2_14", narrationText: "NovelTokyoContentTwentyFive".localize(), questionText: "NovelTokyoPromptTwentyFive".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyFiveA".localize(), nextPageIndex: 27),
                StoryOption(text: "NovelTokyoActionTwentyFiveB".localize(), nextPageIndex: 28)
            ]),
            /* 26 */ StoryPage(imageName: "novel2_14", narrationText: "NovelTokyoContentTwentySix".localize(), questionText: "NovelTokyoPromptTwentySix".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentySixA".localize(), nextPageIndex: 27),
                StoryOption(text: "NovelTokyoActionTwentySixB".localize(), nextPageIndex: 28)
            ]),
            /* 27 */ StoryPage(imageName: "novel2_15", narrationText: "NovelTokyoContentTwentySeven".localize(), questionText: "NovelTokyoPromptTwentySeven".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentySevenA".localize(), nextPageIndex: 29),
                StoryOption(text: "NovelTokyoActionTwentySevenB".localize(), nextPageIndex: 29)
            ]),
            /* 28 */ StoryPage(imageName: "novel2_15", narrationText: "NovelTokyoContentTwentyEight".localize(), questionText: "NovelTokyoPromptTwentyEight".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyEightA".localize(), nextPageIndex: 29),
                StoryOption(text: "NovelTokyoActionTwentyEightB".localize(), nextPageIndex: 29)
            ]),
            /* 29 */ StoryPage(imageName: "novel2_16", narrationText: "NovelTokyoContentTwentyNine".localize(), questionText: "NovelTokyoPromptTwentyNine".localize(), options: [
                StoryOption(text: "NovelTokyoActionTwentyNineA".localize(), nextPageIndex: 0),
                StoryOption(text: "NovelTokyoActionTwentyNineB".localize(), nextPageIndex: -1)
            ])
        ]
        
        let summerPages: [StoryPage] = [
            StoryPage(imageName: "novel3_1", narrationText: "NovelCampContentZero".localize(), questionText: "NovelCampPromptZero".localize(), options: [
                StoryOption(text: "NovelCampActionZeroA".localize(), nextPageIndex: 1),
                StoryOption(text: "NovelCampActionZeroB".localize(), nextPageIndex: 2)
            ]),
            StoryPage(imageName: "novel3_2", narrationText: "NovelCampContentOne".localize(), questionText: "NovelCampPromptOne".localize(), options: [
                StoryOption(text: "NovelCampActionOneA".localize(), nextPageIndex: 3),
                StoryOption(text: "NovelCampActionOneB".localize(), nextPageIndex: 4)
            ]),
            StoryPage(imageName: "novel3_2", narrationText: "NovelCampContentTwo".localize(), questionText: "NovelCampPromptTwo".localize(), options: [
                StoryOption(text: "NovelCampActionTwoA".localize(), nextPageIndex: 3),
                StoryOption(text: "NovelCampActionTwoB".localize(), nextPageIndex: 4)
            ]),
            StoryPage(imageName: "novel3_3", narrationText: "NovelCampContentThree".localize(), questionText: "NovelCampPromptThree".localize(), options: [
                StoryOption(text: "NovelCampActionThreeA".localize(), nextPageIndex: 5),
                StoryOption(text: "NovelCampActionThreeB".localize(), nextPageIndex: 6)
            ]),
            StoryPage(imageName: "novel3_3", narrationText: "NovelCampContentFour".localize(), questionText: "NovelCampPromptFour".localize(), options: [
                StoryOption(text: "NovelCampActionFourA".localize(), nextPageIndex: 5),
                StoryOption(text: "NovelCampActionFourB".localize(), nextPageIndex: 6)
            ]),
            StoryPage(imageName: "novel3_4", narrationText: "NovelCampContentFive".localize(), questionText: "NovelCampPromptFive".localize(), options: [
                StoryOption(text: "NovelCampActionFiveA".localize(), nextPageIndex: 7),
                StoryOption(text: "NovelCampActionFiveB".localize(), nextPageIndex: 8)
            ]),
            StoryPage(imageName: "novel3_4", narrationText: "NovelCampContentSix".localize(), questionText: "NovelCampPromptSix".localize(), options: [
                StoryOption(text: "NovelCampActionSixA".localize(), nextPageIndex: 7),
                StoryOption(text: "NovelCampActionSixB".localize(), nextPageIndex: 8)
            ]),
            StoryPage(imageName: "novel3_5", narrationText: "NovelCampContentSeven".localize(), questionText: "NovelCampPromptSeven".localize(), options: [
                StoryOption(text: "NovelCampActionSevenA".localize(), nextPageIndex: 9),
                StoryOption(text: "NovelCampActionSevenB".localize(), nextPageIndex: 10)
            ]),
            StoryPage(imageName: "novel3_5", narrationText: "NovelCampContentEight".localize(), questionText: "NovelCampPromptEight".localize(), options: [
                StoryOption(text: "NovelCampActionEightA".localize(), nextPageIndex: 9),
                StoryOption(text: "NovelCampActionEightB".localize(), nextPageIndex: 10)
            ]),
            StoryPage(imageName: "novel3_6", narrationText: "NovelCampContentNine".localize(), questionText: "NovelCampPromptNine".localize(), options: [
                StoryOption(text: "NovelCampActionNineA".localize(), nextPageIndex: 11),
                StoryOption(text: "NovelCampActionNineB".localize(), nextPageIndex: 12)
            ]),
            StoryPage(imageName: "novel3_6", narrationText: "NovelCampContentTen".localize(), questionText: "NovelCampPromptTen".localize(), options: [
                StoryOption(text: "NovelCampActionTenA".localize(), nextPageIndex: 11),
                StoryOption(text: "NovelCampActionTenB".localize(), nextPageIndex: 12)
            ]),
            StoryPage(imageName: "novel3_7", narrationText: "NovelCampContentEleven".localize(), questionText: "NovelCampPromptEleven".localize(), options: [
                StoryOption(text: "NovelCampActionElevenA".localize(), nextPageIndex: 13),
                StoryOption(text: "NovelCampActionElevenB".localize(), nextPageIndex: 14)
            ]),
            StoryPage(imageName: "novel3_7", narrationText: "NovelCampContentTwelve".localize(), questionText: "NovelCampPromptTwelve".localize(), options: [
                StoryOption(text: "NovelCampActionTwelveA".localize(), nextPageIndex: 13),
                StoryOption(text: "NovelCampActionTwelveB".localize(), nextPageIndex: 14)
            ]),
            StoryPage(imageName: "novel3_8", narrationText: "NovelCampContentThirteen".localize(), questionText: "NovelCampPromptThirteen".localize(), options: [
                StoryOption(text: "NovelCampActionThirteenA".localize(), nextPageIndex: 15),
                StoryOption(text: "NovelCampActionThirteenB".localize(), nextPageIndex: 16)
            ]),
            StoryPage(imageName: "novel3_8", narrationText: "NovelCampContentFourteen".localize(), questionText: "NovelCampPromptFourteen".localize(), options: [
                StoryOption(text: "NovelCampActionFourteenA".localize(), nextPageIndex: 15),
                StoryOption(text: "NovelCampActionFourteenB".localize(), nextPageIndex: 16)
            ]),
            StoryPage(imageName: "novel3_9", narrationText: "NovelCampContentFifteen".localize(), questionText: "NovelCampPromptFifteen".localize(), options: [
                StoryOption(text: "NovelCampActionFifteenA".localize(), nextPageIndex: 17),
                StoryOption(text: "NovelCampActionFifteenB".localize(), nextPageIndex: 18)
            ]),
            StoryPage(imageName: "novel3_9", narrationText: "NovelCampContentSixteen".localize(), questionText: "NovelCampPromptSixteen".localize(), options: [
                StoryOption(text: "NovelCampActionSixteenA".localize(), nextPageIndex: 17),
                StoryOption(text: "NovelCampActionSixteenB".localize(), nextPageIndex: 18)
            ]),
            StoryPage(imageName: "novel3_10", narrationText: "NovelCampContentSeventeen".localize(), questionText: "NovelCampPromptSeventeen".localize(), options: [
                StoryOption(text: "NovelCampActionSeventeenA".localize(), nextPageIndex: 19),
                StoryOption(text: "NovelCampActionSeventeenB".localize(), nextPageIndex: 20)
            ]),
            StoryPage(imageName: "novel3_10", narrationText: "NovelCampContentEighteen".localize(), questionText: "NovelCampPromptEighteen".localize(), options: [
                StoryOption(text: "NovelCampActionEighteenA".localize(), nextPageIndex: 19),
                StoryOption(text: "NovelCampActionEighteenB".localize(), nextPageIndex: 20)
            ]),
            StoryPage(imageName: "novel3_11", narrationText: "NovelCampContentNineteen".localize(), questionText: "NovelCampPromptNineteen".localize(), options: [
                StoryOption(text: "NovelCampActionNineteenA".localize(), nextPageIndex: 21),
                StoryOption(text: "NovelCampActionNineteenB".localize(), nextPageIndex: 22)
            ]),
            StoryPage(imageName: "novel3_11", narrationText: "NovelCampContentTwenty".localize(), questionText: "NovelCampPromptTwenty".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyA".localize(), nextPageIndex: 21),
                StoryOption(text: "NovelCampActionTwentyB".localize(), nextPageIndex: 22)
            ]),
            StoryPage(imageName: "novel3_12", narrationText: "NovelCampContentTwentyOne".localize(), questionText: "NovelCampPromptTwentyOne".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyOneA".localize(), nextPageIndex: 23),
                StoryOption(text: "NovelCampActionTwentyOneB".localize(), nextPageIndex: 24)
            ]),
            StoryPage(imageName: "novel3_12", narrationText: "NovelCampContentTwentyTwo".localize(), questionText: "NovelCampPromptTwentyTwo".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyTwoA".localize(), nextPageIndex: 23),
                StoryOption(text: "NovelCampActionTwentyTwoB".localize(), nextPageIndex: 24)
            ]),
            StoryPage(imageName: "novel3_13", narrationText: "NovelCampContentTwentyThree".localize(), questionText: "NovelCampPromptTwentyThree".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyThreeA".localize(), nextPageIndex: 25),
                StoryOption(text: "NovelCampActionTwentyThreeB".localize(), nextPageIndex: 26)
            ]),
            StoryPage(imageName: "novel3_13", narrationText: "NovelCampContentTwentyFour".localize(), questionText: "NovelCampPromptTwentyFour".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyFourA".localize(), nextPageIndex: 25),
                StoryOption(text: "NovelCampActionTwentyFourB".localize(), nextPageIndex: 26)
            ]),
            StoryPage(imageName: "novel3_14", narrationText: "NovelCampContentTwentyFive".localize(), questionText: "NovelCampPromptTwentyFive".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyFiveA".localize(), nextPageIndex: 27),
                StoryOption(text: "NovelCampActionTwentyFiveB".localize(), nextPageIndex: 28)
            ]),
            StoryPage(imageName: "novel3_14", narrationText: "NovelCampContentTwentySix".localize(), questionText: "NovelCampPromptTwentySix".localize(), options: [
                StoryOption(text: "NovelCampActionTwentySixA".localize(), nextPageIndex: 27),
                StoryOption(text: "NovelCampActionTwentySixB".localize(), nextPageIndex: 28)
            ]),
            StoryPage(imageName: "novel3_15", narrationText: "NovelCampContentTwentySeven".localize(), questionText: "NovelCampPromptTwentySeven".localize(), options: [
                StoryOption(text: "NovelCampActionTwentySevenA".localize(), nextPageIndex: 0),
                StoryOption(text: "NovelCampActionTwentySevenB".localize(), nextPageIndex: -1)
            ]),
            StoryPage(imageName: "novel3_15", narrationText: "NovelCampContentTwentyEight".localize(), questionText: "NovelCampPromptTwentyEight".localize(), options: [
                StoryOption(text: "NovelCampActionTwentyEightA".localize(), nextPageIndex: 0),
                StoryOption(text: "NovelCampActionTwentyEightB".localize(), nextPageIndex: -1)
            ])
        ]
        
        stories = [
            Storyline(title: "TextAdventuresTitle1".localize(), pages: maidPages),
            Storyline(title: "TextAdventuresTitle2".localize(), pages: tokyoPages),
            Storyline(title: "TextAdventuresTitle3".localize(), pages: summerPages)
        ]
    }
}
