import XCTest
@testable import PersonaSiriStudio

final class PersonaModelTests: XCTestCase {
    func testPresetIdentifiersAreUnique() {
        let identifiers = Persona.presets.map(\.id)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }

    func testEveryPresetHasUsableInstructions() {
        for persona in Persona.presets {
            XCTAssertFalse(persona.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertFalse(persona.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    func testOnlyUnfilteredPresetIsMarkedAdult() {
        let adultPresets = Persona.presets.filter(\.isAdult)
        XCTAssertEqual(adultPresets.map(\.id), ["unfiltered"])
    }

    func testSiriIntentRequiresAdultAcknowledgementOnlyForAdultPreset() throws {
        let adultPersona = try XCTUnwrap(Persona.presets.first(where: \.isAdult))
        let standardPersona = try XCTUnwrap(Persona.presets.first(where: { !$0.isAdult }))

        XCTAssertFalse(AskPersonaIntent.isPersonaEnabled(adultPersona, adultEnabled: false))
        XCTAssertTrue(AskPersonaIntent.isPersonaEnabled(adultPersona, adultEnabled: true))
        XCTAssertTrue(AskPersonaIntent.isPersonaEnabled(standardPersona, adultEnabled: false))
    }

    func testKeychainCanSaveReadReplaceAndDelete() throws {
        let account = "persona-test-\(UUID().uuidString)"
        defer { try? KeychainStore.delete(account: account) }

        try KeychainStore.save("first-test-value", account: account)
        XCTAssertEqual(KeychainStore.read(account: account), "first-test-value")

        try KeychainStore.save("replacement-test-value", account: account)
        XCTAssertEqual(KeychainStore.read(account: account), "replacement-test-value")

        try KeychainStore.delete(account: account)
        XCTAssertNil(KeychainStore.read(account: account))
    }

    func testProviderEndpointRequiresHTTPSAndRejectsEmbeddedCredentialsOrFragment() {
        XCTAssertTrue(AIService.isValidEndpoint("https://api.example.com/v1/chat/completions"))
        XCTAssertTrue(AIService.isValidEndpoint("https://api.example.com:8443/v1/chat?version=1"))
        XCTAssertFalse(AIService.isValidEndpoint("http://api.example.com/v1/chat"))
        XCTAssertFalse(AIService.isValidEndpoint("https://user:secret@api.example.com/v1/chat"))
        XCTAssertFalse(AIService.isValidEndpoint("https://user@api.example.com/v1/chat"))
        XCTAssertFalse(AIService.isValidEndpoint("https://api.example.com/v1/chat#token"))
        XCTAssertFalse(AIService.isValidEndpoint("not a URL"))
    }

    func testTranscriptIsBoundedForInMemoryDisplay() {
        let transcript = (0..<60).map { index in
            AIService.Message(role: index.isMultiple(of: 2) ? "user" : "assistant",
                              content: String(repeating: "m", count: 1_000))
        }
        let bounded = AIService.boundedHistory(transcript)
        XCTAssertLessThanOrEqual(bounded.count, AIService.maximumHistoryMessages)
        XCTAssertLessThanOrEqual(bounded.reduce(0) { $0 + $1.content.count }, AIService.maximumHistoryCharacters)
        XCTAssertEqual(bounded.last?.content.count, 1_000)
    }

    func testPersonaInstructionsAreBoundedBeforeProviderRequest() {
        let oversized = String(repeating: "p", count: AIService.maximumPersonaPromptCharacters + 500)
        let bounded = AIService.boundedPersonaPrompt(oversized)
        XCTAssertEqual(bounded.count, AIService.maximumPersonaPromptCharacters)
        XCTAssertEqual(bounded, String(oversized.prefix(AIService.maximumPersonaPromptCharacters)))
    }

    func testHistoryIsLimitedToRecentMessagesAndCharacterBudget() {
        let history = (0..<30).map { index in
            AIService.Message(role: index == 0 ? "system" : (index.isMultiple(of: 2) ? "user" : "assistant"),
                              content: String(repeating: "x", count: 1_000))
        }
        let bounded = AIService.boundedHistory(history)
        XCTAssertLessThanOrEqual(bounded.count, AIService.maximumHistoryMessages)
        XCTAssertLessThanOrEqual(bounded.reduce(0) { $0 + $1.content.count }, AIService.maximumHistoryCharacters)
        XCTAssertTrue(bounded.allSatisfy { $0.role == "user" || $0.role == "assistant" })
        XCTAssertEqual(bounded.last?.content.count, 1_000)
    }

    func testAIServiceRejectsOverlongPromptBeforeNetworkAccess() async {
        do {
            _ = try await AIService.reply(to: String(repeating: "x", count: AIService.maximumPromptCharacters + 1),
                                          persona: PersonaSettings.selectedPersona)
            XCTFail("Expected an overlong prompt to be rejected.")
        } catch let error as AIServiceError {
            guard case .promptTooLong = error else {
                return XCTFail("Expected promptTooLong, received \(error).")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAIServiceRejectsEmptyPrompt() async {
        do {
            _ = try await AIService.reply(to: " \n ", persona: PersonaSettings.selectedPersona)
            XCTFail("Expected empty prompt to be rejected.")
        } catch let error as AIServiceError {
            guard case .emptyPrompt = error else {
                return XCTFail("Expected emptyPrompt, received \(error).")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
