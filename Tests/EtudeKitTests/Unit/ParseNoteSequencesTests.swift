import Testing
import EtudeKit

// Deliberately NOT @testable: the parser is exercised through its public API
// only, so these tests exert the same design pressure its real consumer (the
// Resolver) will.
@Suite("Parse note sequences")
struct ParseNoteSequencesTests {
    @Test("delivers an empty tree for an empty token stream", .tags(.unit))
    func emptyStream() throws {
        #expect(try makeSUT().parseMusic([]) == [])
    }

    @Test("parses bare notes into a flat event sequence", .tags(.unit))
    func bareNotes() throws {
        #expect(try makeSUT().parseMusic(tokens("c4 d e'")) == [
            note("c", dur(4)),
            note("d"),
            note("e", marks: 1),
        ])
    }

    @Test("attaches a tie to the preceding note", .tags(.unit))
    func tieAttachesToPrecedingNote() throws {
        #expect(try makeSUT().parseMusic(tokens("fis2.~ fis2. e")) == [
            note("fis", dur(2, dots: 1), tied: true),
            note("fis", dur(2, dots: 1)),
            note("e"),
        ])
    }

    @Test("a tie may be separated from its note by whitespace", .tags(.unit))
    func detachedTie() throws {
        // Verbatim shape from the Gnossienne: `f4 ~ f2 ~ | f1`
        #expect(try makeSUT().parseMusic(tokens("f4 ~ f2")) == [
            note("f", dur(4), tied: true),
            note("f", dur(2)),
        ])
    }

    @Test("delivers a typed error on a tie with no note before it", .tags(.unit))
    func tieWithoutNote() throws {
        #expect(throws: ParseError.unexpectedToken(.tie, index: 0)) {
            try makeSUT().parseMusic(tokens("~ c"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
