import Testing
import EtudeKit

@Suite("Parse file structure")
struct ParseFileStructureTests {
    @Test("parses top-level assignments into named definitions", .tags(.unit))
    func assignments() throws {
        let file = try makeSUT().parseFile(tokens("melody = \\relative c'' { fis } bass = { g2. }"))
        #expect(file.definitions == [
            "melody": .relative(anchor: NoteToken(name: "c", octaveMarks: 2), body: [note("fis")]),
            "bass": .sequence([note("g", dur(2, dots: 1))]),
        ])
    }

    @Test("skips a version declaration before definitions", .tags(.unit))
    func versionThenAssignments() throws {
        let file = try makeSUT().parseFile(tokens("\\version \"2.24.0\" theme = { c }"))
        #expect(file.definitions == ["theme": .sequence([note("c")])])
    }

    @Test("delivers a typed error on a stray note at file scope", .tags(.unit))
    func strayMusicAtFileScope() throws {
        #expect(throws: ParseError.unexpectedToken(.note(NoteToken(name: "c")), index: 0)) {
            try makeSUT().parseFile(tokens("c"))
        }
    }

    @Test("parses the header block into metadata fields", .tags(.unit))
    func headerBlock() throws {
        let file = try makeSUT().parseFile(
            tokens("\\header { title = \"Gymnop\u{e9}die No. 1\" composer = \"Erik Satie\" }"))
        #expect(file.header == [
            "title": "Gymnop\u{e9}die No. 1",
            "composer": "Erik Satie",
        ])
    }

    @Test("delivers a typed error on a header field with no string value", .tags(.unit))
    func headerFieldWithoutString() throws {
        #expect(throws: ParseError.unexpectedToken(.number(3), index: 4)) {
            try makeSUT().parseFile(tokens("\\header { title = 3 }"))
        }
    }

    @Test("parses the score block's staff assembly", .tags(.unit))
    func scoreBlock() throws {
        // Verbatim shape from the Gymnopédie.
        let file = try makeSUT().parseFile(tokens("""
            melody = { c }
            \\score { << \\new Staff \\melody \\new Staff << \\new Voice \\bass >> >> }
            """))
        #expect(file.score == .parallel([
            .context(type: "Staff", body: .reference("melody")),
            .context(type: "Staff", body: .parallel([
                .context(type: "Voice", body: .reference("bass")),
            ])),
        ]))
    }

    @Test("a file with no score block has a nil score", .tags(.unit))
    func fileWithoutScore() throws {
        #expect(try makeSUT().parseFile(tokens("theme = { c }")).score == nil)
    }

    @Test("a definition captures earlier definitions by value", .tags(.unit))
    func eagerSubstitution() throws {
        // Clair de Lune grows its voices with `rhUp = {\\rhUp ... \\rhUpRed}` --
        // each redefinition appends to the CAPTURED previous value, so
        // substitution must happen at definition time, not at resolve time.
        let file = try makeSUT().parseFile(tokens("theme = { c } theme = { \\theme d }"))
        #expect(file.definitions["theme"] == .sequence([.sequence([note("c")]), note("d")]))
    }

    @Test("a reference to a name not yet defined stays late-bound", .tags(.unit))
    func forwardReference() throws {
        let file = try makeSUT().parseFile(tokens("melody = { \\coda }"))
        #expect(file.definitions["melody"] == .sequence([.reference("coda")]))
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
