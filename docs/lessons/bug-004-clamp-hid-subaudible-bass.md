# Lesson: BUG-004 — Sub-audible octave-0 bass; clamping hid it

## Symptom
The Gymnopédie's bass ending drifted toward octave 0 — and nobody knew, because
`clamp(ev, lo=36)` silently lifted every out-of-range pitch back into audibility.
The output "sounded roughly fine" while the resolver bug lived on.

## Root cause
Defensive repair where an invariant belonged. The prototype's octave-mark errors
(copied from a hand-cleaned source) produced E0/D0; the clamp made them E2/D2 and
erased the evidence.

## The guard now in place
ADR-0001: the Validator THROWS structured findings — register sanity is a rule,
not a repair. `BUG004_ClampedSubAudibleBass` proves the reconstructed ending
figure resolves in register and that drift throws instead of clamping. The rule
promptly caught two real defects Phase 3–4: the vendored Gymnopédie bass marks,
and Clair de Lune's lhDown drift (issue #1).

## Lesson
Invariants beat defensive code. A clamp turns a loud bug into a quiet one; a
validator turns a quiet bug into a red test.
