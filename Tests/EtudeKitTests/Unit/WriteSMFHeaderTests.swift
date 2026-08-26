import Testing
import EtudeKit

@Suite("Write SMF header and tempo track")
struct WriteSMFHeaderTests {
    @Test("writes a Type 1 header with one track per voice plus the meta track", .tags(.unit))
    func header() throws {
        let bytes = makeSUT().bytes(for: score([
            voice("melody", pitches: [60]),
            voice("bass", pitches: [48]),
        ]))
        // MThd, length 6, format 1, ntrks 3, division 480.
        #expect(Array(bytes.prefix(14)) == [
            0x4D, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 1, 0, 3, 0x01, 0xE0,
        ])
    }

    @Test("the meta track carries the score's tempo and meter", .tags(.unit))
    func metaTrack() throws {
        let bytes = makeSUT().bytes(for: score(
            [voice("melody", pitches: [60])],
            meter: Meter(beats: 3, beatUnit: 4),
            tempo: TempoMark(label: "Lent", beatUnit: 4, beatsPerMinute: 66)))
        // Track 0: 66 bpm = 909_090 µs/quarter; 3/4 = 3, 2^2, 24 clocks, 8.
        #expect(Array(bytes[14..<43]) == [
            0x4D, 0x54, 0x72, 0x6B, 0, 0, 0, 21,           // MTrk, length
            0, 0xFF, 0x51, 3, 0x0D, 0xDF, 0x22,            // tempo
            0, 0xFF, 0x58, 4, 3, 2, 24, 8,                 // time signature
            0, 0xFF, 0x2F, 0,                              // end of track
        ])
    }

    @Test("without tempo or meter the meta track defaults to 120 in common time", .tags(.unit))
    func defaults() throws {
        let bytes = makeSUT().bytes(for: score([voice("melody", pitches: [60])]))
        #expect(Array(bytes[14..<43]) == [
            0x4D, 0x54, 0x72, 0x6B, 0, 0, 0, 21,
            0, 0xFF, 0x51, 3, 0x07, 0xA1, 0x20,            // 500_000 µs = 120 bpm
            0, 0xFF, 0x58, 4, 4, 2, 24, 8,
            0, 0xFF, 0x2F, 0,
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> SMFWriter { SMFWriter() }
}
