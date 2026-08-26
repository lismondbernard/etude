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
public enum RepeatStyle: String, Equatable, Sendable, Codable {
    case volta, unfold
}

/// One node of the LilyPond-shaped parse tree. Pitches are still relative,
/// repeats unexpanded, tuplet fractions unapplied — resolving all of that is
/// the Resolver's job, and this shape must not appear past it.
public indirect enum MusicNode: Equatable, Sendable, Codable {
    case note(NoteToken, tied: Bool)
    case rest(RestToken)
    case chord([NoteToken], duration: DurationToken?, tied: Bool)
    case chordRepeat(duration: DurationToken?)
    case sequence([MusicNode])
    case parallel([MusicNode])
    case relative(anchor: NoteToken?, body: [MusicNode])
    case repeated(RepeatStyle, count: Int, body: [MusicNode], alternatives: [[MusicNode]])
    /// Durations in `body` are scaled by `scaleNumerator/scaleDenominator`.
    /// `\times 3/2` stores its fraction as written; `\tuplet 3/2` (3 in the
    /// time of 2) stores the inverse.
    case tuplet(scaleNumerator: Int, scaleDenominator: Int, body: [MusicNode])
    /// Ornamental notes that steal time from the note that follows the group;
    /// an acciaccatura is played very short regardless of written duration.
    case grace([MusicNode], acciaccatura: Bool)
    /// A note turned silent by `\rest`: placed (and octave-threaded) like the
    /// written pitch, but nothing sounds.
    case pitchedRest(NoteToken)
    case meter(beats: Int, beatUnit: Int)
    case tempo(label: String?, beatUnit: Int?, beatsPerMinute: Int?)
    /// A use of a named definition (`\themeOneMelody`). Unresolved here —
    /// binding it to its definition is the Resolver's job, so an unknown name
    /// fails loudly there rather than silently at parse time.
    case reference(String)
    /// A `\new <Type>` wrapper (Staff, Voice, PianoStaff) around one music
    /// expression. Voice/staff STRUCTURE is interpreted from these when the
    /// score is assembled; inside a melody line they group like braces.
    case context(type: String, body: MusicNode)
}

/// A parsed `.ly` file: named definitions plus (in later cycles) header
/// metadata and the `\score` assembly. Still LilyPond-shaped (§0.4).
public struct LilyFile: Equatable, Sendable {
    public let header: [String: String]
    public let definitions: [String: MusicNode]
    /// The `\score` assembly — staves and voices, usually referencing the
    /// named definitions. `nil` when the file only defines material.
    public let score: MusicNode?

    public init(
        header: [String: String] = [:],
        definitions: [String: MusicNode],
        score: MusicNode? = nil
    ) {
        self.header = header
        self.definitions = definitions
        self.score = score
    }
}

/// Recursive-descent parser over the tokenizer's stream. Stateless between
/// runs; all per-run state lives inside `parseMusic`.
public struct Parser: Sendable {
    public init() {}

