// MIDI writer — `Score` → `[UInt8]`   (Phase 3, built test-first)
//
// Standard MIDI File Type 1 at 480 ticks per quarter: one tempo/meta track,
// then one `MTrk` per voice. Every track ends with End-of-Track.
//
// Running status is DELIBERATELY omitted: every event carries its status
// byte. That costs bytes but keeps the writer obvious — and it is the seed of
// the §0.5 swap lesson, where Phase 6 introduces a running-status writer,
// proves both against `SMFWriterSpecs`, and deletes this one in a single
// commit.

/// The score→bytes seam (§0.3). The app and the golden tests depend on this
/// protocol, so Phase 6 can swap writers without touching either.
public protocol SMFWriting: Sendable {
    func bytes(for score: Score) -> [UInt8]
}

/// The first, deliberately naive Standard MIDI File writer.
public struct SMFWriter: SMFWriting {
    public init() {}

    public func bytes(for score: Score) -> [UInt8] {
        var bytes: [UInt8] = []
        bytes += Array("MThd".utf8)
        bytes += uint32(6)
        bytes += uint16(1)                                // format 1
        bytes += uint16(UInt16(score.voices.count + 1))   // meta track + voices
        bytes += uint16(UInt16(ResolvedMusic.ticksPerQuarter))
        bytes += metaTrack(for: score)
        return bytes
    }

    /// Track 0: tempo and time signature, nothing sounding.
    private func metaTrack(for score: Score) -> [UInt8] {
        var events: [UInt8] = []
        let bpm = score.tempo?.beatsPerMinute ?? 120
        let microsecondsPerQuarter = 60_000_000 / bpm
        events += [0, 0xFF, 0x51, 3]
        events += uint32(UInt32(microsecondsPerQuarter)).suffix(3)
        let meter = score.meter ?? Meter(beats: 4, beatUnit: 4)
        // dd is the beat unit as a power of two; 24 MIDI clocks per metronome
        // tick and 8 thirty-seconds per quarter are the conventional constants.
        events += [0, 0xFF, 0x58, 4, UInt8(meter.beats),
                   UInt8(meter.beatUnit.trailingZeroBitCount), 24, 8]
        events += endOfTrack
        return chunk("MTrk", events)
    }

    private let endOfTrack: [UInt8] = [0, 0xFF, 0x2F, 0]

    private func chunk(_ magic: String, _ data: [UInt8]) -> [UInt8] {
        Array(magic.utf8) + uint32(UInt32(data.count)) + data
    }

    private func uint32(_ value: UInt32) -> [UInt8] {
        [UInt8(value >> 24 & 0xFF), UInt8(value >> 16 & 0xFF),
         UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)]
    }

    private func uint16(_ value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }

    private func uint32(_ value: Int) -> [UInt8] {
        uint32(UInt32(value))
    }
}
