# Lessons — the bug catalog, told as stories

One write-up per regression bug (PLAN.md §6). These are the pedagogical crown jewels: each
real prototype bug becomes a named Swift regression test plus a story here (symptom → root
cause → the guard). Use `TEMPLATE.md`.

| Bug | Title | Layer | Guard status | Story |
|---|---|---|---|---|
| BUG-001 | Chord tokens split on whitespace | Tokenizer | guarded (Phase 1) | [story](bug-001-chords-split-on-whitespace.md) |
| BUG-002 | Relative octave threaded through `\repeat unfold` | Resolver | guarded (Phase 2) | [story](bug-002-relative-threaded-through-repeat.md) |
| BUG-003 | `\crossStaff { }` treated as parallel separator | Parser | guarded (Phase 2) | [story](bug-003-crossstaff-braces-split-voices.md) |
| BUG-004 | Sub-audible octave-0 bass; clamping hid it | Resolver/Validator | guarded (Phase 3) | [story](bug-004-clamp-hid-subaudible-bass.md) |
| BUG-005 | Polyphony wrapper glued to a pitch broke chords | Tokenizer | guarded (Phase 1) | [story](bug-005-glued-polyphony-wrapper.md) |
| BUG-006 | Voice-length mismatch (Clair de Lune) | Validator | institutionalized; alignment SOLVED in Phase 4, register drift closed with issue #1 | [story](bug-006-voice-length-mismatch.md) |
| BUG-007 | Parallel music placed from the door, not the thread | Resolver | guarded (issue #1) — the only bug born in THIS engine, and the prototype shared it | [story](bug-007-parallel-relative-door-context.md) |
