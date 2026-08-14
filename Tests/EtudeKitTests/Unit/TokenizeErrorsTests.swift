import Testing
import EtudeKit

@Suite("Tokenizer errors")
struct TokenizeErrorsTests {
    @Test("delivers a typed error with location on an unexpected character", .tags(.unit))
    func unexpectedCharacter() throws {
        let sut = makeSUT()
        #expect(throws: TokenizerError.unexpectedCharacter("@", line: 2, column: 4)) {
            try sut.tokenize("c4\n d @")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
