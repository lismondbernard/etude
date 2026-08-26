import Testing
import EtudeKit

@Suite("Validate bar arithmetic")
struct ValidateBarArithmeticTests {
    @Test("whole bars under the meter validate cleanly", .tags(.unit))
    func wholeBars() throws {
        // Two 3/4 bars of quarters.
        try makeSUT().validate(score(
            [voice("melody", pitches: [60, 62, 64, 65, 67, 69])],
            meter: Meter(beats: 3, beatUnit: 4)))
    }

    @Test("a ragged final bar is a finding", .tags(.unit))
    func raggedFinalBar() throws {
        #expect(throws: ValidationError(findings: [
            .raggedBars(voice: "melody", ticks: 5 * 480, barTicks: 1440),
        ])) {
            try makeSUT().validate(score(
                [voice("melody", pitches: [60, 62, 64, 65, 67])],
                meter: Meter(beats: 3, beatUnit: 4)))
        }
    }

    @Test("without a meter, bar arithmetic has nothing to say", .tags(.unit))
    func noMeter() throws {
        try makeSUT().validate(score([voice("melody", pitches: [60, 62, 64, 65, 67])]))
    }

    // MARK: - Helpers

    private func makeSUT() -> Validator { Validator() }
}
