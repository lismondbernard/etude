import Testing
import EtudeKit

@Suite("Tokenize scheme arguments")
struct TokenizeSchemeTests {
    @Test("lexes scheme forms as single tokens", .tags(.unit), arguments: [
        ("#'(rhUpRed rhDownGreen lhUpBlue lhDownGrey)", "'(rhUpRed rhDownGreen lhUpBlue lhDownGrey)"),
        ("#'damping", "'damping"),
        ("##t", "#t"),
        ("#3", "3"),
        ("#-1", "-1"),
    ])
    func schemeForms(source: String, payload: String) throws {
        #expect(try makeSUT().tokenize(source) == [.scheme(payload)])
    }

    @Test("a scheme number glued to a command stays separate", .tags(.unit))
    func gluedToCommand() throws {
        // Verbatim shape from Clair de Lune: `\barNumberCheck#66`
        #expect(try makeSUT().tokenize("\\barNumberCheck#66 r4") == [
            .command("barNumberCheck"),
            .scheme("66"),
            .rest(RestToken(kind: .sounding, duration: DurationToken(4))),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
