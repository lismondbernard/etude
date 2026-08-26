import Testing
import EtudeKit

@Suite("Parse relative blocks")
struct ParseRelativeBlocksTests {
    @Test("parses \\relative with its anchor pitch", .tags(.unit))
    func anchoredRelative() throws {
        #expect(try makeSUT().parseMusic(tokens("\\relative c'' { fis a }")) == [
            .relative(anchor: NoteToken(name: "c", octaveMarks: 2),
                      body: [note("fis"), note("a")]),
        ])
    }

    @Test("parses a bare \\relative with no anchor", .tags(.unit))
    func bareRelative() throws {
        // The Gnossienne theme blocks all use this form.
        #expect(try makeSUT().parseMusic(tokens("\\relative { c''8 }")) == [
            .relative(anchor: nil, body: [note("c", marks: 2, dur(8))]),
        ])
    }

    @Test("delivers a typed error when \\relative has no body", .tags(.unit))
    func relativeWithoutBody() throws {
        #expect(throws: ParseError.unexpectedToken(.note(NoteToken(name: "d")), index: 2)) {
            try makeSUT().parseMusic(tokens("\\relative c d"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
