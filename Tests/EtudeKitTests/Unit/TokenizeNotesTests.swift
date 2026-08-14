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

    @Test("tokenizes octave marks into a signed count", .tags(.unit), arguments: [
        ("c'", 1), ("c''", 2), ("fis'", 1), ("c,", -1), ("bes,,", -2), ("c", 0),
    ])
    func octaveMarks(source: String, marks: Int) throws {
        let sut = makeSUT()
        let name = String(source.prefix(while: \.isLetter))
        #expect(try sut.tokenize(source) == [.note(NoteToken(name: name, octaveMarks: marks))])
    }

    @Test("tokenizes a duration with dots glued to the note", .tags(.unit), arguments: [
        ("c4", NoteToken(name: "c", duration: DurationToken(4))),
        ("f1", NoteToken(name: "f", duration: DurationToken(1))),
        ("fis2.", NoteToken(name: "fis", duration: DurationToken(2, dots: 1))),
        ("e,2.", NoteToken(name: "e", octaveMarks: -1, duration: DurationToken(2, dots: 1))),
        ("c''8", NoteToken(name: "c", octaveMarks: 2, duration: DurationToken(8))),
    ])
    func gluedDuration(source: String, expected: NoteToken) throws {
        let sut = makeSUT()
        #expect(try sut.tokenize(source) == [.note(expected)])
    }

    @Test("tokenizes Dutch accidental suffixes as part of the pitch", .tags(.unit),
          arguments: ["fis", "cis", "gis", "bes", "des", "fisis", "beses"])
    func dutchAccidentals(name: String) throws {
        let sut = makeSUT()
        #expect(try sut.tokenize(name) == [.note(NoteToken(name: name))])
    }

    @Test("classifies words that are not pitch names as identifiers", .tags(.unit),
          arguments: ["volta", "unfold", "Staff", "Voice", "english", "title"])
    func nonPitchWords(word: String) throws {
        let sut = makeSUT()
        #expect(try sut.tokenize(word) == [.identifier(word)])
    }

    @Test("an identifier glued to a brace keeps both tokens", .tags(.unit))
    func identifierGluedToBrace() throws {
        let sut = makeSUT()
        // Verbatim shape from the Gnossienne: `\new Voice{\voiceOne …`
        #expect(try sut.tokenize("Voice{") == [.identifier("Voice"), .braceOpen])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
