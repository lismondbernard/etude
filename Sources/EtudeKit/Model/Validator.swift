// Validator — invariants as first-class code   (Phase 3, built test-first)
//
// Findings are DATA, not just a throw: the whole list is gathered and thrown
// together so a diagnostics screen (or a test failure message) can show every
// violation at once. The Validator never repairs a score — clamping is how
// BUG-004 stayed hidden (ADR-0001).

/// One invariant violation, in the musician's vocabulary.
public enum ValidationFinding: Equatable, Sendable {
    /// A voice's performed span differs from the longest voice's.
    case voiceMisaligned(voice: String, ticks: Int, expectedTicks: Int)
    /// A pitch outside the plausible instrument range (A0…C8) — an octave
    /// artifact from resolution, not music (BUG-004/006).
    case registerViolation(voice: String, pitch: UInt8)
}

/// Thrown when validation finds anything — carrying all findings, not the first.
public struct ValidationError: Error, Equatable, Sendable {
    public let findings: [ValidationFinding]

    public init(findings: [ValidationFinding]) {
        self.findings = findings
    }
}

/// Runs every invariant over a score and throws the collected findings.
public struct Validator: Sendable {
    public init() {}

    public func validate(_ score: Score) throws(ValidationError) {
        var findings: [ValidationFinding] = []
        findings += alignmentFindings(score)
        findings += registerFindings(score)
        guard findings.isEmpty else { throw ValidationError(findings: findings) }
    }

    /// Invariant 1 — voice alignment: simultaneous voices span equal ticks.
    /// (The check that exposed Clair de Lune's 91/46/57/54-beat mismatch.)
    private func alignmentFindings(_ score: Score) -> [ValidationFinding] {
        guard let longest = score.voices.map(\.totalTicks).max() else { return [] }
        return score.voices
            .filter { $0.totalTicks != longest }
            .map { .voiceMisaligned(voice: $0.name, ticks: $0.totalTicks, expectedTicks: longest) }
    }

    /// Invariant 2 — register sanity: every pitch within the piano's A0…C8.
    /// One finding per offending pitch value per voice keeps the list readable
    /// when a whole drifted passage violates.
    private func registerFindings(_ score: Score) -> [ValidationFinding] {
        let plausible: ClosedRange<UInt8> = 21...108
        return score.voices.flatMap { voice in
            var seen = Set<UInt8>()
            return voice.events.compactMap { event -> ValidationFinding? in
                guard !plausible.contains(event.pitch), seen.insert(event.pitch).inserted else {
                    return nil
                }
                return .registerViolation(voice: voice.name, pitch: event.pitch)
            }
        }
    }
}
