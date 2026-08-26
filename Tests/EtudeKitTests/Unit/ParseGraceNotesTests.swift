import Testing
import EtudeKit

@Suite("Parse grace notes")
struct ParseGraceNotesTests {
    @Test("parses a grace group ahead of its main note", .tags(.unit))
    func graceGroup() throws {
        // Verbatim shape from the Gnossienne: `\grace { c8 } b2`
        #expect(try makeSUT().parseMusic(tokens("\\grace { c8 } b2")) == [
            .grace([note("c", dur(8))], acciaccatura: false),
            note("b", dur(2)),
        ])
    }

    @Test("parses an acciaccatura group as the very-short grace kind", .tags(.unit))
    func acciaccaturaGroup() throws {
        #expect(try makeSUT().parseMusic(tokens("\\acciaccatura { d16 } c4")) == [
            .grace([note("d", dur(16))], acciaccatura: true),
            note("c", dur(4)),
        ])
    }

    @Test("delivers a typed error on a grace group with no body", .tags(.unit))
    func graceWithoutBody() throws {
        #expect(throws: ParseError.unexpectedToken(.note(NoteToken(name: "b", duration: DurationToken(2))), index: 1)) {
            try makeSUT().parseMusic(tokens("\\grace b2"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
