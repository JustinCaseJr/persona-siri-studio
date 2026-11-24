import Foundation

enum AIServiceError: LocalizedError {
    case missingKey
    case invalidResponse
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Add your AI provider API key in Settings."
        case .invalidResponse: return "The AI provider returned an unreadable response."
        case .http(let code, let message): return "Provider error \(code): \(message)"
        }
    }
}

struct AIService {
    struct Message: Codable {
        let role: String
        let content: String
    }

    private struct RequestBody: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ResponseBody: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    static func reply(to prompt: String, persona: Persona) async throws -> String {
        guard let key = KeychainStore.read(), !key.isEmpty else { throw AIServiceError.missingKey }
        let defaults = UserDefaults.standard
        let endpoint = defaults.string(forKey: PersonaSettings.endpoint) ?? "https://api.openai.com/v1/chat/completions"
        let model = defaults.string(forKey: PersonaSettings.model) ?? "gpt-4o-mini"
        guard let url = URL(string: endpoint) else { throw AIServiceError.invalidResponse }

        let adultEnabled = defaults.bool(forKey: PersonaSettings.adultEnabled)
        let chosenPersona = persona.isAdult && !adultEnabled ? Persona.presets[1] : persona
        let body = RequestBody(model: model,
                               messages: [
                                Message(role: "system", content: chosenPersona.systemPrompt),
                                Message(role: "user", content: prompt)
                               ],
                               temperature: 0.8)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.http(http.statusCode, String(detail.prefix(500)))
        }
        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let content = decoded.choices.first?.message.content else { throw AIServiceError.invalidResponse }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
