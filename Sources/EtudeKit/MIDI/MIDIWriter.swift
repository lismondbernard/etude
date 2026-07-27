// MIDI writer (+ minimal reader) — `Score` → `[UInt8]`   (implemented in Phase 3)
//
// Standard MIDI File Type 1: `MThd` (format 1, ntrks, division e.g. 480 tpq), one
// tempo/meta track + one `MTrk` per voice, every track ending with End-of-Track.
// Running status is deliberately NOT used (keep the emitter simple and legible; the
// comment in the implementation says why). A minimal SMF reader parses bytes back to
// events for round-trip tests.
//
// Tests (Phase 3):
//   - golden-file byte comparison against the known-good `.mid` fixtures
//   - round-trip property: write→read == identity on events
//   - structural smoke checks: header magic, track terminators, clean EOF

// Intentionally empty in Phase 0.
