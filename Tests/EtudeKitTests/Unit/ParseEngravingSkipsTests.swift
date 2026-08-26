import Testing
import EtudeKit

// The parse tree is a PERFORMING representation — engraving instructions
// (slurs, stems, layout breaks) change how a score looks, not how it sounds,
// so they parse to nothing rather than polluting the tree.
@Suite("Parse engraving skips")
struct ParseEngravingSkipsTests {
    @Test("skips slurs and bar checks between notes", .tags(.unit))
    func slursAndBarChecks() throws {
        // Verbatim shape from the Gymnopédie melody: `s4 fis( a g fis … d2.~ d2) d4 |`
        #expect(try makeSUT().parseMusic(tokens("fis( a) c |")) == [
            note("fis"), note("a"), note("c"),
        ])
    }

    @Test("skips voicing and visibility commands", .tags(.unit), arguments: [
        "voiceOne", "voiceTwo", "once", "hideNotes", "stemUp", "stemDown", "stemNeutral",
        "tieUp", "tieDown", "tieNeutral", "slurUp", "slurDown", "phrasingSlurUp",
        "dynamicUp", "break", "pageBreak",
    ])
    func engravingCommands(command: String) throws {
        #expect(try makeSUT().parseMusic(tokens("c \\\(command) d")) == [
            note("c"), note("d"),
        ])
    }

    @Test("skips a version or language declaration with its argument", .tags(.unit))
    func declarationsWithArguments() throws {
        #expect(try makeSUT().parseMusic(tokens("\\version \"2.24.0\" \\language \"english\" cs")) == [
            note("cs"),
        ])
    }

    @Test("skips dynamics and per-note effect commands", .tags(.unit), arguments: [
        "pp", "ppp", "p", "mp", "mf", "f", "ff", "fff", "sf",
        "arpeggio", "sustainOn", "sustainOff", "slurNeutral",
        "mergeDifferentlyDottedOn", "mergeDifferentlyHeadedOn",
    ])
    func dynamicsAndEffects(command: String) throws {
        #expect(try makeSUT().parseMusic(tokens("c \\\(command) d")) == [
            note("c"), note("d"),
        ])
    }

    @Test("skips commands that carry an argument", .tags(.unit), arguments: [
        "\\clef bass", "\\clef \"treble\"", "\\ottava #1", "\\barNumberCheck#66",
        "\\change Staff = \"upper\"",
    ])
    func argumentedCommands(fragment: String) throws {
        #expect(try makeSUT().parseMusic(tokens("c \(fragment) d")) == [
            note("c"), note("d"),
        ])
    }

    @Test("skips an override through its assigned value", .tags(.unit))
    func overrides() throws {
        // Verbatim shapes from Clair de Lune's prelude definitions.
        let source = "c \\override Beam #'damping = #3 d \\override NoteColumn #'ignore-collision = ##t e"
        #expect(try makeSUT().parseMusic(tokens(source)) == [
            note("c"), note("d"), note("e"),
        ])
    }

    @Test("skips a markup chain with its text", .tags(.unit))
    func markup() throws {
        // Verbatim shape from Clair de Lune: `r4\ppp^\markup\italic"morendo jusqu'à la fin"`
        #expect(try makeSUT().parseMusic(tokens("r4 \\markup \\italic \"morendo\" c")) == [
            .rest(RestToken(kind: .sounding, duration: dur(4))),
            note("c"),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
