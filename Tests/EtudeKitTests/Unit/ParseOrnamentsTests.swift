import Testing
import EtudeKit

@Suite("Parse ornaments")
struct ParseOrnamentsTests {
    @Test("parses mordent and prall marks after their note", .tags(.unit))
    func mordentAndPrall() throws {
        // Verbatim shapes from the Minuet: `c4^\mordent`, `b^\prall`
        // (the attach caret is lexed away before the parser sees it).
        #expect(try makeSUT().parseMusic(tokens("c4\\mordent b\\prall")) == [
            note("c", dur(4)),
            .ornament(.mordent),
            note("b"),
            .ornament(.prall),
        ])
    }

    @Test("a trill plays plain: skipped like engraving", .tags(.unit))
    func trill() throws {
        // The Winter Largo's `c4.\trill` — the prototype performed trilled
        // notes plain, and the golden fixtures encode that reading.
        #expect(try makeSUT().parseMusic(tokens("c4.\\trill bes8")) == [
            note("c", dur(4, dots: 1)),
            note("bes", dur(8)),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
