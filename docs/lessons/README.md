# Lessons — the bug catalog, told as stories

One write-up per regression bug (PLAN.md §6). These are the pedagogical crown jewels: each
real prototype bug becomes a named Swift regression test plus a story here (symptom → root
cause → the guard). Use `TEMPLATE.md`.

| Bug | Title | Layer | Guard status |
|---|---|---|---|
| BUG-001 | Chord tokens split on whitespace | Tokenizer | Phase 1 |
| BUG-002 | Relative octave threaded through `\repeat unfold` | Resolver | Phase 2 |
| BUG-003 | `\crossStaff { }` treated as parallel separator | Parser | Phase 2 |
| BUG-004 | Sub-audible octave-0 bass; clamping hid it | Resolver/Validator | Phase 3 |
| BUG-005 | Polyphony wrapper glued to a pitch broke chords | Tokenizer | Phase 1 |
| BUG-006 | Voice-length mismatch (Clair de Lune) | Validator | Phase 4 (known issue) |
