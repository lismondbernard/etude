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
public struct NoteToken: Equatable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

/// One lexical unit of LilyPond source.
public enum Token: Equatable, Sendable {
    case note(NoteToken)
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
                var word = ""
                while i < chars.count, chars[i].isLetter {
                    word.append(chars[i])
                    i += 1
                }
                tokens.append(.note(NoteToken(name: word)))
                continue
            }
            i += 1
        }
        return tokens
    }
}
