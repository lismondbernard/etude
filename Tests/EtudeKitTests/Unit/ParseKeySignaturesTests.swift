import Testing
import EtudeKit

@Suite("Parse key signatures")
struct ParseKeySignaturesTests {
    @Test("parses a major key", .tags(.unit))
    func majorKey() throws {
        // Verbatim shape from the Minuet: `\key g \major`
        #expect(try makeSUT().parseMusic(tokens("\\key g \\major c")) == [
            .key(root: NoteToken(name: "g"), mode: .major),
            note("c"),
        ])
    }

    @Test("parses a minor key with an altered root", .tags(.unit))
    func minorKey() throws {
        #expect(try makeSUT().parseMusic(tokens("\\key fis \\minor")) == [
            .key(root: NoteToken(name: "fis"), mode: .minor),
        ])
    }

    @Test("delivers a typed error on a key without a mode", .tags(.unit))
    func keyWithoutMode() throws {
        #expect(throws: ParseError.unexpectedToken(.note(NoteToken(name: "c")), index: 2)) {
            try makeSUT().parseMusic(tokens("\\key g c"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
