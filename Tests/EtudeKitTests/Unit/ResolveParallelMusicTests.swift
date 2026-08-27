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

    @Test("relative context threads through children in source order", .tags(.unit))
    func childrenThreadTheRelativeContext() throws {
        // LilyPond's rule, and the issue-#1 lesson: for octave purposes the
        // children of `<< … >>` resolve AS IF WRITTEN SEQUENTIALLY — each
        // starts where the previous child's context ended, and the LAST
        // child's end leads afterwards. (Phase 3 encoded the intuitive
        // every-child-from-the-door rule instead; LilyPond's own MIDI of the
        // Mutopia Clair de Lune refuted it, bar by bar, in the bass climb of
        // bars 19–24.)
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: [
                note("c", dur(4)),
                .parallel([
                    .sequence([note("e", dur(4)), note("f")]),
                    .sequence([note("g", dur(4)), note("a")]),
                ]),
                note("b", dur(4)),
            ]),
        ])
        // Child two's g places from child one's F4 (up to G4) — NOT from C4.
        // The closing b places from child two's A4 — NOT from child one's F4.
        #expect(resolved.notes.map(\.midiNote) == [60, 64, 65, 67, 69, 71])
    }

    @Test("the Gnossienne ossia wrapper resolves to the same A-flats", .tags(.unit))
    func gnossienneOssiaShape() throws {
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
