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
    case unexpectedEndOfInput
}

/// How a `\repeat` block is performed: `volta` plays the body then any
/// alternative endings; `unfold` writes the body out `count` times.
public enum RepeatStyle: String, Equatable, Sendable {
    case volta, unfold
}

/// One node of the LilyPond-shaped parse tree. Pitches are still relative,
/// repeats unexpanded, tuplet fractions unapplied — resolving all of that is
/// the Resolver's job, and this shape must not appear past it.
public indirect enum MusicNode: Equatable, Sendable {
    case note(NoteToken, tied: Bool)
    case rest(RestToken)
    case chord([NoteToken], duration: DurationToken?, tied: Bool)
    case chordRepeat(duration: DurationToken?)
    case sequence([MusicNode])
    case parallel([MusicNode])
    case relative(anchor: NoteToken?, body: [MusicNode])
    case repeated(RepeatStyle, count: Int, body: [MusicNode], alternatives: [[MusicNode]])
}

/// Recursive-descent parser over the tokenizer's stream. Stateless between
/// runs; all per-run state lives inside `parseMusic`.
public struct Parser: Sendable {
    public init() {}

    /// Parses a music expression sequence — the inside of a `{ … }` block.
    public func parseMusic(_ tokens: [Token]) throws(ParseError) -> [MusicNode] {
        var i = 0
        let nodes = try parseSequence(tokens, &i, endingAt: nil)
        guard i == tokens.count else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        return nodes
    }

    /// Parses expressions until `terminator` (consumed) or, with no terminator,
    /// the end of the stream. Reaching the end while a terminator is still owed
    /// is an unterminated group.
    private func parseSequence(
        _ tokens: [Token], _ i: inout Int, endingAt terminator: Token?
    ) throws(ParseError) -> [MusicNode] {
        var nodes: [MusicNode] = []
        while i < tokens.count {
            if let terminator, tokens[i] == terminator {
                i += 1
                return nodes
            }
            switch tokens[i] {
            case .braceOpen:
                i += 1
                nodes.append(.sequence(try parseSequence(tokens, &i, endingAt: .braceClose)))
            case .parallelStart:
                // Each element parsed between `<<` and `>>` is one simultaneous
                // child expression — a bare event or a braced sequence.
                i += 1
                nodes.append(.parallel(try parseSequence(tokens, &i, endingAt: .parallelEnd)))
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
            case .command("alternative"):
                // Alternative endings are not standalone music — they modify
                // the repeat that precedes them.
                guard case .repeated(let style, let count, let body, []) = nodes.last else {
                    throw ParseError.unexpectedToken(.command("alternative"), index: i)
                }
                i += 1
                nodes[nodes.count - 1] = .repeated(
                    style, count: count, body: body,
                    alternatives: try parseAlternativeGroups(tokens, &i)
                )
            case .command(let name):
                nodes.append(try parseCommand(name, tokens, &i))
            default:
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
        }
        guard terminator == nil else { throw ParseError.unexpectedEndOfInput }
        return nodes
    }

    /// Parses one `\command` and whatever arguments its form requires;
    /// `i` sits on the command token on entry.
    private func parseCommand(
        _ name: String, _ tokens: [Token], _ i: inout Int
    ) throws(ParseError) -> MusicNode {
        switch name {
        case "relative":
            i += 1
            var anchor: NoteToken?
            if i < tokens.count, case .note(let pitch) = tokens[i] {
                anchor = pitch
                i += 1
            }
            return .relative(anchor: anchor, body: try parseBracedBody(tokens, &i))
        case "repeat":
            i += 1
            guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
            guard case .identifier(let styleWord) = tokens[i],
                  let style = RepeatStyle(rawValue: styleWord) else {
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
            i += 1
            guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
            guard case .number(let count) = tokens[i] else {
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
            i += 1
            return .repeated(style, count: count, body: try parseBracedBody(tokens, &i), alternatives: [])
        default:
            throw ParseError.unexpectedToken(.command(name), index: i)
        }
    }

    /// Consumes `{ { … } { … } }` — the endings list of an `\alternative`.
    private func parseAlternativeGroups(
        _ tokens: [Token], _ i: inout Int
    ) throws(ParseError) -> [[MusicNode]] {
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        guard tokens[i] == .braceOpen else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        i += 1
        var groups: [[MusicNode]] = []
        while i < tokens.count {
            switch tokens[i] {
            case .braceOpen:
                i += 1
                groups.append(try parseSequence(tokens, &i, endingAt: .braceClose))
            case .braceClose:
                i += 1
                return groups
            default:
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
        }
        throw ParseError.unexpectedEndOfInput
    }

    /// Consumes a required `{ … }` group and returns its contents.
    private func parseBracedBody(
        _ tokens: [Token], _ i: inout Int
    ) throws(ParseError) -> [MusicNode] {
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        guard tokens[i] == .braceOpen else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        i += 1
        return try parseSequence(tokens, &i, endingAt: .braceClose)
    }
}
