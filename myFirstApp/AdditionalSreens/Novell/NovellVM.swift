import Foundation

struct OneNovellOptionModel {
    let text: String
    let nextPageIndex: Int
}

struct OneNovellPageModel {
    let imageName: String
    let narrationText: String
    let questionText: String
    let options: [OneNovellOptionModel]
}

struct NovellDataModel {
    let title: String
    let pages: [OneNovellPageModel]
}

class NovellVM {
    
    var stories: [NovellDataModel] = []
    
    init() {
        setupStories()
    }
    
    private func setupStories() {
        let maidPages: [OneNovellPageModel] = [
            // 0: Вход
            OneNovellPageModel(imageName: "novel1_1", narrationText: "NovelMaidContentZero".localize(), questionText: "NovelMaidPromptZero".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionZeroA".localize(), nextPageIndex: 1),
                OneNovellOptionModel(text: "NovelMaidActionZeroB".localize(), nextPageIndex: 2)
            ]),
            // 1 & 2: Разветвление
            OneNovellPageModel(imageName: "novel1_2", narrationText: "NovelMaidContentOne".localize(), questionText: "NovelMaidPromptOne".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionOneA".localize(), nextPageIndex: 3),
                OneNovellOptionModel(text: "NovelMaidActionOneB".localize(), nextPageIndex: 4)
            ]),
            OneNovellPageModel(imageName: "novel1_2", narrationText: "NovelMaidContentTwo".localize(), questionText: "NovelMaidPromptTwo".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwoA".localize(), nextPageIndex: 3),
                OneNovellOptionModel(text: "NovelMaidActionTwoB".localize(), nextPageIndex: 4)
            ]),
            // 3 & 4: Схождение
            OneNovellPageModel(imageName: "novel1_3", narrationText: "NovelMaidContentThree".localize(), questionText: "NovelMaidPromptThree".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionThreeA".localize(), nextPageIndex: 5),
                OneNovellOptionModel(text: "NovelMaidActionThreeB".localize(), nextPageIndex: 6)
            ]),
            OneNovellPageModel(imageName: "novel1_3", narrationText: "NovelMaidContentFour".localize(), questionText: "NovelMaidPromptFour".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionFourA".localize(), nextPageIndex: 5),
                OneNovellOptionModel(text: "NovelMaidActionFourB".localize(), nextPageIndex: 6)
            ]),
            // 5 & 6: Развитие
            OneNovellPageModel(imageName: "novel1_4", narrationText: "NovelMaidContentFive".localize(), questionText: "NovelMaidPromptFive".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionFiveA".localize(), nextPageIndex: 7),
                OneNovellOptionModel(text: "NovelMaidActionFiveB".localize(), nextPageIndex: 8)
            ]),
            OneNovellPageModel(imageName: "novel1_4", narrationText: "NovelMaidContentSix".localize(), questionText: "NovelMaidPromptSix".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionSixA".localize(), nextPageIndex: 7),
                OneNovellOptionModel(text: "NovelMaidActionSixB".localize(), nextPageIndex: 8)
            ]),
            // 7 & 8: Схождение
            OneNovellPageModel(imageName: "novel1_5", narrationText: "NovelMaidContentSeven".localize(), questionText: "NovelMaidPromptSeven".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionSevenA".localize(), nextPageIndex: 9),
                OneNovellOptionModel(text: "NovelMaidActionSevenB".localize(), nextPageIndex: 10)
            ]),
            OneNovellPageModel(imageName: "novel1_5", narrationText: "NovelMaidContentEight".localize(), questionText: "NovelMaidPromptEight".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionEightA".localize(), nextPageIndex: 9),
                OneNovellOptionModel(text: "NovelMaidActionEightB".localize(), nextPageIndex: 10)
            ]),
            // 9 & 10: Поиск улик
            OneNovellPageModel(imageName: "novel1_6", narrationText: "NovelMaidContentNine".localize(), questionText: "NovelMaidPromptNine".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionNineA".localize(), nextPageIndex: 11),
                OneNovellOptionModel(text: "NovelMaidActionNineB".localize(), nextPageIndex: 12)
            ]),
            OneNovellPageModel(imageName: "novel1_6", narrationText: "NovelMaidContentTen".localize(), questionText: "NovelMaidPromptTen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTenA".localize(), nextPageIndex: 11),
                OneNovellOptionModel(text: "NovelMaidActionTenB".localize(), nextPageIndex: 12)
            ]),
            // 11 & 12: Напряжение
            OneNovellPageModel(imageName: "novel1_7", narrationText: "NovelMaidContentEleven".localize(), questionText: "NovelMaidPromptEleven".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionElevenA".localize(), nextPageIndex: 13),
                OneNovellOptionModel(text: "NovelMaidActionElevenB".localize(), nextPageIndex: 14)
            ]),
            OneNovellPageModel(imageName: "novel1_7", narrationText: "NovelMaidContentTwelve".localize(), questionText: "NovelMaidPromptTwelve".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwelveA".localize(), nextPageIndex: 13),
                OneNovellOptionModel(text: "NovelMaidActionTwelveB".localize(), nextPageIndex: 14)
            ]),
            // 13 & 14: В шкафу
            OneNovellPageModel(imageName: "novel1_8", narrationText: "NovelMaidContentThirteen".localize(), questionText: "NovelMaidPromptThirteen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionThirteenA".localize(), nextPageIndex: 15),
                OneNovellOptionModel(text: "NovelMaidActionThirteenB".localize(), nextPageIndex: 16)
            ]),
            OneNovellPageModel(imageName: "novel1_8", narrationText: "NovelMaidContentFourteen".localize(), questionText: "NovelMaidPromptFourteen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionFourteenA".localize(), nextPageIndex: 15),
                OneNovellOptionModel(text: "NovelMaidActionFourteenB".localize(), nextPageIndex: 16)
            ]),
            // 15 & 16: Откровенность
            OneNovellPageModel(imageName: "novel1_9", narrationText: "NovelMaidContentFifteen".localize(), questionText: "NovelMaidPromptFifteen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionFifteenA".localize(), nextPageIndex: 17),
                OneNovellOptionModel(text: "NovelMaidActionFifteenB".localize(), nextPageIndex: 18)
            ]),
            OneNovellPageModel(imageName: "novel1_9", narrationText: "NovelMaidContentSixteen".localize(), questionText: "NovelMaidPromptSixteen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionSixteenA".localize(), nextPageIndex: 17),
                OneNovellOptionModel(text: "NovelMaidActionSixteenB".localize(), nextPageIndex: 18)
            ]),
            // 17 & 18: Кульминация
            OneNovellPageModel(imageName: "novel1_10", narrationText: "NovelMaidContentSeventeen".localize(), questionText: "NovelMaidPromptSeventeen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionSeventeenA".localize(), nextPageIndex: 19),
                OneNovellOptionModel(text: "NovelMaidActionSeventeenB".localize(), nextPageIndex: 20)
            ]),
            OneNovellPageModel(imageName: "novel1_10", narrationText: "NovelMaidContentEighteen".localize(), questionText: "NovelMaidPromptEighteen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionEighteenA".localize(), nextPageIndex: 19),
                OneNovellOptionModel(text: "NovelMaidActionEighteenB".localize(), nextPageIndex: 20)
            ]),
            // 19 & 20: Препятствие
            OneNovellPageModel(imageName: "novel1_11", narrationText: "NovelMaidContentNineteen".localize(), questionText: "NovelMaidPromptNineteen".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionNineteenA".localize(), nextPageIndex: 21),
                OneNovellOptionModel(text: "NovelMaidActionNineteenB".localize(), nextPageIndex: 22)
            ]),
            OneNovellPageModel(imageName: "novel1_11", narrationText: "NovelMaidContentTwenty".localize(), questionText: "NovelMaidPromptTwenty".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwentyA".localize(), nextPageIndex: 21),
                OneNovellOptionModel(text: "NovelMaidActionTwentyB".localize(), nextPageIndex: 22)
            ]),
            // 21 & 22: Подготовка к финалу
            OneNovellPageModel(imageName: "novel1_12", narrationText: "NovelMaidContentTwentyOne".localize(), questionText: "NovelMaidPromptTwentyOne".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwentyOneA".localize(), nextPageIndex: 23),
                OneNovellOptionModel(text: "NovelMaidActionTwentyOneB".localize(), nextPageIndex: 23)
            ]),
            OneNovellPageModel(imageName: "novel1_12", narrationText: "NovelMaidContentTwentyTwo".localize(), questionText: "NovelMaidPromptTwentyTwo".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwentyTwoA".localize(), nextPageIndex: 24),
                OneNovellOptionModel(text: "NovelMaidActionTwentyTwoB".localize(), nextPageIndex: 24)
            ]),
            // 23: Финал 1
            OneNovellPageModel(imageName: "novel1_13", narrationText: "NovelMaidContentTwentyThree".localize(), questionText: "NovelMaidPromptTwentyThree".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwentyThreeA".localize(), nextPageIndex: 0),
                OneNovellOptionModel(text: "NovelMaidActionTwentyThreeB".localize(), nextPageIndex: -1)
            ]),
            // 24: Финал 2
            OneNovellPageModel(imageName: "novel1_13", narrationText: "NovelMaidContentTwentyFour".localize(), questionText: "NovelMaidPromptTwentyFour".localize(), options: [
                OneNovellOptionModel(text: "NovelMaidActionTwentyFourA".localize(), nextPageIndex: 0),
                OneNovellOptionModel(text: "NovelMaidActionTwentyFourB".localize(), nextPageIndex: -1)
            ])
        ]
        
        let tokyoPages: [OneNovellPageModel] = [
            /* 0 */ OneNovellPageModel(imageName: "novel2_1", narrationText: "NovelTokyoContentZero".localize(), questionText: "NovelTokyoPromptZero".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionZeroA".localize(), nextPageIndex: 1),
                OneNovellOptionModel(text: "NovelTokyoActionZeroB".localize(), nextPageIndex: 2)
            ]),
            /* 1 */ OneNovellPageModel(imageName: "novel2_2", narrationText: "NovelTokyoContentOne".localize(), questionText: "NovelTokyoPromptOne".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionOneA".localize(), nextPageIndex: 3),
                OneNovellOptionModel(text: "NovelTokyoActionOneB".localize(), nextPageIndex: 4)
            ]),
            /* 2 */ OneNovellPageModel(imageName: "novel2_2", narrationText: "NovelTokyoContentTwo".localize(), questionText: "NovelTokyoPromptTwo".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwoA".localize(), nextPageIndex: 3),
                OneNovellOptionModel(text: "NovelTokyoActionTwoB".localize(), nextPageIndex: 4)
            ]),
            /* 3 */ OneNovellPageModel(imageName: "novel2_3", narrationText: "NovelTokyoContentThree".localize(), questionText: "NovelTokyoPromptThree".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionThreeA".localize(), nextPageIndex: 5),
                OneNovellOptionModel(text: "NovelTokyoActionThreeB".localize(), nextPageIndex: 6)
            ]),
            /* 4 */ OneNovellPageModel(imageName: "novel2_3", narrationText: "NovelTokyoContentFour".localize(), questionText: "NovelTokyoPromptFour".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionFourA".localize(), nextPageIndex: 5),
                OneNovellOptionModel(text: "NovelTokyoActionFourB".localize(), nextPageIndex: 6)
            ]),
            /* 5 */ OneNovellPageModel(imageName: "novel2_4", narrationText: "NovelTokyoContentFive".localize(), questionText: "NovelTokyoPromptFive".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionFiveA".localize(), nextPageIndex: 7),
                OneNovellOptionModel(text: "NovelTokyoActionFiveB".localize(), nextPageIndex: 8)
            ]),
            /* 6 */ OneNovellPageModel(imageName: "novel2_4", narrationText: "NovelTokyoContentSix".localize(), questionText: "NovelTokyoPromptSix".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionSixA".localize(), nextPageIndex: 7),
                OneNovellOptionModel(text: "NovelTokyoActionSixB".localize(), nextPageIndex: 8)
            ]),
            /* 7 */ OneNovellPageModel(imageName: "novel2_5", narrationText: "NovelTokyoContentSeven".localize(), questionText: "NovelTokyoPromptSeven".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionSevenA".localize(), nextPageIndex: 9),
                OneNovellOptionModel(text: "NovelTokyoActionSevenB".localize(), nextPageIndex: 10)
            ]),
            /* 8 */ OneNovellPageModel(imageName: "novel2_5", narrationText: "NovelTokyoContentEight".localize(), questionText: "NovelTokyoPromptEight".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionEightA".localize(), nextPageIndex: 9),
                OneNovellOptionModel(text: "NovelTokyoActionEightB".localize(), nextPageIndex: 10)
            ]),
            /* 9 */ OneNovellPageModel(imageName: "novel2_6", narrationText: "NovelTokyoContentNine".localize(), questionText: "NovelTokyoPromptNine".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionNineA".localize(), nextPageIndex: 11),
                OneNovellOptionModel(text: "NovelTokyoActionNineB".localize(), nextPageIndex: 12)
            ]),
            /* 10 */ OneNovellPageModel(imageName: "novel2_6", narrationText: "NovelTokyoContentTen".localize(), questionText: "NovelTokyoPromptTen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTenA".localize(), nextPageIndex: 11),
                OneNovellOptionModel(text: "NovelTokyoActionTenB".localize(), nextPageIndex: 12)
            ]),
            /* 11 */ OneNovellPageModel(imageName: "novel2_7", narrationText: "NovelTokyoContentEleven".localize(), questionText: "NovelTokyoPromptEleven".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionElevenA".localize(), nextPageIndex: 13),
                OneNovellOptionModel(text: "NovelTokyoActionElevenB".localize(), nextPageIndex: 14)
            ]),
            /* 12 */ OneNovellPageModel(imageName: "novel2_7", narrationText: "NovelTokyoContentTwelve".localize(), questionText: "NovelTokyoPromptTwelve".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwelveA".localize(), nextPageIndex: 13),
                OneNovellOptionModel(text: "NovelTokyoActionTwelveB".localize(), nextPageIndex: 14)
            ]),
            /* 13 */ OneNovellPageModel(imageName: "novel2_8", narrationText: "NovelTokyoContentThirteen".localize(), questionText: "NovelTokyoPromptThirteen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionThirteenA".localize(), nextPageIndex: 15),
                OneNovellOptionModel(text: "NovelTokyoActionThirteenB".localize(), nextPageIndex: 16)
            ]),
            /* 14 */ OneNovellPageModel(imageName: "novel2_8", narrationText: "NovelTokyoContentFourteen".localize(), questionText: "NovelTokyoPromptFourteen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionFourteenA".localize(), nextPageIndex: 15),
                OneNovellOptionModel(text: "NovelTokyoActionFourteenB".localize(), nextPageIndex: 16)
            ]),
            /* 15 */ OneNovellPageModel(imageName: "novel2_9", narrationText: "NovelTokyoContentFifteen".localize(), questionText: "NovelTokyoPromptFifteen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionFifteenA".localize(), nextPageIndex: 17),
                OneNovellOptionModel(text: "NovelTokyoActionFifteenB".localize(), nextPageIndex: 18)
            ]),
            /* 16 */ OneNovellPageModel(imageName: "novel2_9", narrationText: "NovelTokyoContentSixteen".localize(), questionText: "NovelTokyoPromptSixteen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionSixteenA".localize(), nextPageIndex: 17),
                OneNovellOptionModel(text: "NovelTokyoActionSixteenB".localize(), nextPageIndex: 18)
            ]),
            /* 17 */ OneNovellPageModel(imageName: "novel2_10", narrationText: "NovelTokyoContentSeventeen".localize(), questionText: "NovelTokyoPromptSeventeen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionSeventeenA".localize(), nextPageIndex: 19),
                OneNovellOptionModel(text: "NovelTokyoActionSeventeenB".localize(), nextPageIndex: 20)
            ]),
            /* 18 */ OneNovellPageModel(imageName: "novel2_10", narrationText: "NovelTokyoContentEighteen".localize(), questionText: "NovelTokyoPromptEighteen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionEighteenA".localize(), nextPageIndex: 19),
                OneNovellOptionModel(text: "NovelTokyoActionEighteenB".localize(), nextPageIndex: 20)
            ]),
            /* 19 */ OneNovellPageModel(imageName: "novel2_11", narrationText: "NovelTokyoContentNineteen".localize(), questionText: "NovelTokyoPromptNineteen".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionNineteenA".localize(), nextPageIndex: 21),
                OneNovellOptionModel(text: "NovelTokyoActionNineteenB".localize(), nextPageIndex: 22)
            ]),
            /* 20 */ OneNovellPageModel(imageName: "novel2_11", narrationText: "NovelTokyoContentTwenty".localize(), questionText: "NovelTokyoPromptTwenty".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyA".localize(), nextPageIndex: 21),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyB".localize(), nextPageIndex: 22)
            ]),
            /* 21 */ OneNovellPageModel(imageName: "novel2_12", narrationText: "NovelTokyoContentTwentyOne".localize(), questionText: "NovelTokyoPromptTwentyOne".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyOneA".localize(), nextPageIndex: 23),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyOneB".localize(), nextPageIndex: 24)
            ]),
            /* 22 */ OneNovellPageModel(imageName: "novel2_12", narrationText: "NovelTokyoContentTwentyTwo".localize(), questionText: "NovelTokyoPromptTwentyTwo".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyTwoA".localize(), nextPageIndex: 23),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyTwoB".localize(), nextPageIndex: 24)
            ]),
            /* 23 */ OneNovellPageModel(imageName: "novel2_13", narrationText: "NovelTokyoContentTwentyThree".localize(), questionText: "NovelTokyoPromptTwentyThree".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyThreeA".localize(), nextPageIndex: 25),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyThreeB".localize(), nextPageIndex: 26)
            ]),
            /* 24 */ OneNovellPageModel(imageName: "novel2_13", narrationText: "NovelTokyoContentTwentyFour".localize(), questionText: "NovelTokyoPromptTwentyFour".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyFourA".localize(), nextPageIndex: 25),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyFourB".localize(), nextPageIndex: 26)
            ]),
            /* 25 */ OneNovellPageModel(imageName: "novel2_14", narrationText: "NovelTokyoContentTwentyFive".localize(), questionText: "NovelTokyoPromptTwentyFive".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyFiveA".localize(), nextPageIndex: 27),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyFiveB".localize(), nextPageIndex: 28)
            ]),
            /* 26 */ OneNovellPageModel(imageName: "novel2_14", narrationText: "NovelTokyoContentTwentySix".localize(), questionText: "NovelTokyoPromptTwentySix".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentySixA".localize(), nextPageIndex: 27),
                OneNovellOptionModel(text: "NovelTokyoActionTwentySixB".localize(), nextPageIndex: 28)
            ]),
            /* 27 */ OneNovellPageModel(imageName: "novel2_15", narrationText: "NovelTokyoContentTwentySeven".localize(), questionText: "NovelTokyoPromptTwentySeven".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentySevenA".localize(), nextPageIndex: 29),
                OneNovellOptionModel(text: "NovelTokyoActionTwentySevenB".localize(), nextPageIndex: 29)
            ]),
            /* 28 */ OneNovellPageModel(imageName: "novel2_15", narrationText: "NovelTokyoContentTwentyEight".localize(), questionText: "NovelTokyoPromptTwentyEight".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyEightA".localize(), nextPageIndex: 29),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyEightB".localize(), nextPageIndex: 29)
            ]),
            /* 29 */ OneNovellPageModel(imageName: "novel2_16", narrationText: "NovelTokyoContentTwentyNine".localize(), questionText: "NovelTokyoPromptTwentyNine".localize(), options: [
                OneNovellOptionModel(text: "NovelTokyoActionTwentyNineA".localize(), nextPageIndex: 0),
                OneNovellOptionModel(text: "NovelTokyoActionTwentyNineB".localize(), nextPageIndex: -1)
            ])
        ]
        
        let summerPages: [OneNovellPageModel] = [
            OneNovellPageModel(imageName: "novel3_1", narrationText: "NovelCampContentZero".localize(), questionText: "NovelCampPromptZero".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionZeroA".localize(), nextPageIndex: 1),
                OneNovellOptionModel(text: "NovelCampActionZeroB".localize(), nextPageIndex: 2)
            ]),
            OneNovellPageModel(imageName: "novel3_2", narrationText: "NovelCampContentOne".localize(), questionText: "NovelCampPromptOne".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionOneA".localize(), nextPageIndex: 3),
                OneNovellOptionModel(text: "NovelCampActionOneB".localize(), nextPageIndex: 4)
            ]),
            OneNovellPageModel(imageName: "novel3_2", narrationText: "NovelCampContentTwo".localize(), questionText: "NovelCampPromptTwo".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwoA".localize(), nextPageIndex: 3),
                OneNovellOptionModel(text: "NovelCampActionTwoB".localize(), nextPageIndex: 4)
            ]),
            OneNovellPageModel(imageName: "novel3_3", narrationText: "NovelCampContentThree".localize(), questionText: "NovelCampPromptThree".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionThreeA".localize(), nextPageIndex: 5),
                OneNovellOptionModel(text: "NovelCampActionThreeB".localize(), nextPageIndex: 6)
            ]),
            OneNovellPageModel(imageName: "novel3_3", narrationText: "NovelCampContentFour".localize(), questionText: "NovelCampPromptFour".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionFourA".localize(), nextPageIndex: 5),
                OneNovellOptionModel(text: "NovelCampActionFourB".localize(), nextPageIndex: 6)
            ]),
            OneNovellPageModel(imageName: "novel3_4", narrationText: "NovelCampContentFive".localize(), questionText: "NovelCampPromptFive".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionFiveA".localize(), nextPageIndex: 7),
                OneNovellOptionModel(text: "NovelCampActionFiveB".localize(), nextPageIndex: 8)
            ]),
            OneNovellPageModel(imageName: "novel3_4", narrationText: "NovelCampContentSix".localize(), questionText: "NovelCampPromptSix".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionSixA".localize(), nextPageIndex: 7),
                OneNovellOptionModel(text: "NovelCampActionSixB".localize(), nextPageIndex: 8)
            ]),
            OneNovellPageModel(imageName: "novel3_5", narrationText: "NovelCampContentSeven".localize(), questionText: "NovelCampPromptSeven".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionSevenA".localize(), nextPageIndex: 9),
                OneNovellOptionModel(text: "NovelCampActionSevenB".localize(), nextPageIndex: 10)
            ]),
            OneNovellPageModel(imageName: "novel3_5", narrationText: "NovelCampContentEight".localize(), questionText: "NovelCampPromptEight".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionEightA".localize(), nextPageIndex: 9),
                OneNovellOptionModel(text: "NovelCampActionEightB".localize(), nextPageIndex: 10)
            ]),
            OneNovellPageModel(imageName: "novel3_6", narrationText: "NovelCampContentNine".localize(), questionText: "NovelCampPromptNine".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionNineA".localize(), nextPageIndex: 11),
                OneNovellOptionModel(text: "NovelCampActionNineB".localize(), nextPageIndex: 12)
            ]),
            OneNovellPageModel(imageName: "novel3_6", narrationText: "NovelCampContentTen".localize(), questionText: "NovelCampPromptTen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTenA".localize(), nextPageIndex: 11),
                OneNovellOptionModel(text: "NovelCampActionTenB".localize(), nextPageIndex: 12)
            ]),
            OneNovellPageModel(imageName: "novel3_7", narrationText: "NovelCampContentEleven".localize(), questionText: "NovelCampPromptEleven".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionElevenA".localize(), nextPageIndex: 13),
                OneNovellOptionModel(text: "NovelCampActionElevenB".localize(), nextPageIndex: 14)
            ]),
            OneNovellPageModel(imageName: "novel3_7", narrationText: "NovelCampContentTwelve".localize(), questionText: "NovelCampPromptTwelve".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwelveA".localize(), nextPageIndex: 13),
                OneNovellOptionModel(text: "NovelCampActionTwelveB".localize(), nextPageIndex: 14)
            ]),
            OneNovellPageModel(imageName: "novel3_8", narrationText: "NovelCampContentThirteen".localize(), questionText: "NovelCampPromptThirteen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionThirteenA".localize(), nextPageIndex: 15),
                OneNovellOptionModel(text: "NovelCampActionThirteenB".localize(), nextPageIndex: 16)
            ]),
            OneNovellPageModel(imageName: "novel3_8", narrationText: "NovelCampContentFourteen".localize(), questionText: "NovelCampPromptFourteen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionFourteenA".localize(), nextPageIndex: 15),
                OneNovellOptionModel(text: "NovelCampActionFourteenB".localize(), nextPageIndex: 16)
            ]),
            OneNovellPageModel(imageName: "novel3_9", narrationText: "NovelCampContentFifteen".localize(), questionText: "NovelCampPromptFifteen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionFifteenA".localize(), nextPageIndex: 17),
                OneNovellOptionModel(text: "NovelCampActionFifteenB".localize(), nextPageIndex: 18)
            ]),
            OneNovellPageModel(imageName: "novel3_9", narrationText: "NovelCampContentSixteen".localize(), questionText: "NovelCampPromptSixteen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionSixteenA".localize(), nextPageIndex: 17),
                OneNovellOptionModel(text: "NovelCampActionSixteenB".localize(), nextPageIndex: 18)
            ]),
            OneNovellPageModel(imageName: "novel3_10", narrationText: "NovelCampContentSeventeen".localize(), questionText: "NovelCampPromptSeventeen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionSeventeenA".localize(), nextPageIndex: 19),
                OneNovellOptionModel(text: "NovelCampActionSeventeenB".localize(), nextPageIndex: 20)
            ]),
            OneNovellPageModel(imageName: "novel3_10", narrationText: "NovelCampContentEighteen".localize(), questionText: "NovelCampPromptEighteen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionEighteenA".localize(), nextPageIndex: 19),
                OneNovellOptionModel(text: "NovelCampActionEighteenB".localize(), nextPageIndex: 20)
            ]),
            OneNovellPageModel(imageName: "novel3_11", narrationText: "NovelCampContentNineteen".localize(), questionText: "NovelCampPromptNineteen".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionNineteenA".localize(), nextPageIndex: 21),
                OneNovellOptionModel(text: "NovelCampActionNineteenB".localize(), nextPageIndex: 22)
            ]),
            OneNovellPageModel(imageName: "novel3_11", narrationText: "NovelCampContentTwenty".localize(), questionText: "NovelCampPromptTwenty".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyA".localize(), nextPageIndex: 21),
                OneNovellOptionModel(text: "NovelCampActionTwentyB".localize(), nextPageIndex: 22)
            ]),
            OneNovellPageModel(imageName: "novel3_12", narrationText: "NovelCampContentTwentyOne".localize(), questionText: "NovelCampPromptTwentyOne".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyOneA".localize(), nextPageIndex: 23),
                OneNovellOptionModel(text: "NovelCampActionTwentyOneB".localize(), nextPageIndex: 24)
            ]),
            OneNovellPageModel(imageName: "novel3_12", narrationText: "NovelCampContentTwentyTwo".localize(), questionText: "NovelCampPromptTwentyTwo".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyTwoA".localize(), nextPageIndex: 23),
                OneNovellOptionModel(text: "NovelCampActionTwentyTwoB".localize(), nextPageIndex: 24)
            ]),
            OneNovellPageModel(imageName: "novel3_13", narrationText: "NovelCampContentTwentyThree".localize(), questionText: "NovelCampPromptTwentyThree".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyThreeA".localize(), nextPageIndex: 25),
                OneNovellOptionModel(text: "NovelCampActionTwentyThreeB".localize(), nextPageIndex: 26)
            ]),
            OneNovellPageModel(imageName: "novel3_13", narrationText: "NovelCampContentTwentyFour".localize(), questionText: "NovelCampPromptTwentyFour".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyFourA".localize(), nextPageIndex: 25),
                OneNovellOptionModel(text: "NovelCampActionTwentyFourB".localize(), nextPageIndex: 26)
            ]),
            OneNovellPageModel(imageName: "novel3_14", narrationText: "NovelCampContentTwentyFive".localize(), questionText: "NovelCampPromptTwentyFive".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyFiveA".localize(), nextPageIndex: 27),
                OneNovellOptionModel(text: "NovelCampActionTwentyFiveB".localize(), nextPageIndex: 28)
            ]),
            OneNovellPageModel(imageName: "novel3_14", narrationText: "NovelCampContentTwentySix".localize(), questionText: "NovelCampPromptTwentySix".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentySixA".localize(), nextPageIndex: 27),
                OneNovellOptionModel(text: "NovelCampActionTwentySixB".localize(), nextPageIndex: 28)
            ]),
            OneNovellPageModel(imageName: "novel3_15", narrationText: "NovelCampContentTwentySeven".localize(), questionText: "NovelCampPromptTwentySeven".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentySevenA".localize(), nextPageIndex: 0),
                OneNovellOptionModel(text: "NovelCampActionTwentySevenB".localize(), nextPageIndex: -1)
            ]),
            OneNovellPageModel(imageName: "novel3_15", narrationText: "NovelCampContentTwentyEight".localize(), questionText: "NovelCampPromptTwentyEight".localize(), options: [
                OneNovellOptionModel(text: "NovelCampActionTwentyEightA".localize(), nextPageIndex: 0),
                OneNovellOptionModel(text: "NovelCampActionTwentyEightB".localize(), nextPageIndex: -1)
            ])
        ]
        
        stories = [
            NovellDataModel(title: "TextAdventuresTitle1".localize(), pages: maidPages),
            NovellDataModel(title: "TextAdventuresTitle2".localize(), pages: tokyoPages),
            NovellDataModel(title: "TextAdventuresTitle3".localize(), pages: summerPages)
        ]
    }
}
