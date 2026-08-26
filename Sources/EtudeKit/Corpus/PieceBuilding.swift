// The app-facing seams (§0.3)   (Phase 5, built test-first)
//
// `CorpusProviding` answers "where do pieces come from" — a bundle today, a
// download someday — and `PieceBuilding` is the one door the app's view
// models use to run the pipeline. Both are protocols designed from the
// consumer's side so view-model tests run against spies with no real parsing.

/// Where piece sources come from.
public protocol CorpusProviding: Sendable {
    func source(for piece: CorpusPiece) throws -> String
}

/// A finished build: the assembled score, its emitted MIDI, and whatever the
/// Validator had to say. Findings are DATA here (ADR-0001) — the Diagnostics
/// screen renders them; an empty list is a clean bill.
public struct BuiltPiece: Equatable, Sendable {
    public let score: Score
    public let midi: [UInt8]
    public let findings: [ValidationFinding]

    public init(score: Score, midi: [UInt8], findings: [ValidationFinding]) {
        self.score = score
        self.midi = midi
        self.findings = findings
    }
}

/// The engine as the app sees it.
public protocol PieceBuilding: Sendable {
    func build(_ piece: CorpusPiece, tempoBeatsPerMinute: Int?) async throws -> BuiltPiece
}

extension PieceBuilding {
    public func build(_ piece: CorpusPiece) async throws -> BuiltPiece {
        try await build(piece, tempoBeatsPerMinute: nil)
    }
}

/// The real pipeline behind the seam: tokenize → parse → assemble → validate
/// (collecting findings, never repairing) → emit.
public struct EnginePieceBuilder: PieceBuilding {
    private let corpus: CorpusProviding

    public init(corpus: CorpusProviding) {
        self.corpus = corpus
    }

    public func build(
        _ piece: CorpusPiece, tempoBeatsPerMinute: Int?
    ) async throws -> BuiltPiece {
        let source = try corpus.source(for: piece)
        let file = try Parser().parseFile(try Tokenizer().tokenize(source))

        var score: Score
        if let voices = piece.voices {
            score = try ScoreBuilder().score(
                from: file, voices: voices, title: piece.title,
                velocities: piece.velocities,
                assumingBeatsPerMinute: piece.assumedBeatsPerMinute)
        } else {
            score = try ScoreBuilder().score(from: file, velocities: piece.velocities)
        }
        if let tempoBeatsPerMinute {
            score = Score(
                title: score.title,
                tempo: TempoMark(label: score.tempo?.label, beatUnit: 4,
                                 beatsPerMinute: tempoBeatsPerMinute),
                meter: score.meter, voices: score.voices)
        }

        var findings: [ValidationFinding] = []
        do {
            try Validator().validate(score)
        } catch {
            findings = error.findings
        }
        return BuiltPiece(score: score, midi: SMFWriter().bytes(for: score), findings: findings)
    }
}
