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

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
