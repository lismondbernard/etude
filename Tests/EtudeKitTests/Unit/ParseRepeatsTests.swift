import Testing
import EtudeKit

@Suite("Parse repeats")
struct ParseRepeatsTests {
    @Test("parses a volta repeat with its count and body", .tags(.unit))
    func voltaRepeat() throws {
        #expect(try makeSUT().parseMusic(tokens("\\repeat volta 2 { c d }")) == [
            .repeated(.volta, count: 2, body: [note("c"), note("d")], alternatives: []),
        ])
    }

    @Test("parses an unfold repeat with its count and body", .tags(.unit))
    func unfoldRepeat() throws {
        // Verbatim shape from the Gnossienne bass: `\repeat unfold 6 { f,1 | }`
        #expect(try makeSUT().parseMusic(tokens("\\repeat unfold 6 { f,1 }")) == [
            .repeated(.unfold, count: 6, body: [note("f", marks: -1, dur(1))], alternatives: []),
        ])
    }

    @Test("delivers a typed error on an unknown repeat style", .tags(.unit))
    func unknownStyle() throws {
        #expect(throws: ParseError.unexpectedToken(.identifier("tremolo"), index: 1)) {
            try makeSUT().parseMusic(tokens("\\repeat tremolo 2 { c }"))
        }
    }

    @Test("delivers a typed error on a repeat with no count", .tags(.unit))
    func missingCount() throws {
        #expect(throws: ParseError.unexpectedToken(.braceOpen, index: 2)) {
            try makeSUT().parseMusic(tokens("\\repeat volta { c }"))
        }
    }

    @Test("attaches alternative endings to the preceding volta repeat", .tags(.unit))
    func alternativeEndings() throws {
        #expect(try makeSUT().parseMusic(tokens("\\repeat volta 2 { c } \\alternative { { d } { e } }")) == [
            .repeated(.volta, count: 2, body: [note("c")],
                      alternatives: [[note("d")], [note("e")]]),
        ])
    }

    @Test("delivers a typed error on \\alternative with no repeat before it", .tags(.unit))
    func alternativeWithoutRepeat() throws {
        #expect(throws: ParseError.unexpectedToken(.command("alternative"), index: 1)) {
            try makeSUT().parseMusic(tokens("c \\alternative { { d } }"))
        }
    }

    @Test("delivers a typed error on a bare event inside \\alternative", .tags(.unit))
    func bareEventInsideAlternative() throws {
        #expect(throws: ParseError.unexpectedToken(.note(NoteToken(name: "d")), index: 8)) {
            try makeSUT().parseMusic(tokens("\\repeat volta 2 { c } \\alternative { d }"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
