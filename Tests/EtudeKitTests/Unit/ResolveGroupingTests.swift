import Testing
import EtudeKit

@Suite("Resolve grouping")
struct ResolveGroupingTests {
    @Test("nested sequences resolve transparently, in order", .tags(.unit))
    func nestedSequences() throws {
        // The shape a `\crossStaff { … }` group parses to (BUG-003): plain
        // grouping, so time and relative context flow straight through.
        let resolved = try makeSUT().resolve([
            .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: [
                note("c", dur(4)),
                .sequence([note("d"), note("e")]),
                note("f"),
            ]),
        ])
        #expect(resolved.notes.map(\.midiNote) == [60, 62, 64, 65])
        #expect(resolved.notes.map(\.startTick) == [0, 480, 960, 1440])
    }

    @Test("a new context inside music resolves as its body", .tags(.unit))
    func contextBody() throws {
        let resolved = try makeSUT().resolve([
            .context(type: "Voice", body: .sequence([note("c", dur(4)), note("d")])),
        ])
        #expect(resolved.notes.map(\.midiNote) == [48, 50])
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
