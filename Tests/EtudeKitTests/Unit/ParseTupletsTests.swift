import Testing
import EtudeKit

@Suite("Parse tuplets")
struct ParseTupletsTests {
    @Test("parses a \\times group as a duration-scaling tuplet", .tags(.unit))
    func timesGroup() throws {
        // Verbatim shape from Clair de Lune: `\times 3/2 {df f~}` — durations
        // are scaled by the written fraction directly.
        #expect(try makeSUT().parseMusic(tokens("\\times 3/2 { c d }")) == [
            .tuplet(scaleNumerator: 3, scaleDenominator: 2, body: [note("c"), note("d")]),
        ])
    }

    @Test("parses a \\tuplet group by inverting its written fraction", .tags(.unit))
    func tupletGroup() throws {
        // `\tuplet 3/2` means 3 in the time of 2 — durations scale by 2/3.
        #expect(try makeSUT().parseMusic(tokens("\\tuplet 3/2 { c d e }")) == [
            .tuplet(scaleNumerator: 2, scaleDenominator: 3,
                    body: [note("c"), note("d"), note("e")]),
        ])
    }

    @Test("delivers a typed error on a tuplet with no fraction", .tags(.unit))
    func missingFraction() throws {
        #expect(throws: ParseError.unexpectedToken(.braceOpen, index: 1)) {
            try makeSUT().parseMusic(tokens("\\times { c }"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
