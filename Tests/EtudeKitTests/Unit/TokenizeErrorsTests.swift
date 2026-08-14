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

    @Test("delivers a typed error on an unterminated string", .tags(.unit))
    func unterminatedString() throws {
        let sut = makeSUT()
        #expect(throws: TokenizerError.unterminatedString(line: 1, column: 8)) {
            try sut.tokenize("\\tempo \"Lent")
        }
    }

    @Test("delivers a typed error on an unterminated chord", .tags(.unit))
    func unterminatedChord() throws {
        let sut = makeSUT()
        #expect(throws: TokenizerError.unterminatedChord(line: 1, column: 4)) {
            try sut.tokenize("c4 <e g b")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
