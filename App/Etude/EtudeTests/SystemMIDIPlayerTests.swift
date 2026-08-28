import XCTest
import EtudeKit
@testable import Etude

/// The real player wrapper (issue #3): on iOS, `AVMIDIPlayer` with no sound
/// bank plays SILENCE while reporting success — so the wrapper's contract is
/// that a missing bank throws instead of pretending. Audibility itself stays
/// a manual device check; these tests pin the configuration that makes it
/// possible.
@MainActor
final class SystemMIDIPlayerTests: XCTestCase {
    func testLoadFailsLoudlyWhenTheSoundBankIsMissing() {
        let sut = makeSUT(soundBankURL: URL(fileURLWithPath: "/nowhere/missing.sf2"))

        XCTAssertThrowsError(try sut.load(shortMIDI()),
                             "a missing bank must throw, never play silence")
    }

    func testLoadFailsLoudlyWhenNoSoundBankWasResolved() {
        let sut = makeSUT(soundBankURL: nil)

        XCTAssertThrowsError(try sut.load(shortMIDI()))
    }

    func testLoadsRealMIDIThroughTheBundledBank() throws {
        let bank = try XCTUnwrap(SoundBank.bundledPiano)
        let sut = makeSUT(soundBankURL: bank)

        XCTAssertNoThrow(try sut.load(shortMIDI()))
        XCTAssertFalse(sut.isPlaying, "loading must not start playback")
    }

    // MARK: - Helpers

    private func makeSUT(
        soundBankURL: URL?, file: StaticString = #filePath, line: UInt = #line
    ) -> SystemMIDIPlayer {
        let sut = SystemMIDIPlayer(soundBankURL: soundBankURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    /// One middle-C quarter note, straight through the engine's own writer.
    private func shortMIDI() -> Data {
        let voice = Voice(
            name: "melody",
            events: [NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 90)],
            totalTicks: 480)
        let score = Score(title: "Smoke", tempo: nil, meter: nil, voices: [voice])
        return Data(RunningStatusSMFWriter().bytes(for: score))
    }
}
