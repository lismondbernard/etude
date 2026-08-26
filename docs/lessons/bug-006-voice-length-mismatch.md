# Lesson: BUG-006 — Voice-length mismatch (Clair de Lune)

## Symptom
The prototype's Clair de Lune section 1 timed out at 91 / 46 / 57 / 54 beats
across its four voices — dense polyphony it could not align, discovered only
because a length check existed at all.

## Root cause
Many small parsing gaps compounding: block comments that ate same-line music,
separated durations, zero-width spacers, duration multipliers, partial ties.
Each dropped or stretched time differently per voice.

## The guard now in place
This bug was never "fixed" — it was INSTITUTIONALIZED as the Validator's voice
alignment invariant, so the whole class of failure is loud forever. The Swift
rewrite then passed it: all four voices align at 72 bars of 9/8, section by
section, and the compact and expanded sources agree note for note
(`ClairDeLuneSourcesAgreeTests`). What remains open is different and smaller:
lhDown's sub-piano register drift, pinned by the register invariant as
issue #1 (`BuildClairDeLuneTests`, `withKnownIssue` — ADR-0003).

## Lesson
Institutionalize the failure class, not the fix. The invariant that exposed the
prototype's collapse is the same one that certified the rewrite — and the same
one holding the door on what is still wrong.
