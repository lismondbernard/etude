# Golden MIDI fixtures

Byte-for-byte reference output for the corpus acceptance/golden tests (PLAN.md §4.5).

**Provenance (Phase 0):** these seven `.mid` files are the *Python prototype's* output,
copied from `../../../../music/` (the prototype working folder). They are the initial
golden baseline per PLAN.md §5: "if the original prototype files are provided, use them;
if not, the first byte-stable output of the finished pipeline becomes the golden baseline."

**Important:** the Swift pipeline does not exist yet. When Phase 3 emits its first
byte-stable output, each fixture must be **re-baselined** against the Swift writer (the
Swift SMF encoding — division, meta ordering, EOT placement — will not necessarily match
the prototype byte-for-byte). When re-baselining, record the commit hash in a sidecar note
per fixture, and treat any diff as a review item, not an automatic overwrite.

| Fixture | Piece | Prototype BPM |
|---|---|---|
| `minuet-in-g.mid` | Petzold Minuet in G (BWV Anh. 114), full AABB | 126 |
| `prelude-in-c.mid` | Bach Prelude in C (BWV 846) | 72 |
| `air-on-the-g-string.mid` | Bach Air on the G String (BWV 1068), flute+guitar | 66 |
| `winter-largo.mid` | Vivaldi Largo from "Winter" (RV 297) | 52 |
| `gymnopedie-1.mid` | Satie Gymnopédie No. 1 | 66 |
| `gnossienne-1.mid` | Satie Gnossienne No. 1 | 72 |
| `clair-de-lune.mid` | Debussy Clair de Lune — **boss fight, known issue #1** | 60 |
