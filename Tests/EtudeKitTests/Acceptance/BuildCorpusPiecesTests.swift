import Testing
import Foundation
import EtudeKit

/// Phase 3 acceptance (PLAN.md §10): every corpus piece builds through the
/// whole pipeline — tokenize → parse → resolve → assemble → validate — and
/// lands on its known shape (Appendix B).
@Suite("Build corpus pieces")
struct BuildCorpusPiecesTests {
    @Test("the Minuet builds its full AABB form", .tags(.acceptance))
    func minuet() throws {
        let score = try buildPiece("minuet-in-g.ly")

        #expect(score.title == "Minuet in G major")
        #expect(score.voices.map(\.name) == ["melody", "bass"])
        #expect(score.tempo?.beatsPerMinute == 126)
        // AABB: two 16-bar sections, each played twice, in 3/4.
        #expect(score.voices.map(\.totalTicks) == [92160, 92160])
        try Validator().validate(score, expectedOpening: [74, 67, 69, 71, 72])
    }

    // MARK: - Helpers

    /// The whole pipeline up to a validated, assembled score.
    func buildPiece(_ name: String, velocities: [String: UInt8] = [:]) throws -> Score {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name)
        let source = try String(contentsOf: url, encoding: .utf8)
        let file = try Parser().parseFile(try Tokenizer().tokenize(source))
        return try ScoreBuilder().score(from: file, velocities: velocities)
    }
}
