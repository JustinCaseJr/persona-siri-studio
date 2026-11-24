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
