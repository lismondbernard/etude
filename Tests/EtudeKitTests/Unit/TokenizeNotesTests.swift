import Testing
import EtudeKit

// Deliberately NOT @testable: the tokenizer is exercised through its public API
// only, so these tests exert the same design pressure a real consumer (the
// Parser) will.
@Suite("Tokenize notes")
struct TokenizeNotesTests {
    @Test("delivers no tokens for empty input", .tags(.unit))
    func emptyInput() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("") == [])
    }

    @Test("delivers no tokens for whitespace-only input", .tags(.unit))
    func whitespaceOnlyInput() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("  \n\t  \n") == [])
    }

    @Test("tokenizes a bare Dutch note name", .tags(.unit), arguments: ["c", "d", "e", "f", "g", "a", "b"])
    func bareDutchNoteName(name: String) throws {
        let sut = makeSUT()
        #expect(try sut.tokenize(name) == [.note(NoteToken(name: name))])
    }

    @Test("tokenizes a sequence of notes separated by whitespace", .tags(.unit))
    func noteSequence() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("c d\n e") == [
            .note(NoteToken(name: "c")),
            .note(NoteToken(name: "d")),
            .note(NoteToken(name: "e")),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
