import EtudeKit

// Score-level sample builders (PLAN.md §0.6).

func voice(
    _ name: String, pitches: [UInt8], eventTicks: Int = 480, totalTicks: Int? = nil,
    velocity: UInt8 = 80
) -> Voice {
    let events = pitches.enumerated().map { index, pitch in
        NoteEvent(pitch: pitch, startTick: index * eventTicks,
                  durationTicks: eventTicks, velocity: velocity)
    }
    return Voice(name: name, events: events,
                 totalTicks: totalTicks ?? pitches.count * eventTicks)
}

func score(_ voices: [Voice], meter: Meter? = nil, tempo: TempoMark? = nil) -> Score {
    Score(title: "Sample", tempo: tempo, meter: meter, voices: voices)
}
