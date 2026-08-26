# Lesson: BUG-005 — Polyphony wrapper glued to a pitch broke chord parsing

## Symptom
The Gnossienne writes `<<af2 …` — a simultaneous-music wrapper glued directly to
a pitch. The prototype, seeing `<`-prefixed text, treated the whole word as a
malformed chord opening and corrupted the voice structure after it.

## Root cause
Structural markers and pitch tokens were separated by whitespace assumptions,
not by grammar (BUG-001's sibling, one layer up).

## The guard now in place
`BUG005_ParallelMarkerGluedToPitch` runs the exact source fragment: `<<` is
recognized wherever it appears, and the pitch after it tokenizes exactly as it
would after whitespace.

## Lesson
Test with the exact hostile fragment from the wild. Synthetic examples are tidy;
real sources glue things together.
