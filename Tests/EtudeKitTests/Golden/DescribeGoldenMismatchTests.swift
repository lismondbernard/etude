import Testing
import EtudeKit

/// A golden mismatch has to say what moved in the music, not just that two
/// byte arrays differ (PLAN.md §3): decode both files with the SMF reader and
/// name the first event that changed.
@Suite("Describe a golden mismatch")
struct DescribeGoldenMismatchTests {
    @Test("names the field that changed in the first differing event", .tags(.golden))
    func changedVelocity() {
        let golden = bytes(voice("melody", pitches: [62, 64, 66], velocity: 92))
        let output = bytes(voice("melody", pitches: [62, 64, 66], velocity: 93))

        #expect(goldenMismatch(golden: golden, output: output) == """
            track "melody": 3 of 3 events differ. \
            First, event 1 (D4 at tick 0): velocity 92 became 93.
            """)
    }

    @Test("names a wrong note by its pitch", .tags(.golden))
    func wrongNote() {
        let golden = bytes(voice("melody", pitches: [62, 64, 66]))
        let output = bytes(voice("melody", pitches: [62, 52, 66]))

        #expect(goldenMismatch(golden: golden, output: output) == """
            track "melody": 1 of 3 events differ. \
            First, event 2 (E4 at tick 480): pitch E4 became E3.
            """)
    }

    @Test("names an event the new output added", .tags(.golden))
    func addedEvent() {
        let golden = bytes(voice("melody", pitches: [62, 64, 66]))
        let output = bytes(voice("melody", pitches: [62, 64, 66, 67]))

        #expect(goldenMismatch(golden: golden, output: output) == """
            track "melody": the golden has 3 events, the new output has 4. \
            First, event 4: added G4 at tick 1440 for 480 ticks, velocity 80.
            """)
    }

    @Test("names an event the new output dropped", .tags(.golden))
    func droppedEvent() {
        let golden = bytes(voice("melody", pitches: [62, 64, 66, 67]))
        let output = bytes(voice("melody", pitches: [62, 64, 66]))

        #expect(goldenMismatch(golden: golden, output: output) == """
            track "melody": the golden has 4 events, the new output has 3. \
            First, event 4: dropped G4 at tick 1440 for 480 ticks, velocity 80.
            """)
    }

    @Test("says so when the events match and only the encoding differs", .tags(.golden))
    func encodingOnly() {
        // One C4 for a quarter note, written twice: once spelling every status
        // byte, once with running status dropping the repeated 0x90.
        let header: [UInt8] = Array("MThd".utf8) + [0, 0, 0, 6, 0, 1, 0, 1, 0x01, 0xE0]
        func track(_ body: [UInt8]) -> [UInt8] {
            Array("MTrk".utf8) + [0, 0, 0, UInt8(body.count)] + body
        }
        let name: [UInt8] = [0x00, 0xFF, 0x03, 0x01, UInt8(ascii: "m")]
        let end: [UInt8] = [0x00, 0xFF, 0x2F, 0x00]
        let golden = header + track(name + [0x00, 0x90, 60, 80, 0x83, 0x60, 0x90, 60, 0] + end)
        let output = header + track(name + [0x00, 0x90, 60, 80, 0x83, 0x60, 60, 0] + end)

        #expect(goldenMismatch(golden: golden, output: output) == """
            The events are identical; only the encoding differs \
            (the golden is \(golden.count) bytes, the new output \(output.count)).
            """)
    }

    @Test("names a track the new output lost", .tags(.golden))
    func lostTrack() {
        let golden = bytes(voice("melody", pitches: [62]), voice("bass", pitches: [43]))
        let output = bytes(voice("melody", pitches: [62]))

        #expect(goldenMismatch(golden: golden, output: output) == """
            The golden has 2 tracks (melody, bass), the new output has 1 track (melody).
            """)
    }

    @Test("names a tempo change", .tags(.golden))
    func changedTempo() {
        let melody = voice("melody", pitches: [62, 64])
        let golden = RunningStatusSMFWriter().bytes(for: score([melody], tempo: tempo(120)))
        let output = RunningStatusSMFWriter().bytes(for: score([melody], tempo: tempo(96)))

        #expect(goldenMismatch(golden: golden, output: output) == """
            The tempo 120 beats per minute became 96.
            """)
    }

    private func tempo(_ beatsPerMinute: Int) -> TempoMark {
        TempoMark(label: nil, beatUnit: 4, beatsPerMinute: beatsPerMinute)
    }

    private func bytes(_ voices: Voice...) -> [UInt8] {
        RunningStatusSMFWriter().bytes(for: score(voices))
    }
}
