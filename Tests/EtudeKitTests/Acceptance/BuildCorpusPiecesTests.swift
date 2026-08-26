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

    @Test("the Air builds its 18 performed bars", .tags(.acceptance))
    func air() throws {
        let score = try buildPiece("air-on-the-g-string.ly")

        #expect(score.title == "Air on the G String")
        // Flute + guitar-upper only; the edition's bass has a 1-bar repeat
        // mismatch and is deliberately omitted (PLAN.md §5).
        #expect(score.voices.map(\.name) == ["melody", "accompaniment"])
        #expect(score.voices.map(\.totalTicks) == [34560, 34560])
        // The long F#5 (a tied whole + eighth), then the turn through B5.
        try Validator().validate(score, expectedOpening: [78, 83, 79, 78, 76])
    }

    @Test("the Winter Largo builds all five string parts", .tags(.acceptance))
    func winterLargo() throws {
        let score = try buildPiece("winter-largo.ly")

        #expect(score.title == "Winter (Largo)")
        #expect(score.voices.map(\.name) == ["solo", "violinOne", "violinTwo", "viola", "cello"])
        #expect(score.tempo?.beatsPerMinute == 52)
        // 18 bars of 4/4, every part.
        #expect(score.voices.map(\.totalTicks) == Array(repeating: 34560, count: 5))
        // The E-flat major solo entrance.
        try Validator().validate(score, expectedOpening: [75, 82, 80, 79, 77, 75])
    }

    @Test("the Prelude builds its 34 bars of figuration", .tags(.acceptance))
    func prelude() throws {
        let score = try buildPiece("prelude-in-c.ly")

        #expect(score.title == "Prelude in C major")
        #expect(score.voices.map(\.name) == ["figuration", "tenor", "bass"])
        #expect(score.tempo?.beatsPerMinute == 72)
        #expect(score.voices.map(\.totalTicks) == [65280, 65280, 65280])
        // The broken C-major figure: G4 C5 E5, twice.
        try Validator().validate(score, expectedOpening: [67, 72, 76, 67, 72, 76])
    }

    @Test("the Gymnopédie assembles and validates", .tags(.acceptance))
    func gymnopedie() throws {
        let score = try buildPiece("gymnopedie-1.ly")

        #expect(score.voices.map(\.name) == ["melody", "accompaniment", "bass"])
        // 78 performed bars of 3/4, every voice.
        #expect(score.voices.map(\.totalTicks) == Array(repeating: 112320, count: 3))
        try Validator().validate(score, expectedOpening: [78, 81, 79, 78])
    }

    @Test("the Gnossienne assembles and validates", .tags(.acceptance))
    func gnossienne() throws {
        let score = try buildPiece("gnossienne-1.ly")

        #expect(score.voices.map(\.name) == ["melody", "upperChords", "lowerChords", "bass"])
        // 82 performed bars of 4/4, every voice.
        #expect(score.voices.map(\.totalTicks) == Array(repeating: 157440, count: 4))
        try Validator().validate(score, expectedOpening: [72, 75, 74, 72, 72, 71])
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
