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
