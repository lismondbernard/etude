import Testing
import EtudeKit

@Suite("Parse chords")
struct ParseChordsTests {
    @Test("parses a chord's pitches and written duration", .tags(.unit))
    func chordWithDuration() throws {
        // Verbatim shape from the Gymnopédie accompaniment.
        #expect(try makeSUT().parseMusic(tokens("<fis d b>2")) == [
            .chord([NoteToken(name: "fis"), NoteToken(name: "d"), NoteToken(name: "b")],
                   duration: dur(2), tied: false),
        ])
    }

    @Test("chord pitches keep their octave marks", .tags(.unit))
    func chordOctaveMarks() throws {
        #expect(try makeSUT().parseMusic(tokens("<c' a e c>2.")) == [
            .chord([NoteToken(name: "c", octaveMarks: 1), NoteToken(name: "a"),
                    NoteToken(name: "e"), NoteToken(name: "c")],
                   duration: dur(2, dots: 1), tied: false),
        ])
    }

    @Test("attaches a tie to the preceding chord", .tags(.unit))
    func chordTie() throws {
        #expect(try makeSUT().parseMusic(tokens("<f aes>2 ~ <f aes>4")) == [
            .chord([NoteToken(name: "f"), NoteToken(name: "aes")], duration: dur(2), tied: true),
            .chord([NoteToken(name: "f"), NoteToken(name: "aes")], duration: dur(4), tied: false),
        ])
    }

    @Test("parses the q chord repeat with its own duration", .tags(.unit))
    func chordRepeat() throws {
        // Verbatim shape from the Gnossienne: `s4 <c' f>2 q4`
        #expect(try makeSUT().parseMusic(tokens("<c f>2 q4")) == [
            .chord([NoteToken(name: "c"), NoteToken(name: "f")], duration: dur(2), tied: false),
            .chordRepeat(duration: dur(4)),
        ])
    }

    @Test("delivers a typed error on a non-pitch inside a chord", .tags(.unit))
    func nonPitchInsideChord() throws {
        #expect(throws: ParseError.unexpectedToken(.rest(RestToken(kind: .sounding)), index: 2)) {
            try makeSUT().parseMusic(tokens("<c r g>2"))
        }
    }

    @Test("a separated duration times the preceding event", .tags(.unit))
    func separatedDuration() throws {
        // Verbatim shape from Clair de Lune: `<f' af> ~ <f af> 4.`
        #expect(try makeSUT().parseMusic(tokens("<f a>2 ~ <f a> 4. c")) == [
            .chord([NoteToken(name: "f"), NoteToken(name: "a")], duration: dur(2), tied: true),
            .chord([NoteToken(name: "f"), NoteToken(name: "a")],
                   duration: dur(4, dots: 1), tied: false),
            note("c"),
        ])
    }

    @Test("delivers a typed error on a duration with nothing before it", .tags(.unit))
    func strayDuration() throws {
        #expect(throws: ParseError.unexpectedToken(.duration(DurationToken(4, dots: 1)), index: 0)) {
            try makeSUT().parseMusic(tokens("4. c"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
