// Tokenizer — `.ly` text → `[Token]`   (implemented in Phase 1, test-first)
//
// Handles note names (Dutch `c d e f g a b` + `is`/`es`, and English mode via
// `\language "english"` / `\include "english.ly"` with `cs`/`df`), octave marks
// `'`/`,`, durations (`1 2 4 8 16` + dots), chords `<c e g>`, chord-repeat `q`,
// rests `r`/`s`, ties `~`, braces, `<< … >>` parallel markers, and commands
// (`\relative`, `\repeat`, `\times`/`\tuplet`, `\grace`, `\acciaccatura`, `\key`,
// `\time`, `\tempo`, `\crossStaff`, `\ottava`), comments `%`, and strings.
//
// CRITICAL: chords contain spaces — tokenize structurally, never by whitespace
// split (BUG-001). The tokenizer must never crash on arbitrary bytes; it may only
// throw a typed error (fuzz smoke test in Phase 1).

// Intentionally empty in Phase 0. Types land here in Phase 1.
