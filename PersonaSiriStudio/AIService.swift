import Foundation

enum AIServiceError: LocalizedError {
    case missingKey
    case invalidEndpoint
    case invalidResponse
    case emptyPrompt
    case promptTooLong
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Add your AI provider API key in Settings."
        case .invalidEndpoint: return "Use a valid HTTPS chat-completions endpoint."
        case .invalidResponse: return "The AI provider returned an unreadable response."
        case .emptyPrompt: return "Enter a message before sending."
        case .promptTooLong: return "Keep each message under 8,000 characters."
        case .http(let code, let message): return "Provider error \(code): \(message)"
        }
    }
}

struct AIService {
    static let maximumPromptCharacters = 8_000
    static let maximumHistoryCharacters = 24_000
    static let maximumHistoryMessages = 40

    struct Message: Codable, Equatable {
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

    // Keep the newest conversation context within a predictable request-size budget.
    static func boundedHistory(_ history: [Message]) -> [Message] {
        var remaining = maximumHistoryCharacters
        var selected: [Message] = []
        for message in history.suffix(maximumHistoryMessages).reversed() {
            guard remaining > 0 else { break }
            guard message.role == "user" || message.role == "assistant" else { continue }
            let content = String(message.content.suffix(remaining))
            guard !content.isEmpty else { continue }
            selected.append(Message(role: message.role, content: content))
            remaining -= content.count
        }
        return Array(selected.reversed())
    }

    static func reply(to prompt: String, persona: Persona, history: [Message] = []) async throws -> String {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { throw AIServiceError.emptyPrompt }
        guard trimmedPrompt.count <= maximumPromptCharacters else { throw AIServiceError.promptTooLong }
        guard let key = KeychainStore.read(), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.missingKey
        }

        let defaults = UserDefaults.standard
        let endpoint = defaults.string(forKey: PersonaSettings.endpoint) ?? "https://api.openai.com/v1/chat/completions"
        let model = defaults.string(forKey: PersonaSettings.model) ?? "gpt-4o-mini"
        guard let components = URLComponents(string: endpoint),
              components.scheme?.lowercased() == "https",
              components.host != nil,
              let url = components.url else {
            throw AIServiceError.invalidEndpoint
        }
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidResponse
        }

        let adultEnabled = defaults.bool(forKey: PersonaSettings.adultEnabled)
        let chosenPersona = persona.isAdult && !adultEnabled ? Persona.presets[1] : persona
        let safeHistory = boundedHistory(history)
        let messages = [Message(role: "system", content: chosenPersona.systemPrompt)]
            + safeHistory
            + [Message(role: "user", content: trimmedPrompt)]
        let body = RequestBody(model: model, messages: messages, temperature: 0.8)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            // Do not surface full provider payloads: they may contain internal details.
            let detail = String(data: data, encoding: .utf8) ?? "No error details provided."
            throw AIServiceError.http(http.statusCode, String(detail.prefix(240)))
        }
        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
