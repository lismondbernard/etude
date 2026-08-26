import Testing
import EtudeKit

@Suite("Parse parallelMusic blocks")
struct ParseParallelMusicBlocksTests {
    @Test("deals bars round-robin to the named voices", .tags(.unit))
    func roundRobin() throws {
        let file = try makeSUT().parseFile(tokens(
            "\\parallelMusic #'(upper lower) { c4 | d4 | e4 | f4 | }"))
        #expect(file.definitions["upper"] == .sequence([note("c", dur(4)), note("e", dur(4))]))
        #expect(file.definitions["lower"] == .sequence([note("d", dur(4)), note("f", dur(4))]))
    }

    @Test("a braced group inside a bar stays whole", .tags(.unit))
    func groupsStayWhole() throws {
        // Verbatim shape from Clair de Lune: `\times 3/2 {df f~} …` inside bars.
        let file = try makeSUT().parseFile(tokens(
            "\\parallelMusic #'(upper lower) { \\times 3/2 { c8 d } e4 | f4 | }"))
        #expect(file.definitions["upper"] == .sequence([
            .tuplet(scaleNumerator: 3, scaleDenominator: 2,
                    body: [note("c", dur(8)), note("d")]),
            note("e", dur(4)),
        ]))
        #expect(file.definitions["lower"] == .sequence([note("f", dur(4))]))
    }

    @Test("segments with no performed music do not count as bars", .tags(.unit))
    func noiseSegmentsDropped() throws {
        let file = try makeSUT().parseFile(tokens(
            "\\parallelMusic #'(upper lower) { c4 | d4 | \\stemUp | e4 | f4 | }"))
        #expect(file.definitions["upper"] == .sequence([note("c", dur(4)), note("e", dur(4))]))
        #expect(file.definitions["lower"] == .sequence([note("d", dur(4)), note("f", dur(4))]))
    }

    @Test("later definitions can capture the dealt voices", .tags(.unit))
    func dealtVoicesAreDefinitions() throws {
        let file = try makeSUT().parseFile(tokens(
            "\\parallelMusic #'(upper lower) { c4 | d4 | } melody = \\relative c' \\upper"))
        #expect(file.definitions["melody"] == .relative(
            anchor: NoteToken(name: "c", octaveMarks: 1),
            body: [.sequence([note("c", dur(4))])]))
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
