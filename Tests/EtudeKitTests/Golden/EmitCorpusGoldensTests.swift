import Testing
import Foundation
import EtudeKit

/// Phase 3 acceptance (PLAN.md §10): every piece emits byte-stable MIDI that
/// matches its golden fixture. The fixtures are the SWIFT writer's baseline
/// (PLAN.md §5 — re-baselined from the prototype's; see Fixtures/README.md
/// for provenance). An intentional output change means deleting the fixture,
/// rerunning to re-record, and reviewing the new bytes in the commit.
@Suite("Emit corpus goldens")
struct EmitCorpusGoldensTests {
    @Test("emits byte-stable output matching the golden fixture", .tags(.golden),
          arguments: CorpusPiece.all.filter { $0.knownIssue == nil }.map(\.id))
    func golden(piece: String) throws {
        let spec = CorpusPiece.all.first { $0.id == piece }!
        let source = try String(contentsOf: corpusURL(piece), encoding: .utf8)
        let file = try Parser().parseFile(try Tokenizer().tokenize(source))
        // Build exactly as the catalog specifies: sources without a \score
        // block (Clair de Lune) name their voices explicitly.
        let score: Score = if let voices = spec.voices {
            try ScoreBuilder().score(
                from: file, voices: voices, title: spec.title,
                velocities: spec.velocities,
                assumingBeatsPerMinute: spec.assumedBeatsPerMinute)
        } else {
            try ScoreBuilder().score(from: file, velocities: spec.velocities)
        }
        try Validator().validate(score)

        let bytes = RunningStatusSMFWriter().bytes(for: score)
        #expect(bytes == RunningStatusSMFWriter().bytes(for: score),
                "two consecutive runs must emit identical bytes")

        let fixture = fixtureURL(piece + ".mid")
        guard FileManager.default.fileExists(atPath: fixture.path) else {
            try Data(bytes).write(to: fixture)
            Issue.record("No golden existed for \(piece) — recorded one; rerun to verify")
            return
        }
        #expect(Data(bytes) == (try Data(contentsOf: fixture)),
                "\(piece) no longer matches its golden — if intended, delete and re-record")
    }

    // MARK: - Helpers

    private func corpusURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name + ".ly")
    }

    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
    }
}
