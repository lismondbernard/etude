import Testing
import EtudeKit

@Suite("Parse groups")
struct ParseGroupsTests {
    @Test("parses a brace group as nested sequential music", .tags(.unit))
    func braceGroup() throws {
        #expect(try makeSUT().parseMusic(tokens("{ c d } e")) == [
            .sequence([note("c"), note("d")]),
            note("e"),
        ])
    }

    @Test("parses nested brace groups", .tags(.unit))
    func nestedBraces() throws {
        #expect(try makeSUT().parseMusic(tokens("{ c { d } }")) == [
            .sequence([note("c"), .sequence([note("d")])]),
        ])
    }

    @Test("delivers a typed error on an unclosed brace group", .tags(.unit))
    func unclosedBrace() throws {
        #expect(throws: ParseError.unexpectedEndOfInput) {
            try makeSUT().parseMusic(tokens("{ c d"))
        }
    }

    @Test("delivers a typed error on a stray closing brace", .tags(.unit))
    func strayClosingBrace() throws {
        #expect(throws: ParseError.unexpectedToken(.braceClose, index: 1)) {
            try makeSUT().parseMusic(tokens("c }"))
        }
    }

    @Test("parses simultaneous music into a parallel group", .tags(.unit))
    func parallelGroup() throws {
        #expect(try makeSUT().parseMusic(tokens("<< { c d } { e f } >>")) == [
            .parallel([
                .sequence([note("c"), note("d")]),
                .sequence([note("e"), note("f")]),
            ]),
        ])
    }

    @Test("a parallel group's children may be bare events", .tags(.unit))
    func parallelBareChildren() throws {
        // The Gnossienne wraps a lone note and an ossia voice: `<<af2 …>>`.
        #expect(try makeSUT().parseMusic(tokens("<< c2 { e } >> f")) == [
            .parallel([note("c", dur(2)), .sequence([note("e")])]),
            note("f"),
        ])
    }

    @Test("delivers a typed error on an unclosed parallel group", .tags(.unit))
    func unclosedParallel() throws {
        #expect(throws: ParseError.unexpectedEndOfInput) {
            try makeSUT().parseMusic(tokens("<< { c }"))
        }
    }

    @Test("parses a new context wrapping its music", .tags(.unit))
    func newContext() throws {
        // Verbatim shape from the Gnossienne ossia: `\new Voice{\voiceOne … }`
        #expect(try makeSUT().parseMusic(tokens("\\new Voice { c }")) == [
            .context(type: "Voice", body: .sequence([note("c")])),
        ])
    }

    @Test("a new context may wrap a reference or parallel music", .tags(.unit))
    func newContextForms() throws {
        // Verbatim shape from the Gymnopédie score block.
        #expect(try makeSUT().parseMusic(tokens("\\new Staff \\melody \\new Staff << \\new Voice \\bass >>")) == [
            .context(type: "Staff", body: .reference("melody")),
            .context(type: "Staff", body: .parallel([
                .context(type: "Voice", body: .reference("bass")),
            ])),
        ])
    }

    @Test("delivers a typed error on \\new with no context type", .tags(.unit))
    func newWithoutType() throws {
        #expect(throws: ParseError.unexpectedToken(.braceOpen, index: 1)) {
            try makeSUT().parseMusic(tokens("\\new { c }"))
        }
    }

    @Test("parses a named context, discarding the engraving name", .tags(.unit))
    func namedContext() throws {
        // Verbatim shape from the Minuet source: `\context Voice = "ii" { … }`
        #expect(try makeSUT().parseMusic(tokens("\\context Voice = \"ii\" { c }")) == [
            .context(type: "Voice", body: .sequence([note("c")])),
        ])
    }

    @Test("a named new context parses the same way", .tags(.unit))
    func namedNewContext() throws {
        // Clair de Lune's shape: `\new Staff = "upper" { … }`
        #expect(try makeSUT().parseMusic(tokens("\\new Staff = \"upper\" { c }")) == [
            .context(type: "Staff", body: .sequence([note("c")])),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
