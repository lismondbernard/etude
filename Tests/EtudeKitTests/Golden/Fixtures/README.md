# Golden MIDI fixtures

Byte-for-byte reference output for the corpus acceptance/golden tests (PLAN.md §4.5).

**Provenance (Phase 0):** these seven `.mid` files are the *Python prototype's* output,
copied from `../../../../music/` (the prototype working folder). They are the initial
golden baseline per PLAN.md §5: "if the original prototype files are provided, use them;
if not, the first byte-stable output of the finished pipeline becomes the golden baseline."

**Provenance (Phase 3 re-baseline):** the six non-Clair fixtures are now the **Swift
writer's** first byte-stable output (`SMFWriter`, Type 1, 480 tpq, one tempo/meta track
plus one named track per voice, full-duration note-offs, no running status). They were
re-baselined in the commit that added `EmitCorpusGoldensTests` — see `git log` for the
hash. The diff against the prototype fixtures was **reviewed, not auto-overwritten**;
every piece was compared to the prototype MIDI at pitch level first:

- **Minuet, Winter, Prelude** — pitch/tick-identical to the prototype.
- **Air** — identical except two guitar notes: partial chord-to-note ties
  (`< fis a >8 ~ a`) sustain here as LilyPond does; the prototype re-attacked.
- **Gymnopédie** — bass ending octaves corrected (the prototype clamped
  sub-audible drift, BUG-004); first-ending chords sit an octave lower because
  pitched rests thread relative context here, per LilyPond.
- **Gnossienne** — grace notes steal their written value (prototype compressed
  to a 32nd), and the hidden ossia voice sounds (hideNotes is engraving-only),
  adding 14 accompaniment notes.

**Provenance (Phase 4):** `clair-de-lune.mid` is now also the Swift writer's output —
the boss fight's KNOWN-ISSUE rendering: all four voices align at 72 bars of 9/8 (which
the prototype never achieved), but lhDown carries sub-piano register drift in bars
8–13/22–24/63–65 (issue #1). The golden pins that rendering so any change to it is a
loud, reviewed event, per ADR-0003.

**Provenance (Phase 6 re-baseline):** all seven fixtures are now
**`RunningStatusSMFWriter`** output — the §0.5 swap. The *events* are unchanged
(the shared `SMFWriterSpecs` contract and the round-trip property proved both
writers restore identical events before the naive writer was deleted); only the
*encoding* differs: note-offs are velocity-0 note-ons and repeated status bytes
are omitted, so the files are smaller. Re-baselined in the same commit that
deleted the naive writer.

| Fixture | Piece | Prototype BPM |
|---|---|---|
| `minuet-in-g.mid` | Petzold Minuet in G (BWV Anh. 114), full AABB | 126 |
| `prelude-in-c.mid` | Bach Prelude in C (BWV 846) | 72 |
| `air-on-the-g-string.mid` | Bach Air on the G String (BWV 1068), flute+guitar | 66 |
| `winter-largo.mid` | Vivaldi Largo from "Winter" (RV 297) | 52 |
| `gymnopedie-1.mid` | Satie Gymnopédie No. 1 | 66 |
| `gnossienne-1.mid` | Satie Gnossienne No. 1 | 72 |
| `clair-de-lune.mid` | Debussy Clair de Lune — **boss fight, known issue #1** | 60 |
