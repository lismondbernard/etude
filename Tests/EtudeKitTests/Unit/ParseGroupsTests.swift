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

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
