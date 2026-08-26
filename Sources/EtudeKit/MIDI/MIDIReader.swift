// Minimal SMF reader — `[UInt8]` → events   (Phase 3, built test-first)
//
// Exists for the round-trip property (write→read == identity on events) and
// structural smoke checks — not a general MIDI import. It still accepts
// running status and skips unknown metas, so it can read files this project
// did not write.

public enum SMFReadError: Error, Equatable, Sendable {
    case notAStandardMIDIFile
    case truncated
    case unterminatedTrack
    case unsupportedFormat(Int)
}

/// One decoded track: its name meta (if any) and paired note events.
public struct SMFTrack: Equatable, Sendable {
    public let name: String
    public let events: [NoteEvent]

    public init(name: String, events: [NoteEvent]) {
        self.name = name
        self.events = events
    }
}

/// A decoded Standard MIDI File.
public struct SMFFile: Equatable, Sendable {
    public let division: Int
    public let beatsPerMinute: Int?
    public let tracks: [SMFTrack]

    public init(division: Int, beatsPerMinute: Int?, tracks: [SMFTrack]) {
        self.division = division
        self.beatsPerMinute = beatsPerMinute
        self.tracks = tracks
    }
}

public struct SMFReader: Sendable {
    public init() {}

    public func read(_ bytes: [UInt8]) throws(SMFReadError) -> SMFFile {
        var i = 0
        guard take(bytes, &i, 4) == Array("MThd".utf8) else {
            throw SMFReadError.notAStandardMIDIFile
        }
        let headerLength = try uint32(bytes, &i)
        let format = try uint16(bytes, &i)
        guard format <= 1 else { throw SMFReadError.unsupportedFormat(format) }
        let trackCount = try uint16(bytes, &i)
        let division = try uint16(bytes, &i)
        i += headerLength - 6

        var beatsPerMinute: Int?
        var tracks: [SMFTrack] = []
        for _ in 0..<trackCount {
            guard take(bytes, &i, 4) == Array("MTrk".utf8) else {
                throw SMFReadError.truncated
            }
            let length = try uint32(bytes, &i)
            guard i + length <= bytes.count else { throw SMFReadError.truncated }
            let (track, tempo) = try decodeTrack(Array(bytes[i..<(i + length)]))
            beatsPerMinute = beatsPerMinute ?? tempo
            tracks.append(track)
            i += length
        }
        return SMFFile(division: division, beatsPerMinute: beatsPerMinute, tracks: tracks)
    }

    private func decodeTrack(_ data: [UInt8]) throws(SMFReadError) -> (SMFTrack, tempo: Int?) {
        var i = 0
        var tick = 0
        var name = ""
        var tempo: Int?
        var runningStatus: UInt8 = 0
        var open: [UInt8: [(tick: Int, velocity: UInt8, index: Int)]] = [:]
        var events: [NoteEvent] = []
        var eventCount = 0

        while i < data.count {
            tick += try variableLength(data, &i)
            guard i < data.count else { throw SMFReadError.truncated }
            var status = data[i]
            if status & 0x80 != 0 {
                i += 1
            } else {
                status = runningStatus
            }
            switch status & 0xF0 {
            case 0xF0 where status == 0xFF:
                guard i < data.count else { throw SMFReadError.truncated }
                let metaType = data[i]
                i += 1
                let length = try variableLength(data, &i)
                guard i + length <= data.count else { throw SMFReadError.truncated }
                let payload = data[i..<(i + length)]
                i += length
                switch metaType {
                case 0x03:
                    name = String(decoding: payload, as: UTF8.self)
                case 0x51:
                    let microseconds = payload.reduce(0) { $0 << 8 | Int($1) }
                    tempo = tempo ?? 60_000_000 / max(microseconds, 1)
                case 0x2F:
                    // End of track: the paired notes, sorted as performed.
                    return (SMFTrack(name: name, events: sorted(events)), tempo)
                default:
                    break
                }
            case 0x90, 0x80:
                runningStatus = status
                guard i + 1 < data.count else { throw SMFReadError.truncated }
                let pitch = data[i]
                let velocity = data[i + 1]
                i += 2
                if status & 0xF0 == 0x90, velocity > 0 {
                    open[pitch, default: []].append((tick, velocity, eventCount))
                    eventCount += 1
                    events.append(NoteEvent(pitch: pitch, startTick: tick,
                                            durationTicks: 0, velocity: velocity))
                } else if !(open[pitch]?.isEmpty ?? true) {
                    let start = open[pitch]!.removeFirst()
                    events[start.index] = NoteEvent(
                        pitch: pitch, startTick: start.tick,
                        durationTicks: tick - start.tick, velocity: start.velocity)
                }
            case 0xA0, 0xB0, 0xE0:
                runningStatus = status
                i += 2
            case 0xC0, 0xD0:
                runningStatus = status
                i += 1
            default:
                throw SMFReadError.truncated
            }
        }
        throw SMFReadError.unterminatedTrack
    }

    private func sorted(_ events: [NoteEvent]) -> [NoteEvent] {
        events.enumerated()
            .sorted { ($0.element.startTick, $0.offset) < ($1.element.startTick, $1.offset) }
            .map(\.element)
    }

    private func take(_ bytes: [UInt8], _ i: inout Int, _ count: Int) -> [UInt8] {
        guard i + count <= bytes.count else { return [] }
        defer { i += count }
        return Array(bytes[i..<(i + count)])
    }

    private func uint16(_ bytes: [UInt8], _ i: inout Int) throws(SMFReadError) -> Int {
        guard i + 2 <= bytes.count else { throw SMFReadError.truncated }
        defer { i += 2 }
        return Int(bytes[i]) << 8 | Int(bytes[i + 1])
    }

    private func uint32(_ bytes: [UInt8], _ i: inout Int) throws(SMFReadError) -> Int {
        guard i + 4 <= bytes.count else { throw SMFReadError.truncated }
        defer { i += 4 }
        return (0..<4).reduce(0) { $0 << 8 | Int(bytes[i + $1]) }
    }

    private func variableLength(_ bytes: [UInt8], _ i: inout Int) throws(SMFReadError) -> Int {
        var value = 0
        while true {
            guard i < bytes.count else { throw SMFReadError.truncated }
            let byte = bytes[i]
            i += 1
            value = value << 7 | Int(byte & 0x7F)
            if byte & 0x80 == 0 { return value }
        }
    }
}
