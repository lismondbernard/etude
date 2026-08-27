# Corpus provenance & licensing

All **compositions** in this corpus are in the **public domain**. What follows concerns
the vendored **typesettings** (the `.ly` files), which carry their own licenses, and the
provenance of each piece as it came through the Python prototype (see `../../music/`).

The **emitted MIDI** of public-domain notes carries no composition or recording copyright
and is free for commercial app/game use. Typesetting licenses attach to the `.ly` text
only.

| Piece | Corpus file | `.ly` status | Typesetting license | Notes |
|---|---|---|---|---|
| Clair de Lune | `clair-de-lune.ly` (+ `.expanded.ly`) | **real, vendored** | Mutopia — **public domain, verified** (typeset by Keith O'Hara, source E. Fromont 1905, Mutopia-2010/12/21-1778; header confirms "placed in the public domain by the typesetter") | Boss fight — issue #1 CLOSED against the recovered original: the §1 `lhDown` anchor is the original's `c'` (a prototype-era "correction" to `c,` was the source half of the drift). `\parallelMusic`, cross-staff, nested tuplets. |
| Minuet in G | `minuet-in-g.ly` | **reconstructed** | Étude typesetting (Apache-2.0); note text via prototype from Allen Garvin's Mutopia edition — **public domain, verified** (header license "Public Domain", "placed in the public domain by the typesetter"; source Bach-Gesellschaft; Mutopia-2017/01/19-75) | Full AABB, voices verbatim from `minuet_full.py`. Pitch-verified against the prototype MIDI, and against Garvin's own rendering during issue #1 (which corrected two notes). |
| Prelude in C | `prelude-in-c.ly` | **generated** | Étude typesetting (Apache-2.0) | DECIDED (action item 3): typeset, mechanically, from the prototype's music21-derived MIDI (music21 corpus encodings of PD scores are BSD-licensed; the note content is PD). Verified tick-exact against that MIDI. Closing ritardando dropped. |
| Air on the G String | `air-on-the-g-string.ly` | **reconstructed** | Étude typesetting (Apache-2.0); note text via prototype from Mike Blackstock's Mutopia flute+guitar edition — **public domain, verified** (header: "placed in the public domain by the typesetter"; "New adaptation from Bach-Gesellschaft"; Mutopia-2008/10/28-1534) | Flute + guitar-upper only; bass omitted (edition repeat mismatch). Written in performed form: repeats play once, first ending only. Fingerings stripped. Partial chord ties sustain (2 fewer notes than prototype MIDI — documented in file). |
| Gymnopédie No. 1 | `gymnopedie-1.ly` | **reconstructed** | Étude typesetting (Apache-2.0); note text from Evin Robertson's Mutopia edition — **public domain, verified** (Dover Edition source; header: "placed in the public domain by the typesetter") | Performing text rebuilt from `music/gymnopedie.py` streams; the ending alternatives are Robertson's original text verbatim since issue #2 (BUG-004/BUG-007 territory), pitch-verified against his rendering. |
| Gnossienne No. 1 | `gnossienne-1.ly` | **reconstructed** | **CC-BY-SA 4.0, verified** — note text via prototype from Knute Snortum's Mutopia edition (Mutopia-2015/07/23-2035; source Éditions Salabert 1913; the only Gnossienne No. 1 on Mutopia, English note names matching ours). Share-alike reaches the reconstruction, so `gnossienne-1.ly` itself is CC-BY-SA 4.0, attributed in its header — not Apache-2.0. | English note names; `q` chord-repeat (introduced in reconstruction); BUG-005 fragment preserved verbatim. |
| Winter — Largo | `winter-largo.ly` | **reconstructed** | Note text via prototype from a Mutopia edition its docstring calls **CC-BY-SA** | Single file, five voices verbatim from `winter.py`, tick-verified against the prototype MIDI. Typesetter name was not recorded by the prototype — recover it from Mutopia and add the attribution string here before the repo goes public (action item 2 still open). Trills play plain. |

## Action items before replacing any stub with a real `.ly`
1. Open the Mutopia source, confirm its header license, and record it in the row above.
2. For **Winter**, add the CC-BY-SA attribution string (typesetter + source URL) here.
   **Still open** — the prototype did not record the typesetter's name.
3. ~~For **Prelude in C**, record the final decision~~ **Done (Phase 3):** typeset as
   `prelude-in-c.ly`, generated from the prototype MIDI and verified tick-exact.
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
