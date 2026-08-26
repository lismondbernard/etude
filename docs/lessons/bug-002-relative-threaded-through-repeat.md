# Lesson: BUG-002 — Relative octave threaded through `\repeat unfold`

## Symptom
The Gnossienne's bass pedal `\repeat unfold 6 { f,1 | }` marched downward —
F2, F1, F0 — instead of holding its pedal, because each pass re-applied the `,`
mark to wherever the previous pass had ended.

## Root cause
The repeat was expanded by re-walking the body text once per pass, threading the
relative-octave context through every repetition. The `,` compounds.

## The guard now in place
The Resolver resolves a repeat body ONCE and copies the resolved events
(`BUG002_RelativeOctaveThreadedThroughRepeat`), and a property law pins the
class: `unfold n` is exactly n pairwise-identical copies of the body.

## Lesson
Resolve once, then copy. When expansion and stateful resolution are interleaved,
state leaks between iterations; separate them and the law becomes provable.
