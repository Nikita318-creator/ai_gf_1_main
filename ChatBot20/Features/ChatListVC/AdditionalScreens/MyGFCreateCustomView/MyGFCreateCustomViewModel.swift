import UIKit

class MyGFCreateCustomViewModel {
    var slides: [MyGFScreenData] {
        return [
            MyGFScreenData(
                title: "CreateMyGF.slide1.title".localize(),
                marketingText: "CreateMyGF.slide1.marketing".localize(),
                imageName: "MyGF1",
                questions: [
                    MyGFQuestionModel(
                        id: "hair_style",
                        title: "CreateMyGF.question.hair_style.title".localize(),
                        options: [
                            "CreateMyGF.option.short".localize(),
                            "CreateMyGF.option.long".localize(),
                            "CreateMyGF.option.ponytails".localize(),
                            "CreateMyGF.option.neon".localize(),
                            "CreateMyGF.option.pastel".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    MyGFQuestionModel(
                        id: "eye_type",
                        title: "CreateMyGF.question.eye_type.title".localize(),
                        options: [
                            "CreateMyGF.option.almond".localize(),
                            "CreateMyGF.option.big_doe".localize(),
                            "CreateMyGF.option.glowing_red".localize(),
                            "CreateMyGF.option.mysterious_purple".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    MyGFQuestionModel(
                        id: "body_face",
                        title: "CreateMyGF.question.body_face.title".localize(),
                        options: [
                            "CreateMyGF.option.cute".localize(),
                            "CreateMyGF.option.mature".localize(),
                            "CreateMyGF.option.petite".localize(),
                            "CreateMyGF.option.curvy".localize(),
                            "CreateMyGF.option.pale".localize(),
                            "CreateMyGF.option.tanned".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                ]
            ),
            MyGFScreenData(
                title: "CreateMyGF.slide2.title".localize(),
                marketingText: "CreateMyGF.slide2.marketing".localize(),
                imageName: "MyGF2",
                questions: [
                    MyGFQuestionModel(
                        id: "main_style",
                        title: "CreateMyGF.question.main_style.title".localize(),
                        options: [
                            "CreateMyGF.option.school_uniform".localize(),
                            "CreateMyGF.option.summer_bikini".localize(),
                            "CreateMyGF.option.fantasy_armor".localize(),
                            "CreateMyGF.option.cosplay".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    MyGFQuestionModel(
                        id: "underwear",
                        title: "CreateMyGF.question.underwear.title".localize(),
                        options: [
                            "CreateMyGF.option.cute".localize(),
                            "CreateMyGF.option.lacy".localize(),
                            "CreateMyGF.option.provocative".localize(),
                            "CreateMyGF.option.none".localize()
                        ],
                        allowMultipleSelection: false
                    )
                ]
            ),
            MyGFScreenData(
                title: "CreateMyGF.slide3.title".localize(),
                marketingText: "CreateMyGF.slide3.marketing".localize(),
                imageName: "MyGF3",
                questions: [
                    MyGFQuestionModel(
                        id: "archetype",
                        title: "CreateMyGF.question.archetype.title".localize(),
                        options: [
                            "CreateMyGF.option.spetialArchetype1".localize(),
                            "CreateMyGF.option.spetialArchetype2".localize(),
                            "CreateMyGF.option.spetialArchetype3".localize(),
                            "CreateMyGF.option.spetialArchetype4".localize(),
                            "CreateMyGF.option.spetialArchetype5".localize(),
                        ],
                        allowMultipleSelection: false
                    ),
                ]
            ),
            MyGFScreenData(
                title: "CreateMyGF.slide4.title".localize(),
                marketingText: "CreateMyGF.slide4.marketing".localize(),
                imageName: "MyGF4",
                questions: [
                    MyGFQuestionModel(
                        id: "goal",
                        title: "CreateMyGF.question.goal.title".localize(),
                        options: [
                            "CreateMyGF.option.adventure".localize(),
                            "CreateMyGF.option.protect_you".localize(),
                            "CreateMyGF.option.build_family".localize(),
                            "CreateMyGF.option.discover_herself".localize()
                        ],
                        allowMultipleSelection: false
                    ),
                    MyGFQuestionModel(
                        id: "connection",
                        title: "CreateMyGF.question.connection.title".localize(),
                        options: [
                            "CreateMyGF.option.love_at_first_sight".localize(),
                            "CreateMyGF.option.childhood_friend".localize(),
                            "CreateMyGF.option.soulmate".localize(),
                            "CreateMyGF.option.arranged_meeting".localize()
                        ],
                        allowMultipleSelection: false
                    )
                ]
            ),
            MyGFScreenData(
                title: "CreateMyGF.slide5.title".localize(),
                marketingText: "CreateMyGF.slide5.marketing".localize(),
                imageName: "MyGF4_1",
                questions: [
                    MyGFQuestionModel(
                        id: "affection",
                        title: "CreateMyGF.question.affection.title".localize(),
                        options: [
                            "CreateMyGF.option.hugs".localize(),
                            "CreateMyGF.option.passionate_kisses".localize(),
                            "CreateMyGF.option.dominant_whispers".localize(),
                            "CreateMyGF.option.soft_touches".localize()
                        ],
                        allowMultipleSelection: true
                    ),
                    MyGFQuestionModel(
                        id: "fetish_traits",
                        title: "CreateMyGF.question.fetish_traits.title".localize(),
                        options: [
                            "CreateMyGF.option.cat_ears".localize(),
                            "CreateMyGF.option.tail".localize(),
                            "CreateMyGF.option.glasses".localize(),
                            "CreateMyGF.option.collar".localize(),
                            "CreateMyGF.option.ribbons".localize()
                        ],
                        allowMultipleSelection: true
                    )
                ]
            )
        ]
    }
}
