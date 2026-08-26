import EtudeKit

/// Pure formatting of Validator findings into the musician's vocabulary —
/// functions, not a view model (§0.9: Diagnostics has no async state worth
/// one). The app is as candid here as the tests are (ADR-0001/0003).
enum DiagnosticsPresenter {
    static func summary(for findings: [ValidationFinding]) -> String {
        findings.isEmpty
            ? "All invariants hold."
            : "\(findings.count) finding\(findings.count == 1 ? "" : "s") — this piece ships honest."
    }

    static func line(for finding: ValidationFinding) -> String {
        switch finding {
        case .voiceMisaligned(let voice, let ticks, let expected):
            "\(voice): spans \(ticks) ticks where the longest voice spans \(expected)."
        case .registerViolation(let voice, let pitch):
            "\(voice): \(noteName(pitch)) (MIDI \(pitch)) is outside the piano's A0…C8."
        case .raggedBars(let voice, let ticks, let barTicks):
            "\(voice): \(ticks) ticks is not a whole number of \(barTicks)-tick bars."
        case .fingerprintMismatch(let voice, let opening, let expected):
            "\(voice): opens \(opening.map(noteName).joined(separator: " ")), " +
            "expected \(expected.map(noteName).joined(separator: " "))."
        }
    }

    static func noteName(_ pitch: UInt8) -> String {
        let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
        return "\(names[Int(pitch) % 12])\(Int(pitch) / 12 - 1)"
    }
}
