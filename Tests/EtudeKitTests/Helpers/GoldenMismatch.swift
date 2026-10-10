import EtudeKit

// Golden-failure description (PLAN.md §3): decode both files with the SMF
// reader and say, in musical terms, the first event that changed in each
// track, so a red golden can be judged before anyone re-records it.

func goldenMismatch(golden: [UInt8], output: [UInt8]) -> String {
    let expected: SMFFile, actual: SMFFile
    do {
        expected = try SMFReader().read(golden)
        actual = try SMFReader().read(output)
    } catch {
        return "One of the files does not decode as MIDI (\(error)); compare the bytes by hand."
    }
    var lines: [String] = []
    if expected.beatsPerMinute != actual.beatsPerMinute {
        lines.append("The tempo \(bpm(expected)) beats per minute became \(bpm(actual)).")
    }
    if voices(expected).count != voices(actual).count {
        lines.append("The golden has \(tracks(expected)), the new output has \(tracks(actual)).")
    }
    lines += zip(expected.tracks, actual.tracks).compactMap(trackMismatch)
    guard lines.isEmpty else { return lines.joined(separator: "\n") }
    return "The events are identical; only the encoding differs "
        + "(the golden is \(golden.count) bytes, the new output \(output.count))."
}

private func bpm(_ file: SMFFile) -> String {
    file.beatsPerMinute.map(String.init) ?? "unset"
}

/// The named tracks: the writer's first track carries only the tempo.
private func voices(_ file: SMFFile) -> [SMFTrack] {
    file.tracks.filter { !$0.name.isEmpty }
}

private func tracks(_ file: SMFFile) -> String {
    let named = voices(file)
    let names = named.map(\.name).joined(separator: ", ")
    return "\(named.count) track\(named.count == 1 ? "" : "s") (\(names))"
}

private func trackMismatch(_ golden: SMFTrack, _ output: SMFTrack) -> String? {
    let was = golden.events, now = output.events
    guard was != now else { return nil }
    let common = min(was.count, now.count)
    let summary = was.count == now.count
        ? "\((0..<common).filter { was[$0] != now[$0] }.count) of \(was.count) events differ."
        : "the golden has \(was.count) events, the new output has \(now.count)."
    let first = (0..<common).first { was[$0] != now[$0] } ?? common
    let change: String = if first < common {
        "event \(first + 1) (\(pitchName(was[first].pitch)) at tick \(was[first].startTick)): "
            + changedFields(was[first], now[first]) + "."
    } else if now.count > was.count {
        "event \(first + 1): added \(describe(now[first]))."
    } else {
        "event \(first + 1): dropped \(describe(was[first]))."
    }
    return "track \"\(golden.name)\": \(summary) First, \(change)"
}

private func changedFields(_ was: NoteEvent, _ now: NoteEvent) -> String {
    var fields: [String] = []
    if was.pitch != now.pitch {
        fields.append("pitch \(pitchName(was.pitch)) became \(pitchName(now.pitch))")
    }
    if was.startTick != now.startTick {
        fields.append("start tick \(was.startTick) became \(now.startTick)")
    }
    if was.durationTicks != now.durationTicks {
        fields.append("length \(was.durationTicks) ticks became \(now.durationTicks)")
    }
    if was.velocity != now.velocity {
        fields.append("velocity \(was.velocity) became \(now.velocity)")
    }
    return fields.joined(separator: ", ")
}

private func describe(_ event: NoteEvent) -> String {
    "\(pitchName(event.pitch)) at tick \(event.startTick) for \(event.durationTicks) ticks, "
        + "velocity \(event.velocity)"
}

/// Scientific pitch notation, middle C (MIDI 60) as C4.
private func pitchName(_ pitch: UInt8) -> String {
    let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return names[Int(pitch) % 12] + String(Int(pitch) / 12 - 1)
}
