import Testing
import EtudeKit

@Suite("Resolve tuplets")
struct ResolveTupletsTests {
    @Test("durations inside a tuplet scale by its fraction", .tags(.unit))
    func scalesDurations() throws {
        // Verbatim shape from Clair de Lune: `\times 3/2 { df f }` — two
        // notes stretched into triple time.
        let resolved = try makeSUT().resolve([
            .tuplet(scaleNumerator: 3, scaleDenominator: 2,
                    body: [note("c", dur(8)), note("d", dur(8))]),
            note("e", dur(4)),
        ])
        #expect(resolved.notes.map(\.durationTicks) == [360, 360, 480])
        #expect(resolved.notes.map(\.startTick) == [0, 360, 720])
        #expect(resolved.totalTicks == 1200)
    }

    @Test("a triplet fits three notes in the time of two", .tags(.unit))
    func triplet() throws {
        let resolved = try makeSUT().resolve([
            .tuplet(scaleNumerator: 2, scaleDenominator: 3,
                    body: [note("c", dur(8)), note("d", dur(8)), note("e", dur(8))]),
        ])
        #expect(resolved.notes.map(\.durationTicks) == [160, 160, 160])
        #expect(resolved.totalTicks == 480)
    }

    @Test("the sticky duration leaves a tuplet unscaled", .tags(.unit))
    func stickyDurationUnscaled() throws {
        let resolved = try makeSUT().resolve([
            .tuplet(scaleNumerator: 2, scaleDenominator: 3, body: [note("c", dur(8))]),
            note("d"),
        ])
        // The d carries the written eighth — 240 ticks, not the scaled 160.
        #expect(resolved.notes.map(\.durationTicks) == [160, 240])
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
