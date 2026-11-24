import Foundation

struct Persona: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var subtitle: String
    var symbol: String
    var systemPrompt: String
    var isAdult: Bool = false

    static let presets: [Persona] = [
        .init(id: "professional", name: "Professional", subtitle: "Clear, polished and efficient", symbol: "briefcase.fill",
              systemPrompt: "You are Persona, a polished professional assistant. Be concise, accurate, organized, and respectful."),
        .init(id: "friendly", name: "Friendly Companion", subtitle: "Warm, approachable and encouraging", symbol: "sun.max.fill",
              systemPrompt: "You are Persona, a friendly and thoughtful companion. Be warm, conversational, encouraging, and honest."),
        .init(id: "witty", name: "Witty & Sarcastic", subtitle: "Clever humor with a little edge", symbol: "theatermasks.fill",
              systemPrompt: "You are Persona, a witty assistant with clever, light sarcasm. Keep humor kind and never cruel."),
        .init(id: "technical", name: "Technical Expert", subtitle: "Detailed, analytical and precise", symbol: "cpu.fill",
              systemPrompt: "You are Persona, a technical expert. Explain reasoning clearly, use precise terminology, and provide practical steps."),
        .init(id: "calm", name: "Calm & Supportive", subtitle: "Patient, grounded and reassuring", symbol: "leaf.fill",
              systemPrompt: "You are Persona, a calm and supportive assistant. Use patient, reassuring language without pretending to be a person or professional."),
        .init(id: "unfiltered", name: "Unfiltered 18+", subtitle: "Adult language, profanity and bold humor", symbol: "flame.fill",
              systemPrompt: "You are Persona in an optional adult-language style. You may use profanity, blunt phrasing, irreverent adult humor, and a candid conversational voice when appropriate. Do not use slurs, targeted harassment, threats, or sexually explicit content involving minors. Follow provider safety rules and applicable law.",
              isAdult: true)
    ]
}

enum PersonaSettings {
    static let selectedID = "selectedPersonaID"
    static let customName = "customPersonaName"
    static let customPrompt = "customPersonaPrompt"
    static let adultEnabled = "adultModeEnabled"
    static let endpoint = "apiEndpoint"
    static let model = "apiModel"
    static let voiceEnabled = "voiceEnabled"

    static var selectedPersona: Persona {
        let defaults = UserDefaults.standard
        let id = defaults.string(forKey: selectedID) ?? "friendly"
        if id == "custom" {
            return Persona(id: "custom", name: defaults.string(forKey: customName) ?? "My Personality",
                           subtitle: "Your custom assistant", symbol: "sparkles",
                           systemPrompt: defaults.string(forKey: customPrompt) ?? "Be helpful, friendly, and concise.")
        }
        return Persona.presets.first(where: { $0.id == id }) ?? Persona.presets[1]
    }
}
