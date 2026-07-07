//
//  AssistantConfig.swift
//  ChatBot20
//
//  Created by Mikita on 5.06.25.
//

import UIKit

struct AssistantConfig: Codable {
    var id: String?
    var assistantName: String = ""
    var aiModel: AIModels = .gemini2
    var tone: Tone = .soft // todo ПОМНИ тут храним isAudio - просто я идиот продолжаю говнокодить
    var style: Style = .friendly // todo ПОМНИ тут храним isPremium - просто я идиот и говно-костыле кодер
    var expertise: Expertise = .casual // todo ПОМНИ тут храним ласт месаадж - просто я идиот и говно-костыле кодер
    var assistantInfo: String = ""
    var userInfo: String = ""
    var avatarImageName: String = "0"
}

enum AIModels: String, CaseIterable, Codable {
    case gpt4omini = "gpt-4o-mini"
    case gpt4o = "gpt-4o"
    case claude35Haiku = "Claude 3.5 Haiku"
    case claude37Sonnet = "Claude 3.7 Sonnet"
    case claude4Sonnet = "Claude 4 Sonnet"
    case gemini2 = "Gemini 2.0"
    case gemini15Flash = "Gemini 1.5 Flash"
    case grok3 = "Grok 3"
    case llaMA3 = "LLaMA 3"
    case mistral = "Mistral"
    
    var image: String {
        ""
    }
}

enum Tone: String, CaseIterable, Codable {
    case soft = "Tone.Soft"
    case milf = "Tone.Milf"
    case rough = "Tone.Rough"
    case direct = "Tone.Direct"
    case neutral = "Tone.Neutral"
    case audio = "Tone.Audio"
    case ex = "Tone.Ex"
    case roleplay = "Tone.Roleplay"

    var image: String {
        switch self {
        case .soft:
            return "🎭"
        case .rough:
            return "😣"
        case .direct:
            return "🎯"
        case .neutral:
            return "😐"
        case .audio, .ex, .roleplay, .milf:
            return ""
        }
    }
    
    static func convert(for toneString: String) -> Tone {
        switch toneString {
        case "Tone.Soft".localize():
            return .soft
        case "Tone.Rough".localize():
            return .rough
        case "Tone.Direct".localize():
            return .direct
        case "Tone.Neutral".localize():
            return .neutral
        case "Tone.Audio".localize():
            return .audio
        case "Tone.Ex".localize():
            return .ex
        case "Tone.Roleplay".localize():
            return .roleplay
        case "Tone.Milf".localize():
            return .milf
        default:
            return .soft
        }
    }
}

enum Style: String, CaseIterable, Codable {
    case scientific = "Style.Scientific"
    case friendly = "Style.Friendly"
    case philosophical = "Style.Philosophical"
    case neutral = "Style.Neutral"
    case premium = "Style.Premium"

    var image: String {
        switch self {
        case .scientific:
            return "🧪"
        case .friendly:
            return "😊"
        case .philosophical:
            return "🤔"
        case .neutral:
            return "😐"
        case .premium:
            return ""
        }
    }
    
    static func convert(for styleString: String) -> Style {
        switch styleString {
        case "Style.Scientific".localize():
            return .scientific
        case "Style.Friendly".localize():
            return .friendly
        case "Style.Philosophical".localize():
            return .philosophical
        case "Style.Premium".localize():
            return .premium
        default:
            return .neutral
        }
    }
}

enum Expertise: String, CaseIterable, Codable {
    case sports = "Expertise.Sports"
    case games = "Expertise.Games"
    case tv = "Expertise.Tv"
    case finance = "Expertise.Finance"
    case study = "Expertise.Study"
    case casual = "Expertise.Casual"
    case fashion = "Expertise.Fashion"
    case neutral = "Expertise.Neutral"
    
