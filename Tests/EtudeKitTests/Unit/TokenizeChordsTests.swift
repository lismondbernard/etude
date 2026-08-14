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

    @Test("tokenizes the chord-repeat mark with an optional duration", .tags(.unit))
    func chordRepeat() throws {
        let sut = makeSUT()
        // Verbatim shape from the Gnossienne: `s4 <c' f>2 q4`
        #expect(try sut.tokenize("s4 <c' f>2 q4 q") == [
            .rest(RestToken(kind: .spacer, duration: DurationToken(4))),
            .chordStart,
            .note(NoteToken(name: "c", octaveMarks: 1)),
            .note(NoteToken(name: "f")),
            .chordEnd(duration: DurationToken(2)),
            .chordRepeat(duration: DurationToken(4)),
            .chordRepeat(duration: nil),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
