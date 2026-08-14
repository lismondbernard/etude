import Testing
import EtudeKit

@Suite("Tokenize chords")
struct TokenizeChordsTests {
    @Test("tokenizes a chord as structural delimiters around its pitches", .tags(.unit))
    func chordStructure() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("<c e g>") == [
            .chordStart,
            .note(NoteToken(name: "c")),
            .note(NoteToken(name: "e")),
            .note(NoteToken(name: "g")),
            .chordEnd(duration: nil),
        ])
    }

    @Test("attaches a written duration to the chord close", .tags(.unit))
    func chordDuration() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("<c' a e c>2.") == [
            .chordStart,
            .note(NoteToken(name: "c", octaveMarks: 1)),
            .note(NoteToken(name: "a")),
            .note(NoteToken(name: "e")),
            .note(NoteToken(name: "c")),
            .chordEnd(duration: DurationToken(2, dots: 1)),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
