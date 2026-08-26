// Parser — `[Token]` → raw event tree   (Phase 2, built test-first)
//
// Recursive-descent parse into a tree of notes/chords/rests with relative pitch
// context still UNRESOLVED (§0.4: the tree is LilyPond-shaped and never travels
// past the Resolver). Captures repeat blocks, tuplet groupings, grace groups,
// and parallel `<<…>>` groups.
//
// `\crossStaff { … }` braces are grouping no-ops, NOT parallel separators (BUG-003).

/// A syntactic error, carrying the offending token and its stream index.
public enum ParseError: Error, Equatable, Sendable {
    case unexpectedToken(Token, index: Int)
}

/// One node of the LilyPond-shaped parse tree. Pitches are still relative,
/// repeats unexpanded, tuplet fractions unapplied — resolving all of that is
/// the Resolver's job, and this shape must not appear past it.
public indirect enum MusicNode: Equatable, Sendable {
    case note(NoteToken, tied: Bool)
    case rest(RestToken)
    case chord([NoteToken], duration: DurationToken?, tied: Bool)
    case chordRepeat(duration: DurationToken?)
}

/// Recursive-descent parser over the tokenizer's stream. Stateless between
/// runs; all per-run state lives inside `parseMusic`.
public struct Parser: Sendable {
    public init() {}

    /// Parses a music expression sequence — the inside of a `{ … }` block.
    public func parseMusic(_ tokens: [Token]) throws(ParseError) -> [MusicNode] {
        var nodes: [MusicNode] = []
        var i = 0
        while i < tokens.count {
            switch tokens[i] {
            case .note(let noteToken):
                nodes.append(.note(noteToken, tied: false))
                i += 1
            case .rest(let restToken):
                nodes.append(.rest(restToken))
                i += 1
            case .tie:
                // A tie is not an event of its own — it marks the preceding
                // note or chord as sustained into the next.
                switch nodes.last {
                case .note(let noteToken, _):
                    nodes[nodes.count - 1] = .note(noteToken, tied: true)
                case .chord(let pitches, let duration, _):
                    nodes[nodes.count - 1] = .chord(pitches, duration: duration, tied: true)
                default:
                    throw ParseError.unexpectedToken(.tie, index: i)
                }
                i += 1
            case .chordStart:
                i += 1
                var pitches: [NoteToken] = []
                scan: while i < tokens.count {
                    switch tokens[i] {
                    case .note(let pitch):
                        pitches.append(pitch)
                        i += 1
                    case .chordEnd(let duration):
                        nodes.append(.chord(pitches, duration: duration, tied: false))
                        i += 1
                        break scan
                    default:
                        throw ParseError.unexpectedToken(tokens[i], index: i)
                    }
                }
            case .chordRepeat(let duration):
                nodes.append(.chordRepeat(duration: duration))
                i += 1
            default:
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
        }
        return nodes
    }
}
