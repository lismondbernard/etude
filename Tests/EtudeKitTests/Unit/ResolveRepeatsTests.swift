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

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
