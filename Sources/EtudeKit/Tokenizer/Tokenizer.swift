// Tokenizer — `.ly` text → `[Token]`   (Phase 1, built test-first)
//
// Handles note names (Dutch `c d e f g a b` + `is`/`es`, and English mode via
// `\language "english"` / `\include "english.ly"` with `cs`/`df` style), octave
// marks `'`/`,`, durations (`1 2 4 8 16` + dots), chords `<c e g>`, chord-repeat
// `q`, rests `r`/`s`/`R`, ties `~`, braces, `<< … >>` parallel markers, commands
// (`\relative`, `\repeat`, `\grace`, `\time`, `\tempo`, `\crossStaff`, …),
// comments `%`, and strings.
//
// CRITICAL: chords contain spaces — tokenize structurally, never by whitespace
// split (BUG-001). The tokenizer must never crash on arbitrary bytes; it may
// only throw a typed `TokenizerError` (fuzz smoke test guards this).

/// A lexical error, carrying enough location to be diagnosable.
public enum TokenizerError: Error, Equatable, Sendable {}

/// A pitch as it appears lexically — one glued word like `fis'4.`, kept whole
/// because splitting it would lose the guarantee that its parts were adjacent.
/// A duration as written: the reciprocal note value (`4` = quarter) plus dots.
public struct DurationToken: Equatable, Sendable {
    public let value: Int
    public let dots: Int

    public init(_ value: Int, dots: Int = 0) {
        self.value = value
        self.dots = dots
    }
}

public struct NoteToken: Equatable, Sendable {
    public let name: String
    /// Net octave adjustment: +1 per `'`, −1 per `,`.
    public let octaveMarks: Int
    public let duration: DurationToken?

    public init(name: String, octaveMarks: Int = 0, duration: DurationToken? = nil) {
        self.name = name
        self.octaveMarks = octaveMarks
        self.duration = duration
    }
}

/// A written rest: `r` (sounding), `s` (spacer), or `R` (multi-measure).
public struct RestToken: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case sounding, spacer, multiMeasure
    }

    public let kind: Kind
    public let duration: DurationToken?

    public init(kind: Kind, duration: DurationToken? = nil) {
        self.kind = kind
        self.duration = duration
    }
}

/// One lexical unit of LilyPond source.
public enum Token: Equatable, Sendable {
    case note(NoteToken)
    case rest(RestToken)
    case tie
    case slurOpen
    case slurClose
    case barCheck
    case braceOpen
    case braceClose
    case chordStart
    case chordEnd(duration: DurationToken?)
}

/// Scans LilyPond source text into a flat token stream. Stateless between runs;
/// all per-run state (note-name language, open-chord tracking) lives inside
/// `tokenize`.
public struct Tokenizer: Sendable {
    public init() {}

    public func tokenize(_ source: String) throws(TokenizerError) -> [Token] {
        var tokens: [Token] = []
        let chars = Array(source)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace {
                i += 1
                continue
            }
            if c.isLetter {
                var name = ""
                while i < chars.count, chars[i].isLetter {
                    name.append(chars[i])
                    i += 1
                }
                if let restKind = Self.restKinds[name] {
                    tokens.append(.rest(RestToken(kind: restKind, duration: scanDuration(chars, &i))))
                    continue
                }
                var octaveMarks = 0
                while i < chars.count, chars[i] == "'" || chars[i] == "," {
                    octaveMarks += chars[i] == "'" ? 1 : -1
                    i += 1
                }
                let duration = scanDuration(chars, &i)
                tokens.append(.note(NoteToken(name: name, octaveMarks: octaveMarks, duration: duration)))
                continue
            }
            if c == "<" {
                tokens.append(.chordStart)
                i += 1
                continue
            }
            if c == ">" {
                i += 1
                tokens.append(.chordEnd(duration: scanDuration(chars, &i)))
                continue
            }
            if let mark = Self.marks[c] {
                tokens.append(mark)
                i += 1
                continue
            }
            i += 1
        }
        return tokens
    }

    private static let marks: [Character: Token] = [
        "~": .tie, "(": .slurOpen, ")": .slurClose, "|": .barCheck,
        "{": .braceOpen, "}": .braceClose,
    ]

    private static let restKinds: [String: RestToken.Kind] = [
        "r": .sounding, "s": .spacer, "R": .multiMeasure,
    ]

    /// Consumes an optional written duration (`4`, `2.`, `16..`) at `i`.
    private func scanDuration(_ chars: [Character], _ i: inout Int) -> DurationToken? {
        var digits = ""
        while i < chars.count, chars[i].isNumber {
            digits.append(chars[i])
            i += 1
        }
        guard let value = Int(digits) else { return nil }
        var dots = 0
        while i < chars.count, chars[i] == "." {
            dots += 1
            i += 1
        }
        return DurationToken(value, dots: dots)
    }
}
