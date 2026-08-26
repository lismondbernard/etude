import Testing
import EtudeKit

@Suite("Resolve parallel music")
struct ResolveParallelMusicTests {
    @Test("parallel children start together and the longest sets the span", .tags(.unit))
    func simultaneousChildren() throws {
        let resolved = try makeSUT().resolve([
            .parallel([
                .sequence([note("c", dur(4)), note("d", dur(4))]),
                .sequence([note("e", dur(2))]),
            ]),
            note("f", dur(4)),
        ])
        #expect(resolved.notes.map(\.midiNote) == [48, 50, 52, 53])
        #expect(resolved.notes.map(\.startTick) == [0, 480, 0, 960])
        #expect(resolved.totalTicks == 1440)
    }

    @Test("the relative context threads the children in source order", .tags(.unit))
    func contextThreadsInSourceOrder() throws {
        // Verbatim shape from the Gnossienne accompaniment (BUG-005 territory):
        // `af4\rest <<af2 \new Voice{ … af4 }>> af4` — every af is the same
        // A-flat 3, hidden or not (\hideNotes affects print, never MIDI).
        let resolved = try makeSUT().resolve([
            .relative(anchor: nil, body: [
                .pitchedRest(NoteToken(name: "af", duration: dur(4))),
                .parallel([
                    note("af", dur(2)),
                    .context(type: "Voice", body: .sequence([note("af", dur(4))])),
                ]),
                note("af", dur(4)),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [56, 56, 56])
        #expect(resolved.notes.map(\.startTick) == [480, 480, 1440])
        #expect(resolved.totalTicks == 480 + 960 + 480)
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
