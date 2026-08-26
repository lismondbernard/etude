import Testing
import EtudeKit

@Suite("Tokenize marks")
struct TokenizeMarksTests {
    @Test("tokenizes tie, slur, and bar-check marks, spaced or glued", .tags(.unit))
    func tieSlurAndBarCheck() throws {
        let sut = makeSUT()
        // Verbatim shapes from the Satie sources: `fis2.~`, `fis(`, `g2 ~ g8`, `f1 |`
        #expect(try sut.tokenize("fis2.~ fis( g2 ~ g8 ) f1 |") == [
            .note(NoteToken(name: "fis", duration: DurationToken(2, dots: 1))),
            .tie,
            .note(NoteToken(name: "fis")),
            .slurOpen,
            .note(NoteToken(name: "g", duration: DurationToken(2))),
            .tie,
            .note(NoteToken(name: "g", duration: DurationToken(8))),
            .slurClose,
            .note(NoteToken(name: "f", duration: DurationToken(1))),
            .barCheck,
        ])
    }

    @Test("tokenizes grouping braces as structural tokens", .tags(.unit))
    func groupingBraces() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("{ c4 }") == [
            .braceOpen,
            .note(NoteToken(name: "c", duration: DurationToken(4))),
            .braceClose,
        ])
    }

    @Test("skips beam brackets and attach carets as engraving noise", .tags(.unit))
    func beamsAndAttachMarks() throws {
        let sut = makeSUT()
        // Verbatim shapes from the Minuet source: `g,8[ a b c]`, `c8^[\mordent d`
        #expect(try sut.tokenize("g,8[ a b c] c8^[ d e_ f") == [
            .note(NoteToken(name: "g", octaveMarks: -1, duration: DurationToken(8))),
            .note(NoteToken(name: "a")),
            .note(NoteToken(name: "b")),
            .note(NoteToken(name: "c")),
            .note(NoteToken(name: "c", duration: DurationToken(8))),
            .note(NoteToken(name: "d")),
            .note(NoteToken(name: "e")),
            .note(NoteToken(name: "f")),
        ])
    }

    @Test("lexes phrasing slurs, hairpins, and articulation shorthands to nothing", .tags(.unit))
    func expressiveMarks() throws {
        let sut = makeSUT()
        // Verbatim shapes from Clair de Lune: `df16\( af'`, `s8*0\!`,
        // `<f gf bf>--~`, `r8\pp\<`.
        // …and Clair de Lune's `f2._-` — a tenuto dash riding an attach mark.
        #expect(try sut.tokenize("des16\\( aes \\) c\\< d\\! <e g>-- f-. g-> a2._-") == [
            .note(NoteToken(name: "des", duration: DurationToken(16))),
            .note(NoteToken(name: "aes")),
            .note(NoteToken(name: "c")),
            .note(NoteToken(name: "d")),
            .chordStart,
            .note(NoteToken(name: "e")),
            .note(NoteToken(name: "g")),
            .chordEnd(duration: nil),
            .note(NoteToken(name: "f")),
            .note(NoteToken(name: "g")),
            .note(NoteToken(name: "a", duration: DurationToken(2, dots: 1))),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
