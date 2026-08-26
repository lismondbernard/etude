import Testing
import EtudeKit

@Suite("Resolve ornaments")
struct ResolveOrnamentsTests {
    @Test("a mordent dips to the lower scale neighbor and back", .tags(.unit))
    func mordent() throws {
        // The Minuet's `c8\mordent` in G major: c–b–c in a 1:1:2 split.
        let resolved = try makeSUT().resolve(try music("\\key g \\major c'8\\mordent d8"))
        #expect(resolved.notes == [
            ResolvedNote(midiNote: 60, startTick: 0, durationTicks: 60),
            ResolvedNote(midiNote: 59, startTick: 60, durationTicks: 60),
            ResolvedNote(midiNote: 60, startTick: 120, durationTicks: 120),
            ResolvedNote(midiNote: 50, startTick: 240, durationTicks: 240),
        ])
    }

    @Test("a prall flicks to the upper scale neighbor", .tags(.unit))
    func prall() throws {
        let resolved = try makeSUT().resolve(try music("\\key g \\major b'4\\prall"))
        #expect(resolved.notes.map(\.midiNote) == [71, 72, 71])
        #expect(resolved.notes.map(\.durationTicks) == [120, 120, 240])
    }

    @Test("the neighbor search walks past non-scale semitones", .tags(.unit))
    func neighborSkipsNonScaleTones() throws {
        // In G major a mordent on f-sharp must dip past f-natural to e.
        let resolved = try makeSUT().resolve(try music("\\key g \\major fis'4\\mordent"))
        #expect(resolved.notes.map(\.midiNote) == [66, 64, 66])
    }

    @Test("an ornament with no key to walk in is loud, not skipped", .tags(.unit))
    func ornamentWithoutKey() throws {
        // The prototype silently skipped ornaments when no scale was set —
        // ADR-0001 says surface it.
        #expect(throws: ResolveError.ornamentWithoutKey) {
            try makeSUT().resolve(try music("c'4\\mordent"))
        }
    }

    @Test("an ornament with nothing to sit on is loud too", .tags(.unit))
    func ornamentWithoutNote() throws {
        #expect(throws: ResolveError.ornamentWithoutNote) {
            try makeSUT().resolve(try music("\\key g \\major r4\\mordent"))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }

    private func music(_ source: String) throws -> [MusicNode] {
        try Parser().parseMusic(try Tokenizer().tokenize(source))
    }
}
