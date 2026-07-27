# ADR 0003 — Clair de Lune is a known issue, not a disabled test

**Status:** Accepted (Phase 0)

## Context
Debussy's Clair de Lune (`\parallelMusic`, two voices per staff, cross-staff writing,
nested tuplets) defeated the prototype's timing of dense polyphony (**BUG-006**). We could
disable/skip its acceptance test to keep the suite green. That would hide a real,
still-open limitation and quietly risk shipping a subtly wrong rendering.

## Decision
Clair de Lune runs the **full pipeline** inside Swift Testing's
`withKnownIssue("parallelMusic + dense polyphony — see issue #1")`. The test executes and
its failure is *recorded and expected*, not skipped. GitHub issue #1 documents exactly
where it breaks and invites contributors. Project policy (stated in the README):
**never ship a subtly wrong version — a correct excerpt beats an incorrect whole.**

## Consequences
- The suite is green with **exactly one** known issue; if Clair de Lune ever starts
  passing, `withKnownIssue` flags the unexpected pass so we notice the fix.
- The voice-alignment invariant (ADR-0001) stays active, so this failure is always loud.
- The app's Diagnostics screen intentionally shows Clair de Lune's alignment findings.
