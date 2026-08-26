import Testing
import EtudeKit

@Suite("Resolve chords")
struct ResolveChordsTests {
    @Test("chord notes sound together for the written duration", .tags(.unit))
    func chordTiming() throws {
        let resolved = try makeSUT().resolve([
            .chord([NoteToken(name: "c"), NoteToken(name: "e"), NoteToken(name: "g")],
                   duration: dur(2), tied: false),
            note("c", dur(4)),
        ])
        #expect(resolved.notes.map(\.midiNote) == [48, 52, 55, 48])
        #expect(resolved.notes.map(\.startTick) == [0, 0, 0, 960])
        #expect(resolved.notes.map(\.durationTicks) == [960, 960, 960, 480])
    }

    @Test("relative chords follow LilyPond's first-note rule", .tags(.unit))
    func firstNoteRule() throws {
        // Verbatim shape from the Gymnopédie accompaniment. The first chord
        // note relates to the previous context, later notes relate within the
        // chord, and the context afterwards continues from the FIRST note.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: [
                .rest(RestToken(kind: .sounding, duration: dur(4))),
                .chord([NoteToken(name: "fis"), NoteToken(name: "d"), NoteToken(name: "b")],
                       duration: dur(2), tied: false),
                .rest(RestToken(kind: .sounding, duration: dur(4))),
                .chord([NoteToken(name: "fis"), NoteToken(name: "cis"), NoteToken(name: "a")],
                       duration: dur(2), tied: false),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [66, 62, 59, 66, 61, 57])
    }

    @Test("a chord note's octave marks adjust within the chord", .tags(.unit))
    func chordOctaveMarks() throws {
        // Verbatim shape from the Gymnopédie first ending: `<c' a e c>2.`
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: [
                note("fis", marks: -1, dur(2, dots: 1)),
                .chord([NoteToken(name: "c", octaveMarks: 1), NoteToken(name: "a"),
                        NoteToken(name: "e"), NoteToken(name: "c")],
                       duration: dur(2, dots: 1), tied: false),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [54, 60, 57, 52, 48])
    }

    @Test("the q repeat re-sounds the previous chord with its own duration", .tags(.unit))
    func chordRepeat() throws {
        // Verbatim shape from the Gnossienne accompaniment: `s4 <c' f>2 q4`
        let resolved = try makeSUT().resolve([
            .relative(anchor: nil, body: [
                .rest(RestToken(kind: .spacer, duration: dur(4))),
                .chord([NoteToken(name: "c", octaveMarks: 1), NoteToken(name: "f")],
                       duration: dur(2), tied: false),
                .chordRepeat(duration: dur(4)),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [60, 65, 60, 65])
        #expect(resolved.notes.map(\.startTick) == [480, 480, 1440, 1440])
        #expect(resolved.notes.map(\.durationTicks) == [960, 960, 480, 480])
    }

    @Test("delivers a typed error on q with no chord before it", .tags(.unit))
    func repeatWithoutChord() throws {
        #expect(throws: ResolveError.chordRepeatWithoutChord) {
            try makeSUT().resolve([.chordRepeat(duration: dur(4))])
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
