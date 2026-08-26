import Testing
import EtudeKit

// The parse tree is a PERFORMING representation — engraving instructions
// (slurs, stems, layout breaks) change how a score looks, not how it sounds,
// so they parse to nothing rather than polluting the tree.
@Suite("Parse engraving skips")
struct ParseEngravingSkipsTests {
    @Test("skips slurs and bar checks between notes", .tags(.unit))
    func slursAndBarChecks() throws {
        // Verbatim shape from the Gymnopédie melody: `s4 fis( a g fis … d2.~ d2) d4 |`
        #expect(try makeSUT().parseMusic(tokens("fis( a) c |")) == [
            note("fis"), note("a"), note("c"),
        ])
    }

    @Test("skips voicing and visibility commands", .tags(.unit), arguments: [
        "voiceOne", "voiceTwo", "once", "hideNotes", "stemUp", "stemDown", "stemNeutral",
        "tieUp", "tieDown", "tieNeutral", "slurUp", "slurDown", "phrasingSlurUp",
        "dynamicUp", "break", "pageBreak",
    ])
    func engravingCommands(command: String) throws {
        #expect(try makeSUT().parseMusic(tokens("c \\\(command) d")) == [
            note("c"), note("d"),
        ])
    }

    @Test("skips a version or language declaration with its argument", .tags(.unit))
    func declarationsWithArguments() throws {
        #expect(try makeSUT().parseMusic(tokens("\\version \"2.24.0\" \\language \"english\" cs")) == [
            note("cs"),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
