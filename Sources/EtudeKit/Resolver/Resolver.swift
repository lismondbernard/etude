// Resolver — event tree → absolute timed events   (Phase 2, built test-first)
//
// - `\relative` octave resolution: each note is placed within a fourth of the
//   previous note, then `'`/`,` adjust. Chord semantics follow LilyPond: the first
//   chord note relates to the previous context; subsequent notes relate within the
//   chord; context after the chord continues from the first note.
// - `\repeat volta/unfold n { … }`: resolve the body ONCE, then copy the resolved
//   events — never re-thread the relative context through repetitions (BUG-002).
//
// Past this layer nothing is LilyPond-shaped (§0.4): output is MIDI pitch
// numbers and ticks. Middle C is written `c'` and resolves to MIDI 60.

/// A semantic error found while resolving the parse tree.
public enum ResolveError: Error, Equatable, Sendable {
    case unknownPitchName(String)
    case chordRepeatWithoutChord
    case unknownReference(String)
    /// A tree shape the resolver does not (yet) perform — failing loudly beats
    /// skipping music (ADR-0001 territory: silence hides wrongness).
    case unsupportedNode(String)
}

/// One sounding note, absolutely placed in time. 480 ticks per quarter.
public struct ResolvedNote: Equatable, Sendable {
    public let midiNote: Int
    public let startTick: Int
    public let durationTicks: Int

    public init(midiNote: Int, startTick: Int, durationTicks: Int) {
        self.midiNote = midiNote
        self.startTick = startTick
        self.durationTicks = durationTicks
    }
}

/// The resolver's output for one music expression: absolute timed notes.
public struct ResolvedMusic: Equatable, Sendable {
    public static let ticksPerQuarter = 480

    public let notes: [ResolvedNote]
    /// Total performed span, trailing rests included.
    public let totalTicks: Int

    public init(notes: [ResolvedNote], totalTicks: Int) {
        self.notes = notes
        self.totalTicks = totalTicks
    }
}

/// Walks the parse tree and produces absolutely-timed, absolutely-pitched
/// events. Stateless between runs; all per-run state lives in `resolve`.
public struct Resolver: Sendable {
    public init() {}

    public func resolve(
        _ music: [MusicNode], definitions: [String: MusicNode] = [:]
    ) throws(ResolveError) -> ResolvedMusic {
        var state = State()
        state.definitions = definitions
        try resolveSequence(music, into: &state)
        return ResolvedMusic(notes: state.notes, totalTicks: state.tick)
    }

    /// Mutable walk state, threaded through the whole resolution in source
    /// order — the same order a musician reads.
    private struct State {
        var notes: [ResolvedNote] = []
        var tick = 0
        /// LilyPond's sticky duration: an event with no written duration lasts
        /// as long as the previous one. A quarter before anything is written.
        var lastDuration = DurationToken(4)
        /// The pitch each relative note is placed against; `nil` outside a
        /// `\relative` block (absolute mode).
        var reference: (letter: Int, octave: Int)?
        /// The last chord's sounded pitches, for the `q` repeat.
        var lastChord: [Int]?
        /// Open ties: sounding pitch → index of the event to extend when the
        /// adjacent matching pitch arrives.
        var pendingTies: [Int: Int] = [:]

        /// Sounds `midi` for `ticks`, merging into an open tie on the same
        /// pitch instead of re-attacking. Returns the event's index.
        mutating func sound(_ midi: Int, ticks: Int, tiedOnward: Bool, into next: inout [Int: Int]) {
            if let open = pendingTies[midi] {
                notes[open] = ResolvedNote(
                    midiNote: midi,
                    startTick: notes[open].startTick,
                    durationTicks: notes[open].durationTicks + ticks)
                if tiedOnward { next[midi] = open }
            } else {
                notes.append(ResolvedNote(midiNote: midi, startTick: tick, durationTicks: ticks))
                if tiedOnward { next[midi] = notes.count - 1 }
            }
        }

        /// Time stolen by a just-resolved grace group, owed by the next
        /// timed event.
        var graceDebt = 0
        /// True while resolving a grace group's own notes, which never pay
        /// the debt they are creating.
        var inGraceBody = false

        /// Named definitions a `.reference` may inline.
        var definitions: [String: MusicNode] = [:]
        /// The tuplet scale in force, as a fraction (numerator, denominator).
        var tupletScale = (numerator: 1, denominator: 1)

        mutating func ticks(for written: DurationToken?) -> Int {
            if let written { lastDuration = written }
            var ticks = Resolver.ticks(of: lastDuration)
                * tupletScale.numerator / tupletScale.denominator
            if !inGraceBody {
                ticks = max(ticks - graceDebt, 0)
                graceDebt = 0
            }
            return ticks
        }
    }

