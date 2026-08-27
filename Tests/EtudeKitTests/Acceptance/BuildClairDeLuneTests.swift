import Testing
import Foundation
import EtudeKit

/// The boss fight (PLAN.md §7) — won in two acts.
///
/// Phase 4 solved the part the prototype never managed: `\parallelMusic`
/// expands to four voices of 72 bars whose SEVEN sections are each whole-bar
/// aligned (the prototype's section 1 timed out at 91/46/57/54 beats across
/// voices, BUG-006), and the compact and expanded sources agree note for note.
///
/// Issue #1 closed the rest: lhDown drifted below the piano's floor in bars
/// 8–13, 22–24, and 63–65. Recovering Keith O'Hara's Mutopia original showed
/// TWO defects conspiring — the vendored §1 anchor had been "corrected" away
/// from the original's `c'`, and the resolver placed `<< >>` children from
/// the group's door where LilyPond threads the relative context through them
/// in source order. With both fixed (each proven against Mutopia's own MIDI
/// rendering), every bar of every voice sits on the piano and the register
/// invariant holds with no known-issue wrapper left.
@Suite("Build Clair de Lune")
struct BuildClairDeLuneTests {
    @Test("the boss fight: aligned, fingerprinted, and on the piano", .tags(.acceptance))
    func bossFight() throws {
        let file = try parseCorpus("clair-de-lune.ly")
        let score = try ScoreBuilder().score(
            from: file, voices: ["rhUp", "rhDown", "lhUp", "lhDown"],
            title: "Clair de Lune",
            velocities: ["rhUp": 82, "rhDown": 82, "lhUp": 72, "lhDown": 72],
            assumingBeatsPerMinute: 60)

        // 72 bars of 9/8 in every voice — the alignment the prototype never had.
        #expect(score.voices.map(\.totalTicks) == Array(repeating: 72 * 2160, count: 4))
        #expect(score.tempo == TempoMark(label: "Andante très expressif",
                                         beatUnit: 4, beatsPerMinute: 60))
        // The famous opening thirds: F4+A♭4, F5+A♭5, D♭5+F5.
        #expect(score.voices[0].events.prefix(6).map(\.pitch) == [65, 68, 77, 80, 73, 77])

        // All four invariants, no wrapper: the byte-stable rendering is pinned
        // by the standard golden test now that the piece carries no known issue.
        try Validator().validate(score)
    }

    // MARK: - Helpers

    private func parseCorpus(_ name: String) throws -> LilyFile {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name)
        return try Parser().parseFile(try Tokenizer().tokenize(String(contentsOf: url, encoding: .utf8)))
    }
}
