# Corpus provenance & licensing

All **compositions** in this corpus are in the **public domain**. What follows concerns
the vendored **typesettings** (the `.ly` files), which carry their own licenses, and the
provenance of each piece as it came through the Python prototype (see `../../music/`).

The **emitted MIDI** of public-domain notes carries no composition or recording copyright
and is free for commercial app/game use. Typesetting licenses attach to the `.ly` text
only.

| Piece | Corpus file | `.ly` status | Typesetting license | Notes |
|---|---|---|---|---|
| Clair de Lune | `clair-de-lune.ly` (+ `.expanded.ly`) | **real, vendored** | Mutopia — public domain (verify header) | Boss fight, issue #1. `\parallelMusic`, cross-staff, nested tuplets. |
| Minuet in G | `minuet-in-g.ly` | stub | Mutopia — public domain | Full AABB, from prototype `minuet_full.py`. |
| Prelude in C | `prelude-in-c.ly` | stub | n/a — see note | Prototype exported from **music21 corpus**, not a Mutopia `.ly`. Decide: typeset a simple `.ly`, or keep golden-MIDI-only. |
| Air on the G String | `air-on-the-g-string.ly` | stub | Mutopia — public domain | Flute + guitar-upper only; bass omitted (edition repeat mismatch). |
| Gymnopédie No. 1 | `gymnopedie-1.ly` | stub | Mutopia — public domain | Watch BUG-004 ending register. |
| Gnossienne No. 1 | `gnossienne-1.ly` | stub | Mutopia — public domain | English note names; `q` chord-repeat. |
| Winter — Largo | `winter-largo/` | stub (multi-part) | **CC-BY-SA** | Attribution required to redistribute the `.ly`. |

## Action items before replacing any stub with a real `.ly`
1. Open the Mutopia source, confirm its header license, and record it in the row above.
2. For **Winter**, add the CC-BY-SA attribution string (typesetter + source URL) here.
3. For **Prelude in C**, record the final decision (typeset `.ly` vs golden-MIDI-only).
4. Verify each piece's opening-melody fingerprint against PLAN.md Appendix B.

## Prototype provenance
The initial golden `.mid` fixtures under
`../Tests/EtudeKitTests/Golden/Fixtures/` are the Python prototype's output. The prototype
source (build scripts + the `lily2.py` parser) lives in `../../music/` and is prior art —
context, not code to port verbatim (PLAN.md §1).
