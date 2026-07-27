# Lesson: BUG-00N — <one-line title>

> One write-up per regression bug (PLAN.md §6). Copy this file to `bug-00N-slug.md` and
> fill it in when the bug's guard test lands. The matching test is
> `Tests/EtudeKitTests/Regression/BUG00N_*.swift`.

## Symptom
What went wrong, as observed (what the wrong MIDI/score looked or sounded like).

## Root cause
The actual defect, in the tokenizer/parser/resolver/validator/writer.

## The guard now in place
The named regression test that fails without the fix and passes with it — and, where
relevant, the invariant or property law that makes this *class* of failure loud forever.

## Lesson
The generalizable testing principle (e.g. "tokenize structurally, not by whitespace";
"invariants beat defensive clamping"; "resolve repeat bodies once, then copy").
