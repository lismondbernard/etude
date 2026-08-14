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
public enum TokenizerError: Error, Equatable, Sendable {
    case unexpectedCharacter(Character, line: Int, column: Int)
    case unterminatedString(line: Int, column: Int)
    case unterminatedChord(line: Int, column: Int)
    case malformedNumber(line: Int, column: Int)
}

/// A duration as written: the reciprocal note value (`4` = quarter) plus dots.
public struct DurationToken: Equatable, Sendable {
    public let value: Int
    public let dots: Int

    public init(_ value: Int, dots: Int = 0) {
        self.value = value
        self.dots = dots
    }
}

/// A pitch as it appears lexically — one glued word like `fis'4.`, kept whole
/// because splitting it would lose the guarantee that its parts were adjacent.
public struct NoteToken: Equatable, Sendable {
    public let name: String
    /// Net octave adjustment: +1 per `'`, −1 per `,`.
    public let octaveMarks: Int
    /// A trailing `!` — the engraver's cautionary/forced accidental.
    public let forcedAccidental: Bool
    public let duration: DurationToken?

    public init(
        name: String,
        octaveMarks: Int = 0,
        forcedAccidental: Bool = false,
        duration: DurationToken? = nil
    ) {
        self.name = name
        self.octaveMarks = octaveMarks
        self.forcedAccidental = forcedAccidental
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
    case chordRepeat(duration: DurationToken?)
    case parallelStart
    case parallelEnd
    case command(String)
    case identifier(String)
    case number(Int)
    case slash
    case equals
    case string(String)
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
        var inChord = false
        var chordOpening = 0
        var language = NoteLanguage.dutch
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
                    tokens.append(.rest(RestToken(kind: restKind, duration: try scanDuration(chars, &i))))
                    continue
                }
                if name == "q" {
                    tokens.append(.chordRepeat(duration: try scanDuration(chars, &i)))
                    continue
                }
                guard isPitchName(name, language: language) else {
                    tokens.append(.identifier(name))
                    continue
                }
                tokens.append(.note(try scanNoteSuffixes(named: name, chars, &i)))
                continue
            }
            if c == "\\" {
                i += 1
                var name = ""
                while i < chars.count, chars[i].isLetter {
                    name.append(chars[i])
                    i += 1
                }
                tokens.append(.command(name))
                continue
            }
            if c == "<" {
                // `<<` opens simultaneous music; a single `<` opens a chord.
                if i + 1 < chars.count, chars[i + 1] == "<", !inChord {
                    tokens.append(.parallelStart)
                    i += 2
                } else {
                    tokens.append(.chordStart)
                    inChord = true
                    chordOpening = i
                    i += 1
                }
                continue
            }
            if c == ">" {
                // Inside a chord, `>` always closes the chord — even when the
                // very next character is another `>` (as in `…>>` after a glued
                // `<<chord`). Outside one, `>>` closes simultaneous music.
                if inChord {
                    inChord = false
                    i += 1
                    tokens.append(.chordEnd(duration: try scanDuration(chars, &i)))
                } else if i + 1 < chars.count, chars[i + 1] == ">" {
                    tokens.append(.parallelEnd)
                    i += 2
                } else {
                    i += 1
                    tokens.append(.chordEnd(duration: try scanDuration(chars, &i)))
                }
                continue
            }
            if c == "%" {
                while i < chars.count, !chars[i].isNewline {
                    i += 1
                }
                continue
            }
            if c == "\"" {
                let opening = i
                i += 1
                var text = ""
                while i < chars.count, chars[i] != "\"" {
                    text.append(chars[i])
                    i += 1
                }
                guard i < chars.count else {
                    let (line, column) = location(of: opening, in: chars)
                    throw TokenizerError.unterminatedString(line: line, column: column)
                }
                i += 1
                // A string names the note language when it follows `\language`
                // or an `\include` of a language file.
                if case .command(let name) = tokens.last,
                   name == "language" || name == "include",
                   text == "english" || text == "english.ly" {
                    language = .english
                }
                tokens.append(.string(text))
                continue
            }
            if c.isNumber {
                let start = i
                var digits = ""
                while i < chars.count, chars[i].isNumber {
                    digits.append(chars[i])
                    i += 1
                }
                guard let value = Int(digits) else {
                    let (line, column) = location(of: start, in: chars)
                    throw TokenizerError.malformedNumber(line: line, column: column)
                }
                tokens.append(.number(value))
                continue
            }
            if let mark = Self.marks[c] {
                tokens.append(mark)
                i += 1
                continue
            }
            let (line, column) = location(of: i, in: chars)
            throw TokenizerError.unexpectedCharacter(c, line: line, column: column)
        }
        if inChord {
            let (line, column) = location(of: chordOpening, in: chars)
            throw TokenizerError.unterminatedChord(line: line, column: column)
        }
        return tokens
    }

    /// 1-based line/column of `index` — computed only on the error path, so the
    /// scanning loop carries no position bookkeeping.
    private func location(of index: Int, in chars: [Character]) -> (line: Int, column: Int) {
        var line = 1, column = 1
        for c in chars.prefix(index) {
            if c.isNewline {
                line += 1
                column = 1
            } else {
                column += 1
            }
        }
        return (line, column)
    }

    private static let marks: [Character: Token] = [
        "~": .tie, "(": .slurOpen, ")": .slurClose, "|": .barCheck,
        "{": .braceOpen, "}": .braceClose, "/": .slash, "=": .equals,
    ]

    private enum NoteLanguage {
        case dutch, english
    }

    /// Dutch grammar: a base letter `a`–`g` plus any run of `is` (sharp) /
    /// `es` (flat) suffixes — the bare-vowel flats (`as`, `es`) are deliberately
    /// unsupported until a corpus piece needs them. English grammar (`cs`/`df`
    /// style): the base letter plus one of `s`, `f`, `ss`, `ff`.
    private func isPitchName(_ word: String, language: NoteLanguage) -> Bool {
        guard let first = word.first, "abcdefg".contains(first) else { return false }
        let rest = Substring(word.dropFirst())
        switch language {
        case .dutch:
            var suffix = rest
            while !suffix.isEmpty {
                if suffix.hasPrefix("is") || suffix.hasPrefix("es") {
                    suffix = suffix.dropFirst(2)
                } else {
                    return false
                }
            }
            return true
        case .english:
            return ["", "s", "f", "ss", "ff"].contains(rest)
        }
    }

    private static let restKinds: [String: RestToken.Kind] = [
        "r": .sounding, "s": .spacer, "R": .multiMeasure,
    ]

    /// Consumes a pitch word's glued suffixes — octave marks, forced
    /// accidental, duration — and assembles the note token.
    private func scanNoteSuffixes(
        named name: String, _ chars: [Character], _ i: inout Int
    ) throws(TokenizerError) -> NoteToken {
        var octaveMarks = 0
        while i < chars.count, chars[i] == "'" || chars[i] == "," {
            octaveMarks += chars[i] == "'" ? 1 : -1
            i += 1
        }
        var forced = false
        if i < chars.count, chars[i] == "!" {
            forced = true
            i += 1
        }
        return NoteToken(
            name: name,
            octaveMarks: octaveMarks,
            forcedAccidental: forced,
            duration: try scanDuration(chars, &i)
        )
    }

    /// Consumes an optional written duration (`4`, `2.`, `16..`) at `i`.
    private func scanDuration(_ chars: [Character], _ i: inout Int) throws(TokenizerError) -> DurationToken? {
        let start = i
        var digits = ""
        while i < chars.count, chars[i].isNumber {
            digits.append(chars[i])
            i += 1
        }
        guard !digits.isEmpty else { return nil }
        guard let value = Int(digits) else {
            let (line, column) = location(of: start, in: chars)
            throw TokenizerError.malformedNumber(line: line, column: column)
        }
        var dots = 0
        while i < chars.count, chars[i] == "." {
            dots += 1
            i += 1
        }
        return DurationToken(value, dots: dots)
    }
}
