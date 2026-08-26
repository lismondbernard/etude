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

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
