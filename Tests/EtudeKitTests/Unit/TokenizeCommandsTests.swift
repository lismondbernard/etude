import Testing
import EtudeKit

@Suite("Tokenize commands")
struct TokenizeCommandsTests {
    @Test("tokenizes a backslash command by name", .tags(.unit), arguments: [
        "relative", "repeat", "grace", "acciaccatura", "crossStaff", "voiceOne", "hideNotes",
    ])
    func commandName(name: String) throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("\\\(name)") == [.command(name)])
    }

    @Test("a command glued to a brace keeps both tokens", .tags(.unit))
    func commandGluedToBrace() throws {
        let sut = makeSUT()
        // Verbatim shape from the Gnossienne: `\grace{ g8 }`
        #expect(try sut.tokenize("\\grace{ g8 }") == [
            .command("grace"),
            .braceOpen,
            .note(NoteToken(name: "g", duration: DurationToken(8))),
            .braceClose,
        ])
    }

    @Test("a command glued to the end of a note starts its own token", .tags(.unit))
    func commandGluedToNote() throws {
        let sut = makeSUT()
        // Verbatim shape from the Gymnopédie: `e4\rest`
        #expect(try sut.tokenize("e4\\rest") == [
            .note(NoteToken(name: "e", duration: DurationToken(4))),
            .command("rest"),
        ])
    }

    @Test("tokenizes meter fractions and tempo assignments", .tags(.unit))
    func metersAndTempos() throws {
        let sut = makeSUT()
        #expect(try sut.tokenize("\\time 3/4") == [
            .command("time"), .number(3), .slash, .number(4),
        ])
        #expect(try sut.tokenize("\\tempo 4 = 66") == [
            .command("tempo"), .number(4), .equals, .number(66),
        ])
        #expect(try sut.tokenize("\\repeat volta 2") == [
            .command("repeat"), .identifier("volta"), .number(2),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