    private func resolveSequence(
        _ music: [MusicNode], into state: inout State
    ) throws(ResolveError) {
        for node in music {
            switch node {
            case .note(let noteToken, let tied):
                let midi = try midiNote(of: noteToken, in: &state)
                let ticks = state.ticks(for: noteToken.duration)
                var next: [Int: Int] = [:]
                state.sound(midi, ticks: ticks, tiedOnward: tied, into: &next)
                state.pendingTies = next
                state.tick += ticks
            case .chord(let pitches, let duration, let tied):
                let ticks = state.ticks(for: duration)
                var sounded: [Int] = []
                var firstReference: (letter: Int, octave: Int)?
                var next: [Int: Int] = [:]
                for (index, pitch) in pitches.enumerated() {
                    // First note against the outer context; later notes within
                    // the chord; afterwards the context continues from the
                    // FIRST note (LilyPond's chord rule).
                    let midi = try midiNote(of: pitch, in: &state)
                    if index == 0 { firstReference = state.reference }
                    sounded.append(midi)
                    state.sound(midi, ticks: ticks, tiedOnward: tied, into: &next)
                }
                state.pendingTies = next
                if let firstReference { state.reference = firstReference }
                state.lastChord = sounded
                state.tick += ticks
            case .chordRepeat(let duration):
                guard let chord = state.lastChord else {
                    throw ResolveError.chordRepeatWithoutChord
                }
                let ticks = state.ticks(for: duration)
                var next: [Int: Int] = [:]
                for midi in chord {
                    state.sound(midi, ticks: ticks, tiedOnward: false, into: &next)
                }
                state.pendingTies = next
                state.tick += ticks
            case .reference(let name):
                guard let definition = state.definitions[name] else {
                    throw ResolveError.unknownReference(name)
                }
                try resolveSequence([definition], into: &state)
            case .parallel(let children):
                // All children start together; the longest one carries the
                // clock forward. The relative context threads through them in
                // source order — the order a reader meets the notes.
                state.pendingTies = [:]
                let start = state.tick
                var furthest = start
                for child in children {
                    state.tick = start
                    try resolveSequence([child], into: &state)
                    state.pendingTies = [:]
                    furthest = max(furthest, state.tick)
                }
                state.tick = furthest
            case .tuplet(let numerator, let denominator, let body):
                // Written durations inside the group scale by the fraction;
                // the sticky duration itself stays unscaled.
                let outer = state.tupletScale
                state.tupletScale = (outer.numerator * numerator,
                                     outer.denominator * denominator)
                try resolveSequence(body, into: &state)
                state.tupletScale = outer
            case .grace(let body, let acciaccatura):
                // Grace notes steal their span from the note that follows: the
                // group sounds first, the debt shortens the next event, and
                // the bar total is preserved.
                let firstEvent = state.notes.count
                let start = state.tick
                let wasInGraceBody = state.inGraceBody
                state.inGraceBody = true
                try resolveSequence(body, into: &state)
                state.inGraceBody = wasInGraceBody
                if acciaccatura {
                    // Very short by definition: the whole group compresses to
                    // a thirty-second, whatever it writes.
                    let target = ResolvedMusic.ticksPerQuarter / 8
                    let graced = state.notes.count - firstEvent
                    for (offset, index) in (firstEvent..<state.notes.count).enumerated() {
                        state.notes[index] = ResolvedNote(
                            midiNote: state.notes[index].midiNote,
                            startTick: start + offset * target / graced,
                            durationTicks: target / graced)
                    }
                    state.tick = start + target
                }
                state.graceDebt += state.tick - start
            case .repeated(.volta, let count, let body, let alternatives):
                // Performed form: the body plays `count` times, the endings
                // covering the final passes. The body is resolved ONCE and
                // copied (BUG-002); every ending starts from the body-end
                // context, not from wherever the previous ending wandered.
                state.pendingTies = [:]
                let firstEvent = state.notes.count
                let bodyStart = state.tick
                try resolveSequence(body, into: &state)
                state.pendingTies = [:]
                let bodyEvents = Array(state.notes[firstEvent...])
                let bodySpan = state.tick - bodyStart
                let bodyEndContext = (state.reference, state.lastDuration, state.lastChord)
                for pass in 0..<max(count, 1) {
                    if pass > 0 {
                        let offset = state.tick - bodyStart
                        state.notes.append(contentsOf: bodyEvents.map {
                            ResolvedNote(midiNote: $0.midiNote,
                                         startTick: $0.startTick + offset,
                                         durationTicks: $0.durationTicks)
                        })
                        state.tick += bodySpan
                    }
                    let endingIndex = pass - (max(count, 1) - alternatives.count)
                    if endingIndex >= 0, endingIndex < alternatives.count {
                        (state.reference, state.lastDuration, state.lastChord) = bodyEndContext
                        try resolveSequence(alternatives[endingIndex], into: &state)
                        state.pendingTies = [:]
                    }
                }
            case .repeated(.unfold, let count, let body, _):
                // Resolve the body ONCE, then copy the resolved events — the
                // relative context must never re-thread through repetitions
                // (BUG-002).
                state.pendingTies = [:]
                let firstEvent = state.notes.count
                let bodyStart = state.tick
                try resolveSequence(body, into: &state)
                state.pendingTies = [:]
                let bodyEvents = Array(state.notes[firstEvent...])
                let span = state.tick - bodyStart
                for pass in 1..<max(count, 1) {
                    let offset = pass * span
                    state.notes.append(contentsOf: bodyEvents.map {
                        ResolvedNote(midiNote: $0.midiNote,
                                     startTick: $0.startTick + offset,
                                     durationTicks: $0.durationTicks)
                    })
                }
                state.tick = bodyStart + max(count, 1) * span
            case .sequence(let body):
                // Pure grouping (bare braces, crossStaff): time and context
                // flow straight through (BUG-003).
                try resolveSequence(body, into: &state)
            case .context(_, let body):
                // Staff/voice assembly matters when a score is built; inside a
                // music line the wrapper is transparent.
                try resolveSequence([body], into: &state)
            case .pitchedRest(let noteToken):
                // Placed like its written pitch — threading the relative
                // context — but nothing sounds.
                _ = try midiNote(of: noteToken, in: &state)
                state.tick += state.ticks(for: noteToken.duration)
            case .relative(let anchor, let body):
                let outer = state.reference
                let anchorNote = anchor ?? NoteToken(name: "f")
                let (letter, _) = try spelledPitch(anchorNote.name)
                state.reference = (letter, 3 + anchorNote.octaveMarks)
                try resolveSequence(body, into: &state)
                state.reference = outer
            case .rest(let restToken):
                // Sounding, spacer, or multi-measure: performed identically —
                // silence for the written span. A tie cannot cross silence.
                state.pendingTies = [:]
                state.tick += state.ticks(for: restToken.duration)
            default:
                throw ResolveError.unsupportedNode("\(node)")
            }
        }
    }

