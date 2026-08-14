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

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
