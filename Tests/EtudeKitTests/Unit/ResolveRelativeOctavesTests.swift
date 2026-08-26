import Testing
import EtudeKit

@Suite("Resolve relative octaves")
struct ResolveRelativeOctavesTests {
    @Test("places each note within a fourth of the previous", .tags(.unit))
    func withinAFourth() throws {
        // The Gymnopédie melody opening: F#5 A5 G5 F#5.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 2),
                      body: [note("fis", dur(4)), note("a"), note("g"), note("fis")]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [78, 81, 79, 78])
    }

    @Test("placement counts letters, choosing the nearer octave", .tags(.unit))
    func letterDistance() throws {
        // From c: f is three letters up (a fourth — stays up); g is three
        // letters DOWN (a fourth down beats a fifth up).
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1),
                      body: [note("f", dur(4)), note("c"), note("g"), note("c")]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [65, 60, 55, 60])
    }

    @Test("octave marks adjust after placement and the context keeps them", .tags(.unit))
    func octaveMarksAdjustPlacement() throws {
        // The Gymnopédie melody's second phrase re-enters an octave up: `fis'`.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1),
                      body: [note("fis", dur(4)), note("fis", marks: 1), note("a")]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [66, 78, 81])
    }

    @Test("a bare relative block anchors at the f below middle C", .tags(.unit))
    func bareAnchor() throws {
        // Verbatim shape from the Gnossienne: `\relative { r4 c''8 … }`
        let resolved = try makeSUT().resolve([
            .relative(anchor: nil, body: [
                .rest(RestToken(kind: .sounding, duration: dur(4))),
                note("c", marks: 2, dur(8)),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [72])
    }

    @Test("alterations never change the chosen octave", .tags(.unit))
    func alterationsDoNotMovePlacement() throws {
        // b to f: three letters down by letter count, even though b→f
        // downward is an augmented fourth in semitones.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1),
                      body: [note("b", dur(4)), note("fis")]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [59, 54])
    }

    @Test("music after the relative block is absolute again", .tags(.unit))
    func absoluteAfterBlock() throws {
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 2), body: [note("g", dur(4))]),
            note("c", dur(4)),
        ])
        #expect(resolved.notes.map(\.midiNote) == [67, 48])
    }

    @Test("a pitched rest sounds nothing but threads the context", .tags(.unit))
    func pitchedRestThreadsContext() throws {
        // Verbatim shape from the Gymnopédie endings: `e4\rest <g e b>2` —
        // the written e places the following chord, silently.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: [
                .pitchedRest(NoteToken(name: "e", duration: dur(4))),
                .chord([NoteToken(name: "g"), NoteToken(name: "e"), NoteToken(name: "b")],
                       duration: dur(2), tied: false),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [67, 64, 59])
        #expect(resolved.notes.map(\.startTick) == [480, 480, 480])
        #expect(resolved.totalTicks == 480 + 960)
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
