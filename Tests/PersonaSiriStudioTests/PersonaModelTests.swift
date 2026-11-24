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


    func testKeychainCanSaveReadReplaceAndDelete() throws {
        let account = "persona-test-\(UUID().uuidString)"
        defer { KeychainStore.delete(account: account) }

        try KeychainStore.save("first-test-value", account: account)
        XCTAssertEqual(KeychainStore.read(account: account), "first-test-value")

        try KeychainStore.save("replacement-test-value", account: account)
        XCTAssertEqual(KeychainStore.read(account: account), "replacement-test-value")

        KeychainStore.delete(account: account)
        XCTAssertNil(KeychainStore.read(account: account))
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
                return XCTFail("Expected promptTooLong, received \\(error).")
            }
        } catch {
            XCTFail("Unexpected error: \\(error)")
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