    case customGF = "CreateYourGF.Hi"
    case roleplay = "Roleplay.Hi"
    case adsBanner = "newChatMessage"
    case gf1 = "Template.Girlfriend1.TextOnMainScreen"
    case gf2 = "Template.Girlfriend2.TextOnMainScreen"
    case gf3 = "Template.Girlfriend3.TextOnMainScreen"
    case gf4 = "Template.Girlfriend4.TextOnMainScreen"
    case gf5 = "Template.Girlfriend5.TextOnMainScreen"
    case gf6 = "Template.Girlfriend6.TextOnMainScreen"
    case gf7 = "Template.Girlfriend7.TextOnMainScreen"
    case gf8 = "Template.Girlfriend8.TextOnMainScreen"
    case gf9 = "Template.Girlfriend9.TextOnMainScreen"
    case gf10 = "Template.Girlfriend10.TextOnMainScreen"
    case gf11 = "Template.Girlfriend11.TextOnMainScreen"
    case gf12 = "Template.Girlfriend12.TextOnMainScreen"
    case gf13 = "Template.Girlfriend13.TextOnMainScreen"
    case gf14 = "Template.Girlfriend14.TextOnMainScreen"
    case gf15 = "Template.Girlfriend15.TextOnMainScreen"
    case gf16 = "Template.Girlfriend16.TextOnMainScreen"
    case gf17 = "Template.Girlfriend17.TextOnMainScreen"
    case gf18 = "Template.Girlfriend18.TextOnMainScreen"
    case gf19 = "Template.Girlfriend19.TextOnMainScreen"
    case gf20 = "Template.Girlfriend20.TextOnMainScreen"
    case gf21 = "Template.Girlfriend21.TextOnMainScreen"
    case gf22 = "Template.Girlfriend22.TextOnMainScreen"
    case gf23 = "Template.Girlfriend23.TextOnMainScreen"
    case gf24 = "Template.Girlfriend24.TextOnMainScreen"
    case gf25 = "Template.Girlfriend25.TextOnMainScreen"
    case gf26 = "Template.Girlfriend26.TextOnMainScreen"
    case gf27 = "Template.Girlfriend27.TextOnMainScreen"

    var image: String {
        switch self {
        case .sports:
            return "⚽"
        case .games:
            return "🎮"
        case .tv:
            return "📺"
        case .finance:
            return "💰"
        case .study:
            return "📚"
        case .casual:
            return "😎"
        case .fashion:
            return "👗"
        case .neutral:
            return "😐"
        case .gf1:
            return ""
        case .gf2:
            return ""
        case .gf3:
            return ""
        case .gf4:
            return ""
        case .gf5:
            return ""
        case .gf6:
            return ""
        case .gf7:
            return ""
        case .gf8:
            return ""
        case .gf9:
            return ""
        case .gf10:
            return ""
        case .gf11:
            return ""
        case .gf12:
            return ""
        case .gf13, .gf14, .gf15, .gf16, .gf17, .gf18, .gf19, .gf20, .gf21, .gf22, .gf23, .gf24, .gf25, .gf26, .gf27:
            return ""
        case .roleplay:
            return ""
        case .customGF:
            return ""
        case .adsBanner:
            return ""
        }
    }
    
    static func convert(for expertiseString: String) -> Expertise {
        switch expertiseString {
        case "Expertise.Sports":
            return .sports
        case "Expertise.Games":
            return .games
        case "Expertise.Tv":
            return .tv
        case "Expertise.Finance":
            return .finance
        case "Expertise.Study":
            return .study
        case "Expertise.Casual":
            return .casual
        case "Expertise.Fashion":
            return .fashion
            
        case "Template.Girlfriend1.TextOnMainScreen".localize():
            return .gf1
        case "Template.Girlfriend2.TextOnMainScreen".localize():
            return .gf2
        case "Template.Girlfriend3.TextOnMainScreen".localize():
            return .gf3
        case "Template.Girlfriend4.TextOnMainScreen".localize():
            return .gf4
        case "Template.Girlfriend5.TextOnMainScreen".localize():
            return .gf5
        case "Template.Girlfriend6.TextOnMainScreen".localize():
            return .gf6
        case "Template.Girlfriend7.TextOnMainScreen".localize():
            return .gf7
        case "Template.Girlfriend8.TextOnMainScreen".localize():
            return .gf8
        case "Template.Girlfriend9.TextOnMainScreen".localize():
            return .gf9
        case "Template.Girlfriend10.TextOnMainScreen".localize():
            return .gf10
        case "Template.Girlfriend11.TextOnMainScreen".localize():
            return .gf11
        case "Template.Girlfriend12.TextOnMainScreen".localize():
            return .gf12
        case "Template.Girlfriend13.TextOnMainScreen".localize():
            return .gf13
        case "Template.Girlfriend14.TextOnMainScreen".localize():
            return .gf14
        case "Template.Girlfriend15.TextOnMainScreen".localize():
            return .gf15
        case "Template.Girlfriend16.TextOnMainScreen".localize():
            return .gf16
        case "Template.Girlfriend17.TextOnMainScreen".localize():
            return .gf17
        case "Template.Girlfriend18.TextOnMainScreen".localize():
            return .gf18
        case "Template.Girlfriend19.TextOnMainScreen".localize():
            return .gf19
        case "Template.Girlfriend20.TextOnMainScreen".localize():
            return .gf20
        case "Template.Girlfriend21.TextOnMainScreen".localize():
            return .gf21
        case "Template.Girlfriend22.TextOnMainScreen".localize():
            return .gf22
        case "Template.Girlfriend23.TextOnMainScreen".localize():
            return .gf23
        case "Template.Girlfriend24.TextOnMainScreen".localize():
            return .gf24
        case "Template.Girlfriend25.TextOnMainScreen".localize():
            return .gf25
        case "Template.Girlfriend26.TextOnMainScreen".localize():
            return .gf26
        case "Template.Girlfriend27.TextOnMainScreen".localize():
            return .gf27
        default:
            return .neutral
        }
    }
}

