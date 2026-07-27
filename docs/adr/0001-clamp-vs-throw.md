# ADR 0001 — Validators throw; they do not clamp

**Status:** Accepted (Phase 0)

## Context
The Python prototype defended against bad pitches by *clamping* out-of-range values into
a plausible register. In the Gymnopédie ending, `<<…>>` octave references drifted and
produced a sub-audible octave-0 bass. Because the code clamped, the output "sounded
roughly fine" and the real resolver bug (**BUG-004**) stayed hidden until noticed by ear.

## Decision
The Validator (PLAN.md §4.4) treats invariant violations as **errors to surface**, not
conditions to silently repair. It **throws structured findings** (findings-as-data) and
never mutates events to make them legal. Register sanity, voice alignment, bar arithmetic,
and opening-phrase fingerprints are all loud failures.

## Consequences
- Bugs that clamping would mask become red tests instead (BUG-004 is now guarded).
- The app's Diagnostics screen can render the findings list directly — honesty in the UI
  mirrors honesty in the tests.
- Callers must handle thrown errors; there is no "just make it work" fallback path.
- Related: ADR-0003 (known issues are visible, not disabled).
