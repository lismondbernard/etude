import Testing
import EtudeKit

@Suite("Parse references")
struct ParseReferencesTests {
    @Test("parses an unknown command as a variable reference", .tags(.unit))
    func variableReference() throws {
        // Verbatim shape from the Gnossienne arrangement:
        // `melody = { … \themeOneMelody \themeOneMelody … }`
        #expect(try makeSUT().parseMusic(tokens("\\themeOneMelody \\themeTwoMelody")) == [
            .reference("themeOneMelody"),
            .reference("themeTwoMelody"),
        ])
    }

    @Test("a reference may sit beside ordinary music", .tags(.unit))
    func referenceBesideMusic() throws {
        #expect(try makeSUT().parseMusic(tokens("\\time 4/4 \\intro c4")) == [
            .meter(beats: 4, beatUnit: 4),
            .reference("intro"),
            note("c", dur(4)),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
