# CLAUDE.md

Guidance for Claude Code when working under `etude/` or `music/`. The workspace-level `../CLAUDE.md` covers builds, Linear, and cross-cutting conventions; `PLAN.md` here is the project plan.

## Étude and its prototype

`etude/` is the canonical, actively developed project; `music/` is the **Python prototype / prior art** that proved the score-to-MIDI pipeline on six pieces before the Swift rewrite.

- Treat `music/` as **read-only reference**, not code to port verbatim. It holds the prototype's `lily2.py` parser, per-piece build scripts, generated public-domain MIDI, and the two standalone Clair de Lune `.ly` sources.
- `etude/` vendored what it needed at Phase 0: the seven `.mid` files became golden-test fixtures (to be re-baselined against the Swift writer, since byte output will differ), and `clair-de-lune.ly` became the one real corpus source. The other pieces' LilyPond lives only as embedded strings inside the prototype's Python scripts.
- The prototype's real bugs are catalogued in `etude/PLAN.md` §6 and become named Swift regression tests — they are pedagogical, so don't discard them.
- New work goes in `etude/`; reach into `music/` only to recover a source fragment or check what the prototype actually did.
