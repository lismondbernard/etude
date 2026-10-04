# ADR 0007: The piece builds when it opens; Build is not a user step

**Status:** Accepted (Phase 8; announced in issue #7)

## Context
PLAN.md §8 specified the piece screen as "Build button, progress, track list" in the Phase 0 scaffold (`9abd75d`), before the engine existed, and Phase 5 implemented it that way (`9dbb6dc`). The step gave the view model its async state and gave the UI flow an explicit condition to wait on. Measured on 2026-10-03 at `044c0a7`, the whole pipeline takes 0.4 to 2.9 ms per piece in a release build on an Apple Silicon Mac (Clair de Lune, 3,889 tokens, is the slowest). A progress screen for that implies work the user should wait for, which is not true.

## Decision
The piece detail runs the build when the piece appears. The Build and Rebuild buttons are removed. The failed state shows the error and a Try again button. The tempo slider remains the only user-initiated rebuild. The `PieceBuilding` seam, the view model's phases, and the unit tests are unchanged; the UI flows wait on the same condition (Play enabled) without tapping.

## Consequences
- The first screenshot and the first UI flow no longer show a Build step. The store positioning ("builds on device") is carried by a line in the detail naming the source file, not by a gate.
- No artificial delay is added to make the build visible. Faking latency would be the UI version of the clamping ADR-0001 forbids.
- When the corpus becomes dynamic (issue #4) and builds get slower or fallible in new ways, a cache or a visible progress state may be warranted. That is a new decision, not a reversal of this one.
- PLAN.md §8 is corrected rather than left as written; the plan is a hypothesis and the measurement is the evidence, which is the method the rest of the repo applies to code.
