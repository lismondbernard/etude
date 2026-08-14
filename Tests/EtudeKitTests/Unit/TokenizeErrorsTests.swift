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

    @Test("delivers a typed error on a number too large to read", .tags(.unit))
    func oversizedNumber() throws {
        let sut = makeSUT()
        #expect(throws: TokenizerError.malformedNumber(line: 1, column: 2)) {
            try sut.tokenize("c99999999999999999999999")
        }
        #expect(throws: TokenizerError.malformedNumber(line: 1, column: 1)) {
            try sut.tokenize("99999999999999999999999")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
