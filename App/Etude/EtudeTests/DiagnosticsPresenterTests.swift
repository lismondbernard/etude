import XCTest
import EtudeKit
@testable import Etude

final class DiagnosticsPresenterTests: XCTestCase {
    func testCleanBuildSummary() {
        XCTAssertEqual(DiagnosticsPresenter.summary(for: []), "All invariants hold.")
    }

    func testFindingsSummaryCounts() {
        let findings: [EtudeKit.ValidationFinding] = [
            .registerViolation(voice: "lhDown", pitch: 13),
            .registerViolation(voice: "lhDown", pitch: 3),
        ]
        XCTAssertEqual(DiagnosticsPresenter.summary(for: findings),
                       "2 findings — this piece ships honest.")
    }

    func testRegisterLineSpeaksTheMusiciansLanguage() {
        let line = DiagnosticsPresenter.line(
            for: .registerViolation(voice: "lhDown", pitch: 13))
        XCTAssertEqual(line, "lhDown: C♯0 (MIDI 13) is outside the piano's A0…C8.")
    }

    func testMisalignmentLineNamesBothSpans() {
        let line = DiagnosticsPresenter.line(
            for: .voiceMisaligned(voice: "bass", ticks: 960, expectedTicks: 1440))
        XCTAssertEqual(line, "bass: spans 960 ticks where the longest voice spans 1440.")
    }
}
