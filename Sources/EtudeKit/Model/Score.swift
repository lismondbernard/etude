// Model + Validator — `Score` value types, invariants as first-class code
// (implemented in Phase 3)
//
// Planned value types:
//   Score { title, tempo, timeSignature, voices: [Voice] }
//   Voice { name, events: [NoteEvent] }
//   NoteEvent { pitch: MIDINote(UInt8 0…127), startTick, durationTicks, velocity }
//
// The Validator runs invariants (each independently unit-tested) and THROWS
// structured findings rather than clamping (ADR-0001 — clamping hid BUG-004):
//   1. Voice alignment — simultaneous voices sum to equal tick length per section
//      (this is the check that exposes Clair de Lune's 91/46/57/54-beat mismatch).
//   2. Register sanity — per-track min/max pitch in a plausible range; octave-0/8
//      artifacts are parser bugs, not music (BUG-004/006).
//   3. Opening-phrase fingerprint — corpus pieces carry expected first-notes.
//   4. Bar arithmetic — events in each bar sum to the time signature.

// Intentionally empty in Phase 0.
