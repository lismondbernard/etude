import Testing
import EtudeKit

/// Byte-level tests for the running-status writer's ENCODING choices — the
/// part `SMFWriterSpecs` deliberately leaves open. Running status is SMF's
/// compression: a channel event whose status byte equals the previous one
/// may omit it.
@Suite("Write SMF with running status")
struct WriteRunningStatusTests {
    @Test("a chord's later note-ons omit the repeated status byte", .tags(.unit))
    func chordOmitsRepeatedStatus() throws {
        let bytes = makeSUT().bytes(for: score([
            Voice(name: "m", events: [
                NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80),
                NoteEvent(pitch: 64, startTick: 0, durationTicks: 480, velocity: 80),
            ], totalTicks: 480),
        ]))
        // After the name meta: first on states 0x90, the second rides it.
        #expect(Array(bytes.dropFirst(41 + 8 + 5)).prefix(7) == [
            0, 0x90, 60, 80,
            0, 64, 80,
        ])
    }

    @Test("the first channel event after a meta states its status explicitly", .tags(.unit))
    func metaCancelsRunningStatus() throws {
        let bytes = makeSUT().bytes(for: score([
            Voice(name: "m",
                  events: [NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80)],
                  totalTicks: 480),
        ]))
        // The track opens with the name meta; running status cannot carry
        // across it, so the first note-on must spell out 0x90.
        #expect(Array(bytes.dropFirst(41 + 8)).prefix(9) == [
            0, 0xFF, 0x03, 1, 0x6D,                        // name "m"
            0, 0x90, 60, 80,                               // explicit status
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> RunningStatusSMFWriter { RunningStatusSMFWriter() }
}