    // MARK: - Pitch

    /// Semitone offsets of the letters c…b within an octave.
    private static let letterOffsets = [0, 2, 4, 5, 7, 9, 11]
    private static let letters: [Character] = ["c", "d", "e", "f", "g", "a", "b"]

    /// Pitches the note in the current mode and, in relative mode, moves the
    /// reference to the resulting pitch.
    private func midiNote(of noteToken: NoteToken, in state: inout State) throws(ResolveError) -> Int {
        let (letter, alteration) = try spelledPitch(noteToken.name)
        let octave: Int
        if let reference = state.reference {
            // Within a fourth of the reference, counted in letters — never in
            // semitones, so alterations cannot move the placement.
            var placed = reference.octave
            let letterDistance = letter - reference.letter
            if letterDistance > 3 { placed -= 1 }
            if letterDistance < -3 { placed += 1 }
            octave = placed + noteToken.octaveMarks
            state.reference = (letter, octave)
        } else {
            // Absolute mode: a bare letter sits in the octave below middle C.
            octave = 3 + noteToken.octaveMarks
        }
        return 12 * (octave + 1) + Self.letterOffsets[letter] + alteration
    }

    /// Splits a written name into letter index and alteration in semitones.
    /// Dutch (`is`/`es` runs) and English (`s`/`f`/`ss`/`ff`) grammars are
    /// structurally disjoint, so no language flag is needed here.
    private func spelledPitch(_ name: String) throws(ResolveError) -> (letter: Int, alteration: Int) {
        guard let first = name.first, let letter = Self.letters.firstIndex(of: first) else {
            throw ResolveError.unknownPitchName(name)
        }
        let suffix = name.dropFirst()
        if suffix.isEmpty { return (letter, 0) }
        // Dutch: any run of `is` (+1) / `es` (−1).
        var rest = suffix
        var alteration = 0
        while !rest.isEmpty {
            if rest.hasPrefix("is") {
                alteration += 1
                rest = rest.dropFirst(2)
            } else if rest.hasPrefix("es") {
                alteration -= 1
                rest = rest.dropFirst(2)
            } else {
                break
            }
        }
        if rest.isEmpty { return (letter, alteration) }
        // English: one of s, ss (sharp) / f, ff (flat).
        switch suffix {
        case "s": return (letter, 1)
        case "ss": return (letter, 2)
        case "f": return (letter, -1)
        case "ff": return (letter, -2)
        default: throw ResolveError.unknownPitchName(name)
        }
    }

    // MARK: - Time

    private static func ticks(of duration: DurationToken) -> Int {
        var base = ResolvedMusic.ticksPerQuarter * 4 / duration.value
        var dotValue = base
        for _ in 0..<duration.dots {
            dotValue /= 2
            base += dotValue
        }
        return base
    }
}
