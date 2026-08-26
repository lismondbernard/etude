import Testing
import EtudeKit

@Suite("Resolve grace notes")
struct ResolveGraceNotesTests {
    @Test("a grace note delays and shortens the note it precedes", .tags(.unit))
    func stealsFromFollowingNote() throws {
        // Verbatim shape from the Gnossienne: `\grace { c8 } b2` — the bar
        // still totals a half note; the grace takes its eighth off the front.
        let resolved = try makeSUT().resolve([
            .grace([note("c", marks: 2, dur(8))], acciaccatura: false),
            note("b", marks: 1, dur(2)),
        ])
        #expect(resolved.notes == [
            ResolvedNote(midiNote: 72, startTick: 0, durationTicks: 240),
            ResolvedNote(midiNote: 71, startTick: 240, durationTicks: 720),
        ])
        #expect(resolved.totalTicks == 960)
    }

    @Test("grace pitches thread the relative context", .tags(.unit))
    func threadsRelativeContext() throws {
        let resolved = try makeSUT().resolve([
            .relative(anchor: nil, body: [
                note("c", marks: 2, dur(4)),
                .grace([note("e", dur(8))], acciaccatura: false),
                note("f", dur(2)),
            ]),
        ])
        // c'' → C5; grace e a third above; f placed from the grace's e.
        #expect(resolved.notes.map(\.midiNote) == [72, 76, 77])
    }

    @Test("an acciaccatura is very short whatever it writes", .tags(.unit))
    func acciaccaturaIsVeryShort() throws {
        let resolved = try makeSUT().resolve([
            .grace([note("d", dur(8))], acciaccatura: true),
            note("c", dur(4)),
        ])
        // A thirty-second of theft, not the written eighth.
        #expect(resolved.notes == [
            ResolvedNote(midiNote: 50, startTick: 0, durationTicks: 60),
            ResolvedNote(midiNote: 48, startTick: 60, durationTicks: 420),
        ])
        #expect(resolved.totalTicks == 480)
    }

    @Test("a grace before a tied pair still merges the pair", .tags(.unit))
    func graceThenTiedPair() throws {
        // Verbatim shape from the Gnossienne: `\grace { g8 } f4 ~ f2`
        let resolved = try makeSUT().resolve([
            .grace([note("g", dur(8))], acciaccatura: false),
            note("f", dur(4), tied: true),
            note("f", dur(2)),
        ])
        #expect(resolved.notes == [
            ResolvedNote(midiNote: 55, startTick: 0, durationTicks: 240),
            ResolvedNote(midiNote: 53, startTick: 240, durationTicks: 240 + 960),
        ])
        #expect(resolved.totalTicks == 480 + 960)
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
