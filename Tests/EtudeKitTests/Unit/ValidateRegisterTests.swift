import Testing
import EtudeKit

@Suite("Validate register sanity")
struct ValidateRegisterTests {
    @Test("pitches across the piano's range validate cleanly", .tags(.unit))
    func plausibleRegister() throws {
        try makeSUT().validate(score([voice("melody", pitches: [21, 60, 108])]))
    }

    @Test("a sub-audible octave-0 artifact is a finding, never a repair", .tags(.unit))
    func subAudibleBass() throws {
        // BUG-004's shape: an octave-drifted bass at MIDI 15. The prototype
        // clamped it into range and hid the resolver bug (ADR-0001).
        #expect(throws: ValidationError(findings: [
            .registerViolation(voice: "bass", pitch: 15),
        ])) {
            try makeSUT().validate(score([voice("bass", pitches: [43, 15, 43])]))
        }
    }

    @Test("a stratospheric octave-8 artifact is equally loud", .tags(.unit))
    func stratosphericTreble() throws {
        #expect(throws: ValidationError(findings: [
            .registerViolation(voice: "melody", pitch: 121),
        ])) {
            try makeSUT().validate(score([voice("melody", pitches: [121, 79])]))
        }
    }

    @Test("one finding per offending pitch per voice, not per note", .tags(.unit))
    func findingsAreDeduplicated() throws {
        #expect(throws: ValidationError(findings: [
            .registerViolation(voice: "bass", pitch: 15),
            .registerViolation(voice: "bass", pitch: 17),
        ])) {
            try makeSUT().validate(score([voice("bass", pitches: [15, 15, 17, 15])]))
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Validator { Validator() }
}
