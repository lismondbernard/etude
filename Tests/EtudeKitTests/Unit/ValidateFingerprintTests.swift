import Testing
import EtudeKit

@Suite("Validate opening fingerprint")
struct ValidateFingerprintTests {
    @Test("a melody opening with the expected notes validates cleanly", .tags(.unit))
    func matchingOpening() throws {
        // The Gymnopédie's F#5 A5 G5 F#5.
        try makeSUT().validate(
            score([voice("melody", pitches: [78, 81, 79, 78, 73, 71])]),
            expectedOpening: [78, 81, 79, 78])
    }

    @Test("a wrong opening is a finding naming both phrases", .tags(.unit))
    func wrongOpening() throws {
        #expect(throws: ValidationError(findings: [
            .fingerprintMismatch(voice: "melody", opening: [78, 81, 79], expected: [78, 79, 81]),
        ])) {
            try makeSUT().validate(
                score([voice("melody", pitches: [78, 81, 79, 78])]),
                expectedOpening: [78, 79, 81])
        }
    }

    @Test("an opening shorter than expected is a mismatch, not a crash", .tags(.unit))
    func openingTooShort() throws {
        #expect(throws: ValidationError(findings: [
            .fingerprintMismatch(voice: "melody", opening: [78], expected: [78, 81]),
        ])) {
            try makeSUT().validate(
                score([voice("melody", pitches: [78])]),
                expectedOpening: [78, 81])
        }
    }

    @Test("without an expectation the fingerprint rule stays silent", .tags(.unit))
    func noExpectation() throws {
        try makeSUT().validate(score([voice("melody", pitches: [61, 62, 63])]))
    }

    // MARK: - Helpers

    private func makeSUT() -> Validator { Validator() }
}
