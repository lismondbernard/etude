// Resolver — event tree → absolute timed events   (implemented in Phase 2)
//
// - `\relative` octave resolution: each note is placed within a fourth of the
//   previous note, then `'`/`,` adjust. Chord semantics follow LilyPond: the first
//   chord note relates to the previous context; subsequent notes relate within the
//   chord; context after the chord continues from the first note.
// - `\repeat volta/unfold n { … }`: resolve the body ONCE, then copy the resolved
//   events — never re-thread the relative context through repetitions (BUG-002).
// - Per-section `\relative` anchors re-anchor at each section head (Gnossienne,
//   Clair sources use this).
//
// Property laws this must satisfy (Phase 2 tests):
//   (a) resolve∘transpose == transpose∘resolve on pitch classes
//   (b) `unfold n` yields exactly n× the body events, pairwise identical
//   (c) octave marks are inverses: `'` then `,` restores pitch
//
// A `ParallelMusicExpander` (round-robin bar distribution) lands here in Phase 4 for
// the Clair de Lune boss fight — see PLAN.md §7.

// Intentionally empty in Phase 0.
