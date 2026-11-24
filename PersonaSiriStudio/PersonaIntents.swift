import AppIntents
import Foundation

struct AskPersonaIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Persona"
    static var description = IntentDescription("Ask your selected Persona assistant a question.")
    static var openAppWhenRun = false

    @Parameter(title: "Question")
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Persona \(\.$question)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let persona = PersonaSettings.selectedPersona
        let adultEnabled = UserDefaults.standard.bool(forKey: PersonaSettings.adultEnabled)
        guard !persona.isAdult || adultEnabled else {
            return .result(dialog: "The Unfiltered 18+ personality is disabled. Enable it in Persona settings first.")
        }
        do {
            let answer = try await AIService.reply(to: question, persona: persona)
            return .result(dialog: IntentDialog(stringLiteral: answer))
        } catch {
            return .result(dialog: IntentDialog(stringLiteral: error.localizedDescription))
        }
    }
}

struct PersonaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskPersonaIntent(),
            phrases: [
                "Ask Persona with \(.applicationName)",
                "Talk to Persona with \(.applicationName)"
            ],
            shortTitle: "Ask Persona",
            systemImageName: "person.wave.2"
        )
    }
}
