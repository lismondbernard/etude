// Running-status MIDI writer — `Score` → `[UInt8]`   (Phase 6, the §0.5 swap)
//
// Same file shape as the naive writer (SMF Type 1 at 480 ticks per quarter:
// meta track, then one named `MTrk` per voice) but with SMF's compression:
// a channel event whose status byte equals the previous one omits it.
// A meta event cancels running status, so the first channel event after one
// always spells its status out.
//
// Proven against `SMFWriterSpecs` and the round-trip property alongside the
// naive writer; once both pass, the naive writer is deleted in one commit.

/// The compact Standard MIDI File writer.
public struct RunningStatusSMFWriter: SMFWriting {
    public init() {}

    public func bytes(for score: Score) -> [UInt8] {
        var bytes: [UInt8] = []
        bytes += Array("MThd".utf8)
        bytes += uint32(6)
        bytes += uint16(1)                                // format 1
        bytes += uint16(UInt16(score.voices.count + 1))   // meta track + voices
        bytes += uint16(UInt16(ResolvedMusic.ticksPerQuarter))
        bytes += metaTrack(for: score)
        for voice in score.voices {
            bytes += track(for: voice)
        }
        return bytes
    }

    /// One voice, one `MTrk`: name meta, then the notes in tick order with
    /// running status. At a shared tick, note-offs precede note-ons so
    /// repeated pitches re-attack instead of being swallowed.
    private func track(for voice: Voice) -> [UInt8] {
        var data: [UInt8] = [0, 0xFF, 0x03, UInt8(voice.name.utf8.count)]
        data += Array(voice.name.utf8)

        struct Moment {
            let tick: Int
            let isOff: Bool
            let status: UInt8
            let data: [UInt8]
        }
        var moments: [Moment] = []
        for event in voice.events {
            moments.append(Moment(tick: event.startTick, isOff: false,
                                  status: 0x90, data: [event.pitch, event.velocity]))
            // MIDI's idiom: note-on at velocity 0 means off. Offs sharing the
            // ons' status is what lets a whole track run on one status byte.
            moments.append(Moment(tick: event.startTick + event.durationTicks, isOff: true,
                                  status: 0x90, data: [event.pitch, 0]))
        }
        moments.sort { ($0.tick, $0.isOff ? 0 : 1) < ($1.tick, $1.isOff ? 0 : 1) }

        var previousTick = 0
        var runningStatus: UInt8?    // nil after the name meta — metas cancel it
        for moment in moments {
            data += variableLength(moment.tick - previousTick)
            previousTick = moment.tick
            if moment.status != runningStatus {
                data.append(moment.status)
                runningStatus = moment.status
            }
            data += moment.data
        }
        data += endOfTrack
        return chunk("MTrk", data)
    }

    /// MIDI's variable-length quantity: seven bits per byte, high bit set on
    /// all but the last.
    private func variableLength(_ value: Int) -> [UInt8] {
        var groups: [UInt8] = [UInt8(value & 0x7F)]
        var rest = value >> 7
        while rest > 0 {
            groups.append(UInt8(rest & 0x7F | 0x80))
            rest >>= 7
        }
        return groups.reversed()
    }

    /// Track 0: tempo and time signature, nothing sounding. All metas, so
    /// running status never comes into play here.
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
