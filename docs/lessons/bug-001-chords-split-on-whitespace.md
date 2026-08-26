# Lesson: BUG-001 — Chord tokens split on whitespace

## Symptom
`<c e g>` came out of the prototype's tokenizer as garbage — the chord was cut at
its inner spaces and the fragments (`<c`, `e`, `g>`) were misread or dropped, so
chords lost notes or corrupted whatever followed.

## Root cause
The prototype tokenized by `text.split()` first and repaired chords afterwards by
gluing tokens back together until a `>` appeared. Structure was an afterthought
bolted onto whitespace.

## The guard now in place
`TokenizeChordsTests` and the Phase 1 tokenizer, which reads `<…>` structurally:
a chord opens, its pitches are scanned in place, and it closes with its written
duration — whitespace never participates. `BUG001_ChordTokensSplitOnWhitespace`
pins chords carrying every duration and ornament suffix.

## Lesson
Tokenize structurally, never by whitespace. If a construct can contain the
delimiter you split on, splitting was the wrong first move.
