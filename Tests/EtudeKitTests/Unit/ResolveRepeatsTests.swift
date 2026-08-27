import Testing
import EtudeKit

@Suite("Resolve repeats")
struct ResolveRepeatsTests {
    @Test("unfold writes the body out count times", .tags(.unit))
    func unfoldCopies() throws {
        let resolved = try makeSUT().resolve([
            .repeated(.unfold, count: 3, body: [note("c", dur(4)), note("d", dur(2))],
                      alternatives: []),
        ])
        #expect(resolved.notes.map(\.midiNote) == [48, 50, 48, 50, 48, 50])
        #expect(resolved.notes.map(\.startTick) == [0, 480, 1440, 1920, 2880, 3360])
        #expect(resolved.totalTicks == 3 * 1440)
    }

    @Test("the relative context enters an unfold body once, not per pass", .tags(.unit))
    func contextEntersOnce() throws {
        // The Gnossienne bass shape: `\repeat unfold 6 { f,1 | } c'1` — every
        // pass sounds the SAME low F; re-threading the marks would spiral
        // F2→F1→F0 (BUG-002's symptom).
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c"), body: [
                .repeated(.unfold, count: 2, body: [note("f", marks: -1, dur(1))],
                          alternatives: []),
                note("c", marks: 1, dur(1)),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [41, 41, 48])
    }

    @Test("ties merge inside each pass independently", .tags(.unit))
    func tiesStayWithinPasses() throws {
        let resolved = try makeSUT().resolve([
            .repeated(.unfold, count: 2,
                      body: [note("c", dur(2), tied: true), note("c", dur(2))],
                      alternatives: []),
        ])
        #expect(resolved.notes == [
            ResolvedNote(midiNote: 48, startTick: 0, durationTicks: 1920),
            ResolvedNote(midiNote: 48, startTick: 1920, durationTicks: 1920),
        ])
    }

    @Test("volta performs body then each alternative in turn", .tags(.unit))
    func voltaWithAlternatives() throws {
        // The Gymnopédie shape: volta 2 with two endings = body+first,
        // body+second.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c"), body: [
                .repeated(.volta, count: 2,
                          body: [note("g", dur(2, dots: 1)), note("d", dur(2, dots: 1))],
                          alternatives: [[note("e", dur(2, dots: 1))], [note("f", dur(2, dots: 1))]]),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [43, 38, 40, 43, 38, 41])
        #expect(resolved.notes.map(\.startTick) == [0, 1440, 2880, 4320, 5760, 7200])
        #expect(resolved.totalTicks == 6 * 1440)
    }

    @Test("alternatives thread the relative context in written order", .tags(.unit))
    func alternativesThreadInWrittenOrder() throws {
        // LilyPond converts \relative to absolute pitches by walking the
        // SOURCE, before any repeat is performed — so the second ending's
        // octave follows the first ending's last note, not the body's.
        // (BUG-007's sibling: the Gymnopédie original writes its second
        // ending as `e,2.`, which only lands on E2 this way — from the
        // body-end context it would fall to E1.)
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: [
                .repeated(.volta, count: 2,
                          body: [note("c", dur(4))],
                          alternatives: [[note("g", marks: 1, dur(4))], [note("g", dur(4))]]),
            ]),
        ])
        // Body C4; first ending places g down to G3, the mark lifts it to G4;
        // the second ending's bare g holds that G4 — placed from the first
        // ending's end, NOT dropped back to the body's C4.
        #expect(resolved.notes.map(\.midiNote) == [60, 67, 60, 67])
    }

    @Test("volta without alternatives simply plays the body count times", .tags(.unit))
    func voltaWithoutAlternatives() throws {
        let resolved = try makeSUT().resolve([
            .repeated(.volta, count: 2, body: [note("c", dur(4))], alternatives: []),
        ])
        #expect(resolved.notes.map(\.midiNote) == [48, 48])
        #expect(resolved.totalTicks == 960)
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
