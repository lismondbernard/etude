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

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
