import Testing
import EtudeKit

@Suite("Resolve durations")
struct ResolveDurationsTests {
    @Test("advances time by each written duration", .tags(.unit))
    func writtenDurations() throws {
        let resolved = try makeSUT().resolve([note("c", dur(4)), note("d", dur(2)), note("e", dur(8))])
        #expect(resolved.notes.map(\.startTick) == [0, 480, 1440])
        #expect(resolved.notes.map(\.durationTicks) == [480, 960, 240])
        #expect(resolved.totalTicks == 1680)
    }

    @Test("a dot extends a duration by half, and dots compound", .tags(.unit))
    func dottedDurations() throws {
        let resolved = try makeSUT().resolve([note("c", dur(2, dots: 1)), note("d", dur(4, dots: 2))])
        #expect(resolved.notes.map(\.durationTicks) == [1440, 840])
    }

    @Test("rests advance time without sounding", .tags(.unit))
    func rests() throws {
        // All three written kinds are performed identically: silence.
        let resolved = try makeSUT().resolve([
            .rest(RestToken(kind: .sounding, duration: dur(4))),
            note("c", dur(4)),
            .rest(RestToken(kind: .spacer, duration: dur(4))),
            .rest(RestToken(kind: .multiMeasure, duration: dur(2, dots: 1))),
        ])
        #expect(resolved.notes == [ResolvedNote(midiNote: 48, startTick: 480, durationTicks: 480)])
        #expect(resolved.totalTicks == 480 + 480 + 480 + 1440)
    }

    @Test("carries the previous duration when a note writes none", .tags(.unit))
    func stickyDuration() throws {
        // Verbatim shape from the Gymnopédie melody: `s4 fis( a g fis …`
        let resolved = try makeSUT().resolve([
            .rest(RestToken(kind: .spacer, duration: dur(4))),
            note("fis"), note("a", dur(2)), note("g"),
        ])
        #expect(resolved.notes.map(\.durationTicks) == [480, 960, 960])
        #expect(resolved.totalTicks == 480 + 480 + 960 + 960)
    }

    @Test("an unwritten duration at the very start is a quarter", .tags(.unit))
    func defaultDuration() throws {
        #expect(try makeSUT().resolve([note("c")]).totalTicks == 480)
    }

    @Test("a written multiplier scales the event's span", .tags(.unit))
    func durationMultipliers() throws {
        // Clair de Lune fills whole 9/8 bars with `s8*9` — and pins a hairpin
        // to a point in time with the zero-width `s8*0`.
        let resolved = try makeSUT().resolve([
            .rest(RestToken(kind: .spacer, duration: DurationToken(8, multiplier: (9, 1)))),
            .rest(RestToken(kind: .spacer, duration: DurationToken(8, multiplier: (0, 1)))),
            note("c", DurationToken(4, multiplier: (3, 2))),
        ])
        #expect(resolved.notes == [ResolvedNote(midiNote: 48, startTick: 2160, durationTicks: 720)])
        #expect(resolved.totalTicks == 2160 + 720)
    }

    @Test("the sticky duration carries its multiplier", .tags(.unit))
    func stickyMultiplier() throws {
        let resolved = try makeSUT().resolve([
            .rest(RestToken(kind: .spacer, duration: DurationToken(8, multiplier: (9, 1)))),
            .rest(RestToken(kind: .spacer)),
        ])
        #expect(resolved.totalTicks == 4320)
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
