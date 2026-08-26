import Testing
import Foundation
import EtudeKit

/// The boss fight (PLAN.md §7), where it actually stands after the rewrite.
///
/// SOLVED — the part the prototype never managed: `\parallelMusic` expands to
/// four voices of 72 bars whose SEVEN sections are each whole-bar aligned
/// (the prototype's section 1 timed out at 91/46/57/54 beats across voices,
/// BUG-006). The opening thirds resolve to their famous pitches, and the
/// compact and expanded sources agree note for note.
///
/// KNOWN ISSUE #1 — lhDown drifts below the piano's floor (to MIDI 3) in
/// bars 8–13, 22–24, and 63–65: an `af,` entering bar 8 already sits at A♭0
/// and the marks keep pushing down. LilyPond's own rules produce the same
/// pitches from this text, so the defect is in the vendored source — octave
/// marks apparently lost when the prototype cleaned the Mutopia edition.
/// Recovering the original source is the fix; the register invariant keeps
/// the wound loud until then (ADR-0003: known issues stay visible).
@Suite("Build Clair de Lune")
struct BuildClairDeLuneTests {
    @Test("the boss fight: aligned, fingerprinted, register drift on record", .tags(.acceptance))
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

        withKnownIssue("lhDown register drift below A0 — issue #1") {
            try Validator().validate(score)
        }

        // The known-issue rendering is still pinned byte-for-byte: the golden
        // records today's output so any change to it is a loud, reviewed event.
        let bytes = SMFWriter().bytes(for: score)
        #expect(bytes == SMFWriter().bytes(for: score))
        let fixture = fixtureURL("clair-de-lune.mid")
        guard FileManager.default.fileExists(atPath: fixture.path) else {
            try Data(bytes).write(to: fixture)
            Issue.record("No golden existed — recorded one; rerun to verify")
            return
        }
        #expect(Data(bytes) == (try Data(contentsOf: fixture)))
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

    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Golden")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
    }
}
