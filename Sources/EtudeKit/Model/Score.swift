// Model — `Score` value types + assembly   (Phase 3, built test-first)
//
// The domain model speaks the musician's vocabulary: voices, ticks, MIDI
// pitches. Zero LilyPond concepts survive here (§0.4) — a future MusicXML
// front end must require no change to these types. Value types on purpose
// (ADR-0002). Invariants live in the Validator, which THROWS rather than
// clamps (ADR-0001).

/// One sounding note as performed: MIDI pitch, absolute ticks, velocity.
public struct NoteEvent: Equatable, Sendable, Codable {
    public let pitch: UInt8
    public let startTick: Int
    public let durationTicks: Int
    public let velocity: UInt8

    public init(pitch: UInt8, startTick: Int, durationTicks: Int, velocity: UInt8) {
        self.pitch = pitch
        self.startTick = startTick
        self.durationTicks = durationTicks
        self.velocity = velocity
    }
}

/// One performed line. `totalTicks` is the full span including trailing
/// silence — alignment between voices is about spans, not last notes.
public struct Voice: Equatable, Sendable, Codable {
    public let name: String
    public let events: [NoteEvent]
    public let totalTicks: Int

    public init(name: String, events: [NoteEvent], totalTicks: Int) {
        self.name = name
        self.events = events
        self.totalTicks = totalTicks
    }
}

/// A complete piece, ready for validation and MIDI emission.
public struct Score: Equatable, Sendable, Codable {
    public let title: String
    public let tempo: TempoMark?
    public let meter: Meter?
    public let voices: [Voice]

    public init(title: String, tempo: TempoMark?, meter: Meter?, voices: [Voice]) {
        self.title = title
        self.tempo = tempo
        self.meter = meter
        self.voices = voices
    }
}

/// A structural failure while assembling a `Score` from a parsed file.
public enum ScoreBuildError: Error, Equatable, Sendable {
    case missingScoreBlock
    /// The resolver placed a pitch no MIDI byte can hold. In-range-but-absurd
    /// registers are the Validator's finer judgement; this is the hard floor.
    case pitchOutOfMIDIRange(voice: String, midi: Int)
    case resolveFailed(String, ResolveError)
}

/// Maps a parsed file to the domain model: walks the `\score` assembly,
/// resolves each referenced voice, and stamps velocities.
public struct ScoreBuilder: Sendable {
    public init() {}

    public func score(
        from file: LilyFile,
        velocities: [String: UInt8] = [:],
        defaultVelocity: UInt8 = 80
    ) throws(ScoreBuildError) -> Score {
        guard let scoreBlock = file.score else { throw ScoreBuildError.missingScoreBlock }
        return try score(
            from: file, voices: voiceReferences(in: scoreBlock),
            title: file.header["title"] ?? "",
            velocities: velocities, defaultVelocity: defaultVelocity)
    }

    /// Assembles explicitly named voices — for sources that define their
    /// voices but carry no `\score` assembly (Clair de Lune). When the
    /// resolved tempo names a feel without a metronome number,
    /// `assumingBeatsPerMinute` supplies one.
    public func score(
        from file: LilyFile,
        voices names: [String],
        title: String,
        velocities: [String: UInt8] = [:],
        defaultVelocity: UInt8 = 80,
        assumingBeatsPerMinute: Int? = nil
    ) throws(ScoreBuildError) -> Score {
        var voices: [Voice] = []
        var meter: Meter?
        var tempo: TempoMark?
        for name in names {
            let resolved: ResolvedMusic
            do {
                resolved = try Resolver().resolve(
                    [.reference(name)], definitions: file.definitions)
            } catch {
                throw ScoreBuildError.resolveFailed(name, error)
            }
            let velocity = velocities[name] ?? defaultVelocity
            var events: [NoteEvent] = []
            for note in resolved.notes {
                guard let pitch = UInt8(exactly: note.midiNote), pitch <= 127 else {
                    throw ScoreBuildError.pitchOutOfMIDIRange(voice: name, midi: note.midiNote)
                }
                events.append(NoteEvent(
                    pitch: pitch, startTick: note.startTick,
                    durationTicks: note.durationTicks, velocity: velocity))
            }
            voices.append(Voice(name: name, events: events, totalTicks: resolved.totalTicks))
            meter = meter ?? resolved.meter
            tempo = tempo ?? resolved.tempo
        }
        if let assumed = assumingBeatsPerMinute, tempo?.beatsPerMinute == nil {
            tempo = TempoMark(label: tempo?.label, beatUnit: 4, beatsPerMinute: assumed)
        }
        return Score(title: title, tempo: tempo, meter: meter, voices: voices)
    }

    /// The referenced definitions inside the score assembly, in reading order.
    private func voiceReferences(in node: MusicNode) -> [String] {
        switch node {
        case .reference(let name): [name]
        case .context(_, let body): voiceReferences(in: body)
        case .parallel(let children), .sequence(let children):
            children.flatMap(voiceReferences(in:))
        default: []
        }
    }
}
