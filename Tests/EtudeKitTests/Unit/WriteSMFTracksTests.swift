import Testing
import EtudeKit

@Suite("Write SMF voice tracks")
struct WriteSMFTracksTests {
    @Test("writes a named track with explicit status on every event", .tags(.unit))
    func oneNoteTrack() throws {
        let bytes = makeSUT().bytes(for: score([
            Voice(name: "m",
                  events: [NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80)],
                  totalTicks: 480),
        ]))
        #expect(Array(bytes.dropFirst(41)) == [
            0x4D, 0x54, 0x72, 0x6B, 0, 0, 0, 18,           // MTrk, length
            0, 0xFF, 0x03, 1, 0x6D,                        // name "m"
            0, 0x90, 60, 80,                               // note on
            0x83, 0x60, 0x80, 60, 0,                       // +480 ticks, note off
            0, 0xFF, 0x2F, 0,
        ])
    }

    @Test("a chord's note-ons share one tick with zero deltas", .tags(.unit))
    func chordTrack() throws {
        let bytes = makeSUT().bytes(for: score([
            Voice(name: "m", events: [
                NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80),
                NoteEvent(pitch: 64, startTick: 0, durationTicks: 480, velocity: 80),
            ], totalTicks: 480),
        ]))
        #expect(Array(bytes.dropFirst(41 + 8 + 5)) == [
            0, 0x90, 60, 80,
            0, 0x90, 64, 80,
            0x83, 0x60, 0x80, 60, 0,
            0, 0x80, 64, 0,
            0, 0xFF, 0x2F, 0,
        ])
    }

    @Test("at a shared tick, note-offs precede note-ons", .tags(.unit))
    func offBeforeOnAtSameTick() throws {
        // Back-to-back middle Cs: the first must release before the second
        // strikes, or the second attack is swallowed.
        let bytes = makeSUT().bytes(for: score([
            Voice(name: "m", events: [
                NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80),
                NoteEvent(pitch: 60, startTick: 480, durationTicks: 480, velocity: 80),
            ], totalTicks: 960),
        ]))
        #expect(Array(bytes.dropFirst(41 + 8 + 5)) == [
            0, 0x90, 60, 80,
            0x83, 0x60, 0x80, 60, 0,
            0, 0x90, 60, 80,
            0x83, 0x60, 0x80, 60, 0,
            0, 0xFF, 0x2F, 0,
        ])
    }

    @Test("long silences become multi-byte variable-length deltas", .tags(.unit))
    func multiByteDelta() throws {
        let bytes = makeSUT().bytes(for: score([
            Voice(name: "m", events: [
                NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80),
                NoteEvent(pitch: 62, startTick: 100_000, durationTicks: 480, velocity: 80),
            ], totalTicks: 100_480),
        ]))
        // 100_000 − 480 = 99_520 ticks of silence = 0x86 0x89 0x40.
        #expect(Array(bytes.dropFirst(41 + 8 + 5 + 4 + 5)) == [
            0x86, 0x89, 0x40, 0x90, 62, 80,
            0x83, 0x60, 0x80, 62, 0,
            0, 0xFF, 0x2F, 0,
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> SMFWriter { SMFWriter() }
}
