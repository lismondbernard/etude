# ADR 0002 — The score model is value types in a UI-free package

**Status:** Accepted (Phase 0)

## Context
Étude is both a shipping app and a testing curriculum. Test speed and determinism are
features. Reference-type graphs with shared mutable state are hard to test and invite
aliasing bugs across the tokenize→parse→resolve→emit pipeline.

## Decision
`Score`, `Voice`, and `NoteEvent` are **value types** (`struct`/`enum`) living in
`EtudeKit`, a pure SPM package with **zero UIKit/SwiftUI imports**. The SwiftUI app is a
thin shell over it. Making the model `Codable` also enables snapshot testing of the event
tree.

## Consequences
- `swift test` runs the whole engine fast, on any platform, with no simulator.
- Property-based laws (resolve/transpose commutation, unfold-copies, octave inverses) are
  clean to state over immutable values.
- The two-target split (`EtudeKit` vs `App/Etude`) is itself Lesson 1 in testability.
- Value semantics cost some copying; irrelevant at this data scale.
