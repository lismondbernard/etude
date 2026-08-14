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
| Gymnopédie No. 1 | `gymnopedie-1.ly` | **reconstructed** | Étude typesetting (Apache-2.0); note text via prototype from a Mutopia edition (PD — verify header) | Not the Mutopia typesetting: performing text rebuilt from `music/gymnopedie.py` streams. Watch BUG-004 ending register. |
| Gnossienne No. 1 | `gnossienne-1.ly` | **reconstructed** | Note text via prototype from a Mutopia edition its docstring calls **CC-BY-SA** — verify header before repo goes public | English note names; `q` chord-repeat; BUG-005 fragment preserved verbatim. If CC-BY-SA is confirmed to reach the reconstruction, attribute typesetter + share-alike this file. |
| Winter — Largo | `winter-largo/` | stub (multi-part) | **CC-BY-SA** | Attribution required to redistribute the `.ly`. |

## Action items before replacing any stub with a real `.ly`
1. Open the Mutopia source, confirm its header license, and record it in the row above.
2. For **Winter**, add the CC-BY-SA attribution string (typesetter + source URL) here.
3. For **Prelude in C**, record the final decision (typeset `.ly` vs golden-MIDI-only).
   Has a downstream consumer — see "Foreign Words marketing assets" below.
4. Verify each piece's opening-melody fingerprint against PLAN.md Appendix B.

## Prototype provenance
The initial golden `.mid` fixtures under
`../Tests/EtudeKitTests/Golden/Fixtures/` are the Python prototype's output. The prototype
source (build scripts + the `lily2.py` parser) lives in `../../music/` and is prior art —
context, not code to port verbatim (PLAN.md §1).

## Downstream consumer: Foreign Words marketing assets
The prototype's `.mid` output in `../../music/` is also the source material for the
Foreign Words App Store preview and social-media music beds (Linear **SSS-78**). Those
beds are rendered to audio once (GarageBand) and archived, so nothing here is a build
dependency — but two decisions in this file would change what the marketing assets are
derived from:

- **Prelude in C** (action item 3). If we typeset a real `.ly` rather than keeping the
  piece golden-MIDI-only, the emitted MIDI changes source, and the rendered bed should be
  re-rendered to match rather than left as a music21-derived artifact of unknown vintage.
- **Any stub replaced with a real `.ly`** (action item 1). Re-baselining a golden fixture
  against the Swift writer will change that piece's MIDI. Marketing beds derived from the
  old MIDI stay valid — they are finished audio — but they will drift from what this
  corpus emits.

Neither blocks SSS-78. Flagging so the drift is deliberate rather than discovered later.

Note also that the marketing beds are rendered with GarageBand's bundled instruments,
which are proprietary Apple Audio Content, **not** CC0 or public domain. That audio
therefore cannot be relicensed freely and must not be vendored into this repo, which is
an open-source teaching project. Keep it in the Foreign Words repo.
