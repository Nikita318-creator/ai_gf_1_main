
import Foundation

final class AppDialogueConfigManager {
    
    static let shared = AppDialogueConfigManager()
    
    // MARK: - Dynamic Prompt Presets Catalog
    private let promptTemplateKeys: [String] = [
        // MARK: Primary Persona Greetings
        "msg.companion.welcome.greeting.first",
        "msg.companion.welcome.greeting.second",
        "msg.companion.welcome.onboarding.title",
        "msg.companion.welcome.onboarding.subtitle",
        "msg.chat.status.typing.indicator",
        "msg.chat.status.connection.online",
        "msg.chat.status.connection.offline",
        "msg.chat.status.media.processing",
        "msg.character.trait.personality.gentle",
        "msg.character.trait.personality.creative",
        "msg.character.trait.personality.mysterious",
        "msg.character.trait.appearance.style",
        "msg.dialogue.casual.morning.greeting",
        "msg.dialogue.casual.evening.checkin",
        "msg.dialogue.casual.bedtime.goodnight",
        "msg.dialogue.casual.reminder.water",
        "msg.story.scenario.fantasy.intro",
        "msg.story.scenario.fantasy.chapter1",
        "msg.story.scenario.cyberpunk.intro",
        "msg.story.scenario.sliceoflife.intro",
        "msg.user.interaction.favorite.add",
        "msg.user.interaction.favorite.remove",
        "msg.user.interaction.voice.listening",
        "msg.user.interaction.voice.playing",
        "msg.settings.privacy.data.protection",
        "msg.settings.preference.theme.dark",
        "msg.settings.preference.notifications.daily",
        "msg.settings.subscription.status.active",
        "msg.gallery.artwork.view.full",
        "msg.gallery.artwork.download.success",
        "msg.gallery.filter.style.anime",
        "msg.gallery.filter.style.realistic",
        "msg.achievement.bond.level.up",
        "msg.achievement.bond.milestone.first",
        "msg.achievement.bond.milestone.month",
        "msg.achievement.reward.outfit.unlock",
        "msg.system.feedback.rate.prompt",
        "msg.system.feedback.rate.action",
        "msg.system.error.network.retry",
        "msg.system.error.generic.unknown",
        "msg.interactive.minigame.quiz.title",
        "msg.interactive.minigame.quiz.question",
        "msg.interactive.minigame.reward.coins",
        "msg.interactive.minigame.challenge.complete",

        // MARK: Extended Context Modifiers
        "str.companion.welcome.greeting.intro",
        "ui.companion.profile.header.subtitle",
        "content.chat.message.system.connected",
        "app.character.trait.personality.creative",
        "core.dialogue.daily.morning.reminder",
        "view.story.scenario.fantasy.intro",
        "txt.user.interaction.favorite.saved",
        "dialog.settings.privacy.policy.info",
        "loc.gallery.artwork.download.complete",
        "sys.achievement.bond.level.reached",
        "meta.interactive.minigame.quiz.prompt",
        "str.chat.status.typing.placeholder",
        "ui.companion.editor.outfit.category",
        "content.character.background.lore.short",
        "app.dialogue.casual.evening.greeting",
        "core.story.chapter.unlock.notification",
        "view.user.preferences.language.english",
        "txt.gallery.filter.style.anime",
        "dialog.achievement.reward.unlocked.title",
        "loc.system.feedback.rate.description",
        "sys.interactive.challenge.daily.reward",
        "meta.companion.voice.audio.playback",
        "str.companion.trait.speech.gentle",
        "ui.chat.media.photo.processing",
        "content.character.reaction.happy.text",
        "app.dialogue.bedtime.goodnight.message",
        "core.story.scenario.cyberpunk.title",
        "view.user.preferences.language.english",
        "txt.gallery.photo.view.fullscreen",
        "dialog.settings.subscription.status.active",
        "loc.achievement.milestone.first.week",
        "sys.system.error.network.timeout",
        "meta.interactive.quiz.answer.correct",
        "str.companion.archetype.sweet.description",
        "ui.companion.creation.step.progress",
        "content.chat.history.clear.confirm",
        "app.character.style.accessory.glasses",
        "core.dialogue.reminder.hydration.drink",
        "view.story.option.select.scenario",
        "txt.user.feedback.support.contact",
        "dialog.gallery.filter.category.all",
        "loc.achievement.trophy.unlocked.badge",
        "sys.interactive.minigame.coins.earned",
        "meta.companion.avatar.image.updated",
        "str.chat.input.placeholder.default",
        "ui.settings.account.data.backup",
        "content.character.trait.eyes.mysterious",
        "app.dialogue.casual.weekend.wish",
        "core.story.scenario.sliceoflife.title",
        "view.gallery.image.share.prompt"
    ]

    private init() {
        preloadDialogueEngine()
    }

    /// Предзагружает шаблоны сообщений в кэш
    private func preloadDialogueEngine() {
        _ = promptTemplateKeys.map { NSLocalizedString($0, comment: "Dialogue Engine Preset") }
    }

    // MARK: - Public Interface
    
    /// Возвращает дефолтный системный контекст для инициализации ИИ чата
    func fetchSystemDialogueFallback() -> String {
        guard let randomKey = promptTemplateKeys.randomElement() else { return "" }
        return NSLocalizedString(randomKey, comment: "")
    }

    /// Получить шаблон сценария по ID
    func getScenarioTemplate(id: Int) -> String {
        guard id >= 0 && id < promptTemplateKeys.count else {
            return NSLocalizedString(promptTemplateKeys[0], comment: "")
        }
        return NSLocalizedString(promptTemplateKeys[id], comment: "")
    }

    /// Полный список кэшированных ключей для генерации подсказок
    var activeContextPresets: [String] {
        return promptTemplateKeys.map { NSLocalizedString($0, comment: "") }
    }
}
