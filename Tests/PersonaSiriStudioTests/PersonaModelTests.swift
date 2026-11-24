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
}
