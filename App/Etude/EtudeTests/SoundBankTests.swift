import XCTest
@testable import Etude

/// iOS ships no built-in sound bank for `AVMIDIPlayer` (issue #3): without one
/// in the bundle, playback "succeeds" silently. These tests pin the bundled
/// bank's presence so a missing resource is a red test, not quiet silence.
final class SoundBankTests: XCTestCase {
    func testPianoSoundBankShipsInTheAppBundle() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "UprightPianoKW-small-20190703", withExtension: "sf2"),
            "the CC0 Upright Piano KW SoundFont must ride in the app bundle")

        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        XCTAssertGreaterThan(data.count, 1_000_000, "a truncated bank would load but sound wrong")
        XCTAssertEqual(data.prefix(4), Data("RIFF".utf8), "an SF2 is a RIFF container")
    }

    func testSoundBankLicenseShipsAlongsideIt() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "UprightPianoKW-cc0", withExtension: "txt"),
            "the CC0 dedication text ships with the bank it covers")
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("CC0 1.0 Universal"))
    }
}
