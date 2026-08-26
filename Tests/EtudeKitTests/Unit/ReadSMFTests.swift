import Testing
import EtudeKit

@Suite("Read SMF")
struct ReadSMFTests {
    @Test("reads back what the writer wrote", .tags(.unit))
    func readsWriterOutput() throws {
        let original = score(
            [voice("melody", pitches: [60, 64, 67], velocity: 92)],
            meter: Meter(beats: 3, beatUnit: 4),
            tempo: TempoMark(label: nil, beatUnit: 4, beatsPerMinute: 66))
        let file = try makeSUT().read(SMFWriter().bytes(for: original))

        #expect(file.division == 480)
        #expect(file.beatsPerMinute == 66)
        #expect(file.tracks.count == 2)
        #expect(file.tracks[1].name == "melody")
        #expect(file.tracks[1].events == original.voices[0].events)
    }

    @Test("pairs overlapping notes of the same pitch first-on first-off", .tags(.unit))
    func overlappingSamePitch() throws {
        let original = score([
            Voice(name: "m", events: [
                NoteEvent(pitch: 60, startTick: 0, durationTicks: 960, velocity: 80),
                NoteEvent(pitch: 60, startTick: 480, durationTicks: 960, velocity: 80),
            ], totalTicks: 1440),
        ])
        let file = try makeSUT().read(SMFWriter().bytes(for: original))
        #expect(file.tracks[1].events.map(\.durationTicks) == [960, 960])
    }

    @Test("delivers a typed error on foreign magic", .tags(.unit))
    func badMagic() throws {
        #expect(throws: SMFReadError.notAStandardMIDIFile) {
            try makeSUT().read(Array("RIFFdata".utf8))
        }
    }

    @Test("delivers a typed error on a truncated file", .tags(.unit))
    func truncated() throws {
        let bytes = SMFWriter().bytes(for: score([voice("m", pitches: [60])]))
        #expect(throws: SMFReadError.truncated) {
            try makeSUT().read(Array(bytes.dropLast(6)))
        }
    }

    @Test("delivers a typed error on a track missing its end marker", .tags(.unit))
    func unterminatedTrack() throws {
        var bytes = SMFWriter().bytes(for: score([voice("m", pitches: [60])]))
        // Overwrite the final End-of-Track meta with note noise.
        bytes.replaceSubrange((bytes.count - 4)..., with: [0, 0x90, 60, 80])
        #expect(throws: SMFReadError.unterminatedTrack) {
            try makeSUT().read(bytes)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> SMFReader { SMFReader() }
}
