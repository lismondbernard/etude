import Testing
import EtudeKit

@Suite("Tokenize rests")
struct TokenizeRestsTests {
    @Test("tokenizes sounding rests, spacers, and multi-measure rests", .tags(.unit), arguments: [
        ("r", RestToken(kind: .sounding)),
        ("r4", RestToken(kind: .sounding, duration: DurationToken(4))),
        ("s1", RestToken(kind: .spacer, duration: DurationToken(1))),
        ("s2.", RestToken(kind: .spacer, duration: DurationToken(2, dots: 1))),
        ("R2.", RestToken(kind: .multiMeasure, duration: DurationToken(2, dots: 1))),
    ])
    func rests(source: String, expected: RestToken) throws {
        let sut = makeSUT()
        #expect(try sut.tokenize(source) == [.rest(expected)])
    }

    @Test("keeps rest letters distinct from pitch letters", .tags(.unit))
    func restVersusPitch() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("r4 g2.") == [
            .rest(RestToken(kind: .sounding, duration: DurationToken(4))),
            .note(NoteToken(name: "g", duration: DurationToken(2, dots: 1))),
        ])
    }

    @Test("scans a duration multiplier on a spacer", .tags(.unit))
    func durationMultipliers() throws {
        let sut = makeSUT()
        // Verbatim shapes from Clair de Lune: `s8*9`, `s2.*9/6`, `s8*0`.
        #expect(try sut.tokenize("s8*9 s2.*9/6 s8*0") == [
            .rest(RestToken(kind: .spacer, duration: DurationToken(8, multiplier: (9, 1)))),
            .rest(RestToken(kind: .spacer, duration: DurationToken(2, dots: 1, multiplier: (9, 6)))),
            .rest(RestToken(kind: .spacer, duration: DurationToken(8, multiplier: (0, 1)))),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