    /// Parses a whole `.ly` file: top-level assignments and declarations.
    public func parseFile(_ tokens: [Token]) throws(ParseError) -> LilyFile {
        var header: [String: String] = [:]
        var definitions: [String: MusicNode] = [:]
        var score: MusicNode?
        var i = 0
        while i < tokens.count {
            switch tokens[i] {
            case .command("header"):
                i += 1
                header = try parseHeaderBlock(tokens, &i)
            case .command("score"):
                i += 1
                let body = try parseBracedBody(tokens, &i)
                score = body.count == 1 ? body[0] : .sequence(body)
            case .identifier(let name) where i + 1 < tokens.count && tokens[i + 1] == .equals:
                i += 2
                definitions[name] = try parseExpression(tokens, &i)
            case .command("version"), .command("language"), .command("include"):
                i += 1
                if i < tokens.count, case .string = tokens[i] {
                    i += 1
                }
            default:
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
        }
        return LilyFile(header: header, definitions: definitions, score: score)
    }

    /// Consumes `{ field = "value" … }` — the metadata block.
    private func parseHeaderBlock(
        _ tokens: [Token], _ i: inout Int
    ) throws(ParseError) -> [String: String] {
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        guard tokens[i] == .braceOpen else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        i += 1
        var fields: [String: String] = [:]
        while i < tokens.count {
            switch tokens[i] {
            case .braceClose:
                i += 1
                return fields
            case .identifier(let field) where i + 1 < tokens.count && tokens[i + 1] == .equals:
                i += 2
                guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
                guard case .string(let value) = tokens[i] else {
                    throw ParseError.unexpectedToken(tokens[i], index: i)
                }
                fields[field] = value
                i += 1
            default:
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
        }
        throw ParseError.unexpectedEndOfInput
    }

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
                if i + 1 < tokens.count, tokens[i + 1] == .command("rest") {
                    nodes.append(.pitchedRest(noteToken))
                    i += 2
                } else {
                    nodes.append(.note(noteToken, tied: false))
                    i += 1
                }
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
            case .slurOpen, .slurClose, .barCheck:
                // Engraving punctuation — no performed meaning.
                i += 1
            case .command(let name) where Self.engravingCommands.contains(name):
                i += 1
            case .command("version"), .command("language"), .command("include"):
                // Declarations whose string argument the tokenizer has already
                // acted on (note-name language) or that only matter to LilyPond.
                i += 1
                if i < tokens.count, case .string = tokens[i] {
                    i += 1
                }
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
        case "times", "tuplet":
            i += 1
            let (a, b) = try parseFraction(tokens, &i)
            let (num, den) = name == "times" ? (a, b) : (b, a)
            return .tuplet(scaleNumerator: num, scaleDenominator: den,
                           body: try parseBracedBody(tokens, &i))
        case "new":
            i += 1
            guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
            guard case .identifier(let contextType) = tokens[i] else {
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
            i += 1
            return .context(type: contextType, body: try parseExpression(tokens, &i))
        case "crossStaff":
            // Engraving hint about which staff prints the notes; its braces
            // group exactly like bare `{ }` — never voice separators (BUG-003).
            i += 1
            return .sequence(try parseBracedBody(tokens, &i))
        case "grace", "acciaccatura":
            i += 1
            return .grace(try parseBracedBody(tokens, &i), acciaccatura: name == "acciaccatura")
        case "time":
            i += 1
            let (beats, unit) = try parseFraction(tokens, &i)
            return .meter(beats: beats, beatUnit: unit)
        case "tempo":
            i += 1
            var label: String?
            if i < tokens.count, case .string(let text) = tokens[i] {
                label = text
                i += 1
            }
            // The `4 = 66` metronome mark is optional after a label.
            guard i < tokens.count, case .number(let unit) = tokens[i] else {
                return .tempo(label: label, beatUnit: nil, beatsPerMinute: nil)
            }
            i += 1
            guard i < tokens.count, tokens[i] == .equals else {
                throw ParseError.unexpectedToken(tokens[i - 1], index: i - 1)
            }
            i += 1
            guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
            guard case .number(let bpm) = tokens[i] else {
                throw ParseError.unexpectedToken(tokens[i], index: i)
            }
            i += 1
            return .tempo(label: label, beatUnit: unit, beatsPerMinute: bpm)
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
            // Any command with no grammar of its own reads as a reference to a
            // named definition.
            i += 1
            return .reference(name)
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

    /// Engraving-only commands: they shape the printed page, not the
    /// performance, so the tree drops them.
    private static let engravingCommands: Set<String> = [
        "voiceOne", "voiceTwo", "once", "hideNotes",
        "stemUp", "stemDown", "stemNeutral",
        "tieUp", "tieDown", "tieNeutral",
        "slurUp", "slurDown", "phrasingSlurUp", "phrasingSlurDown",
        "dynamicUp", "dynamicDown", "break", "pageBreak", "noBreak",
    ]

    /// Consumes an `n/d` fraction.
    private func parseFraction(
        _ tokens: [Token], _ i: inout Int
    ) throws(ParseError) -> (Int, Int) {
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        guard case .number(let numerator) = tokens[i] else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        i += 1
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        guard tokens[i] == .slash else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        i += 1
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        guard case .number(let denominator) = tokens[i] else {
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
        i += 1
        return (numerator, denominator)
    }

    /// Parses exactly one music expression — a braced sequence, a parallel
    /// group, or a command form (reference, relative block, …).
    private func parseExpression(
        _ tokens: [Token], _ i: inout Int
    ) throws(ParseError) -> MusicNode {
        guard i < tokens.count else { throw ParseError.unexpectedEndOfInput }
        switch tokens[i] {
        case .braceOpen:
            i += 1
            return .sequence(try parseSequence(tokens, &i, endingAt: .braceClose))
        case .parallelStart:
            i += 1
            return .parallel(try parseSequence(tokens, &i, endingAt: .parallelEnd))
        case .command(let name):
            return try parseCommand(name, tokens, &i)
        default:
            throw ParseError.unexpectedToken(tokens[i], index: i)
        }
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
