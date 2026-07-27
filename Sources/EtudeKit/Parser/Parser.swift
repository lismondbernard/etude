// Parser — `[Token]` → raw event tree   (implemented in Phase 2)
//
// Recursive-descent parse into a tree of notes/chords/rests with relative pitch
// context still UNRESOLVED. Captures repeat blocks, tuplet groupings
// (`\times 2/3 { … }` scales durations), grace groups (steal time from the
// following note; acciaccatura ≈ very short), and parallel `<<…>>` groups.
//
// `\crossStaff { … }` braces are grouping no-ops, NOT parallel separators (BUG-003).
// Errors are a typed `ParseError` carrying source location. The event tree is
// Codable so it can be snapshot-tested (tree → JSON, compared to a fixture).

// Intentionally empty in Phase 0.
