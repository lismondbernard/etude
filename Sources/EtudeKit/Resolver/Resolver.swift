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

    public func resolve(_ music: [MusicNode]) throws(ResolveError) -> ResolvedMusic {
        var state = State()
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

        mutating func ticks(for written: DurationToken?) -> Int {
            if let written { lastDuration = written }
            return Resolver.ticks(of: lastDuration)
        }
    }

    private func resolveSequence(
        _ music: [MusicNode], into state: inout State
    ) throws(ResolveError) {
        for node in music {
            switch node {
            case .note(let noteToken, _):
                let midi = try midiNote(of: noteToken, in: &state)
                let ticks = state.ticks(for: noteToken.duration)
                state.notes.append(
                    ResolvedNote(midiNote: midi, startTick: state.tick, durationTicks: ticks))
                state.tick += ticks
            case .chord(let pitches, let duration, _):
                let ticks = state.ticks(for: duration)
                var sounded: [Int] = []
                var firstReference: (letter: Int, octave: Int)?
                for (index, pitch) in pitches.enumerated() {
                    // First note against the outer context; later notes within
                    // the chord; afterwards the context continues from the
                    // FIRST note (LilyPond's chord rule).
                    let midi = try midiNote(of: pitch, in: &state)
                    if index == 0 { firstReference = state.reference }
                    sounded.append(midi)
                    state.notes.append(
                        ResolvedNote(midiNote: midi, startTick: state.tick, durationTicks: ticks))
                }
                if let firstReference { state.reference = firstReference }
                state.lastChord = sounded
                state.tick += ticks
            case .chordRepeat(let duration):
                guard let chord = state.lastChord else {
                    throw ResolveError.chordRepeatWithoutChord
                }
                let ticks = state.ticks(for: duration)
                for midi in chord {
                    state.notes.append(
                        ResolvedNote(midiNote: midi, startTick: state.tick, durationTicks: ticks))
                }
                state.tick += ticks
            case .relative(let anchor, let body):
                let outer = state.reference
                let anchorNote = anchor ?? NoteToken(name: "f")
                let (letter, _) = try spelledPitch(anchorNote.name)
                state.reference = (letter, 3 + anchorNote.octaveMarks)
                try resolveSequence(body, into: &state)
                state.reference = outer
            case .rest(let restToken):
                // Sounding, spacer, or multi-measure: performed identically —
                // silence for the written span.
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
