import Testing
import EtudeKit

// The Validator throws findings; it never repairs (ADR-0001). Voice alignment
// is the invariant that exposed Clair de Lune's 91/46/57/54-beat mismatch —
// the whole reason findings are loud.
@Suite("Validate voice alignment")
struct ValidateVoiceAlignmentTests {
    @Test("equal-length voices validate cleanly", .tags(.unit))
    func alignedVoices() throws {
        let sut = makeSUT()
        try sut.validate(score([
            voice("melody", pitches: [60, 62, 64]),
            voice("bass", pitches: [48, 50, 52]),
        ]))
    }

    @Test("a short voice is reported against the longest", .tags(.unit))
    func misalignedVoice() throws {
        let sut = makeSUT()
        #expect(throws: ValidationError(findings: [
            .voiceMisaligned(voice: "bass", ticks: 960, expectedTicks: 1440),
        ])) {
            try sut.validate(score([
                voice("melody", pitches: [60, 62, 64]),
                voice("bass", pitches: [48, 50]),
            ]))
        }
    }

    @Test("every misaligned voice is a separate finding", .tags(.unit))
    func multipleFindings() throws {
        let sut = makeSUT()
        #expect(throws: ValidationError(findings: [
            .voiceMisaligned(voice: "tenor", ticks: 960, expectedTicks: 1440),
            .voiceMisaligned(voice: "bass", ticks: 480, expectedTicks: 1440),
        ])) {
            try sut.validate(score([
                voice("melody", pitches: [60, 62, 64]),
                voice("tenor", pitches: [55, 57]),
                voice("bass", pitches: [48]),
            ]))
        }
    }

    @Test("trailing silence counts toward a voice's span", .tags(.unit))
    func trailingSilenceCounts() throws {
        let sut = makeSUT()
        // One sounding note, then rests to the same span: aligned.
        try sut.validate(score([
            voice("melody", pitches: [60, 62, 64]),
            voice("bass", pitches: [48], totalTicks: 1440),
        ]))
    }

    // MARK: - Helpers

    private func makeSUT() -> Validator { Validator() }
}