enum Template: String, CaseIterable {
    case girlfriend = "Template.Girlfriend"
    case boyfriend = "Template.Boyfriend"
    case cryptoExpert = "Template.CryptoExpert"
    case fitnessInstructor = "Template.FitnessInstructor"
    case toxic = "Template.Toxic"
    case pickupArtist = "Template.PickupArtist"
    case toxicEx = "Template.ToxicEx"
    case supportiveFriend = "Template.SupportiveFriend"
    case motivator = "Template.Motivator"
    case copywriter = "Template.Copywriter" // Генератор коротких текстов, рекламных слоганов
    case captionGenerator = "Template.CaptionGenerator" // Специалист по коротким подписям (рилсы, посты)
    case creativeAdvisor = "Template.CreativeAdvisor" // Идейный вдохновитель, генератор концепций
    case fashionConsultant = "Template.FashionConsultant" // Модный эксперт, советы по стилю
    case gossipAnalyst = "Template.GossipAnalyst" // Комментатор новостей и трендов (нейтральная сплетница)
    case filmCritic = "Template.FilmCritic" // Кино-критик, делает обзоры
    case bookReviewer = "Template.BookReviewer" // Книжный гуру, рекомендации по чтению
    
    var config: AssistantConfig {
        switch self {
        case .girlfriend:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .friendly,
                                   expertise: .neutral, assistantInfo: "Template.Girlfriend.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "1")
        case .boyfriend:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .direct, style: .friendly,
                                   expertise: .neutral, assistantInfo: "Template.Boyfriend.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "2")
        case .cryptoExpert:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .direct, style: .scientific,
                                   expertise: .finance, assistantInfo: "Template.CryptoExpert.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "3")
        case .fitnessInstructor:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .rough, style: .friendly,
                                   expertise: .sports, assistantInfo: "Template.FitnessInstructor.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "5")
        case .supportiveFriend:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .friendly,
                                   expertise: .neutral, assistantInfo: "Template.SupportiveFriend.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "13")
        case .motivator:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .direct, style: .philosophical,
                                   expertise: .neutral, assistantInfo: "Template.Motivator.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "4")
        case .copywriter:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .direct, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.Copywriter.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "12")
        case .captionGenerator:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.CaptionGenerator.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "13")
        case .creativeAdvisor:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.CreativeAdvisor.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "11")
        case .fashionConsultant:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .friendly,
                                   expertise: .fashion, assistantInfo: "Template.FashionConsultant.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "11")
        case .gossipAnalyst:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.GossipAnalyst.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "12")
        case .filmCritic:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .direct, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.FilmCritic.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "8")
        case .bookReviewer:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .soft, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.BookReviewer.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "10")
        case .toxic:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .rough, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.Toxic.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "9")
        case .pickupArtist:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .direct, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.PickupArtist.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "7")
        case .toxicEx:
            return AssistantConfig(assistantName: self.rawValue.localize(), aiModel: .gemini15Flash, tone: .rough, style: .neutral,
                                   expertise: .neutral, assistantInfo: "Template.ToxicEx.AssistantInfo".localize(), userInfo: "",
                                   avatarImageName: "6")
        }
    }
    
    var image: String {
        switch self {
        case .girlfriend:
            return "💖"
        case .boyfriend:
            return "💙"
        case .cryptoExpert:
            return "📈"
        case .fitnessInstructor:
            return "💪"
        case .supportiveFriend:
            return "📋"
        case .motivator:
            return "🔥"
        case .copywriter:
            return "✍️"
        case .captionGenerator:
            return "📝"
        case .creativeAdvisor:
            return "💡"
        case .fashionConsultant:
            return "👗"
        case .gossipAnalyst:
            return "🗣️"
        case .filmCritic:
            return "🎬"
        case .bookReviewer:
            return "📚"
        case .toxic:
            return "😈"
        case .pickupArtist:
            return "😎"
        case .toxicEx:
            return "💔"
        }
    }
}

enum Section: Int, CaseIterable {
    case assistantName
    case aiModel
    case tone
    case style
    case expertise
    case assistantInfo
    case userInfo
    
    var title: String {
        switch self {
        case .assistantName:
            return "Section.AssistantName.Title".localize()
        case .aiModel:
            return "Section.AIModel.Title".localize()
        case .tone:
            return "Section.Tone.Title".localize()
        case .style:
            return "Section.Style.Title".localize()
        case .expertise:
            return "Section.Expertise.Title".localize()
        case .assistantInfo:
            return "Section.AssistantInfo.Title".localize()
        case .userInfo:
            return "Section.UserInfo.Title".localize()
        }
    }
}
