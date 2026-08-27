# HISTORY

How this codebase got the way it is, read from its own git log. `CLAUDE.md`-style
docs describe what the code *is*; this is the counterpart: what happened, in order,
with the commit hashes so you can `git show` any of it. The history itself is a
deliverable of the project (PLAN.md §0.1) — commit subjects name behaviors, one
behavior per commit, and the log is meant to read as the course's narrative spine.

Generated at the close of Phase 6 (139 commits at generation, `6c6b6bd`), just
before the v0.1.0 tag. Findings about the history's own defects are at the
end — recorded, not repaired.

## Timeline

| Era | Dates | What happened | Marker commits |
|---|---|---|---|
| Phase 0 — scaffold | 2026-07-27 | Engine package, app shell, corpus stubs, docs, CI, prototype goldens vendored | `9abd75d` |
| Interlude | 2026-08-12 → 08-14 | Provenance notes; PLAN.md rewritten in the project's own voice; AI-assist disclosure | `9bd86d0`, `9f87d5c`, `06982a7` |
| Phase 1 — Tokenizer | 2026-08-14 | 27 behavior commits, empty input → fuzz smoke; both Satie sources tokenize end-to-end | `4ca3e3b` … `3fbcf14` |
| Phase 2 — Parser + Resolver | 2026-08-25 | LilyPond-shaped tree, then resolution to ticks and MIDI pitches; Satie acceptance | `978f8d2` … `93c25df` |
| Phase 3 — Score, Validator, MIDI, corpus | 2026-08-25 | Domain model, findings-as-data validator, SMF writer/reader, four sources vendored, goldens re-baselined | `8b64b2c` … `f06eb5f` |
| Phase 4 — the boss fight | 2026-08-25 | `\parallelMusic`, multipliers, value-captured definitions; Clair de Lune aligns; issue #1 recorded | `dff33e4` … `c5e55b0` |
| Phase 5 — App MVP | 2026-08-26 | Catalog, seams, view models against spies, page-object UI flows; a UI test catches a real bug | `255bcd1` … `d9ea28c` |
| Phase 6 — polish + capstone | 2026-08-26 | The writer swap (§0.5), credits screen, icon, course map, this file, v0.1.0 | `92285d0` … tag `v0.1.0` |

## Architecture evolution

**The layering was decided before the code existed.** The Phase 0 scaffold
(`9abd75d`) already carried the shape the finished engine has: a pure SwiftPM
package (`Sources/EtudeKit/` with Tokenizer → Parser → Resolver → Model → MIDI
directories), a test tree split by kind (`Unit · Property · Regression · Golden ·
Acceptance`), a corpus directory, ADRs, and an XcodeGen-generated app shell that
imports the engine and nothing else. Nothing later moved a top-level directory;
the history is the layers being *filled in*, strictly bottom-up.

**Phase 1 filled the Tokenizer** one lexical behavior at a time — from
"delivers no tokens for empty input" (`4ca3e3b`) through typed errors with
locations (`6cf9ed4`…) to a seeded fuzz smoke (`8c0ff8d`). Two of the
prototype's six catalogued bugs became guards here before any parsing existed:
chords are tokenized structurally, never split on whitespace (BUG-001,
`09d0891`), and a parallel marker glued to a pitch stays two tokens (BUG-005,
`c3e6a00`).

**Phase 2 added the two-model discipline** the PLAN calls load-bearing: the
parse tree stays LilyPond-shaped (relative pitches, unexpanded repeats) and
never travels past the Resolver. Parsing lands first (`978f8d2`…`1082a7b`,
ending with the parse tree snapshotted as reviewable JSON), then resolution:
sticky durations (`957765d`), relative octaves within a fourth (`6d7518f`),
the chord first-note rule (`b467958`), tie merging (`7719839`),
repeats-resolve-once (BUG-002, `3019edf`), grace time-stealing (`6f0f1d3`),
tuplets, parallel groups, references. Two property tests state the resolver's
laws (`352bdc7`, `b65e94c`).

**Phase 3 introduced the domain model and the honesty policy.** `Score` —
voices, ticks, a musician's vocabulary, zero LilyPond concepts — arrives in
`8b64b2c`. The Validator arrives as findings-as-data, and its second commit is
the policy in one subject: "Validator reports register artifacts instead of
clamping them" (`7f5112a`) — the direct repudiation of the prototype's silent
clamp (BUG-004, guarded in `dec3968`). The SMF writer lands deliberately naive
(explicit status on every event, `dfcb10b`), the reader accepts running status
from day one (`1354fae`), and the round-trip property binds them (`9ae5548`).
Four sources are vendored and pitch-verified, a hidden defect in the vendored
Gymnopédie is *corrected at the source* with provenance notes (`8b7f2aa`), and
the goldens are re-baselined from the prototype's bytes to the Swift writer's
(`7fd5102`) — reviewed, not auto-overwritten.

**Phase 4 is the boss fight** — everything Clair de Lune needed that nothing
else did: scheme arguments (`dff33e4`), duration multipliers (`18a3cc6`),
definitions capturing definitions by value (`c29424d`), `\parallelMusic`
dealing bars round-robin (`54aa6d0`). A wrong anchor in the vendored source is
corrected with the hand-expanded file as witness (`4b5ee2c`), and `43008cd`
lands the piece whole: four voices aligned at 72 bars of 9/8 — solving the
alignment failure that defeated the prototype — with the residual register
drift recorded as **known issue #1** under `withKnownIssue`, per ADR-0003. The
six-bug catalog becomes `docs/lessons/` (`3ae16c9`).

**Phase 5 built the app against seams, not the engine.** The corpus becomes
engine metadata (`255bcd1`), `PieceBuilding` opens the async seam over the
whole pipeline (`ddf94af`), and the view models are tested against spies with
leak tracking before any pixel exists (`5bf5a69`…`9dbb6dc`). The page-object
UI flows (`11968c0`) immediately earned their keep: the Play button never
flipped to Pause because playback state was computed through a non-observable
protocol — fixed by `c420833`, "Playback state is stored where Observation can
see it". A UI test catching a real bug on arrival is the argument for the slow
lane.

**Phase 6 executed the planned replacement.** See the next section.

## Major migrations

### The golden re-baselines (twice, both loud)

The golden `.mid` fixtures changed provenance twice, each time in a reviewed
commit with the reasoning in `Fixtures/README.md`:

1. **Prototype → Swift writer** (`7fd5102`, Phase 3): every piece first compared
   to the prototype MIDI at pitch level; the deliberate divergences (tie
   sustains in the Air, the un-clamped Gymnopédie bass, grace values in the
   Gnossienne) are itemized there.
2. **Naive writer → running status** (`8638b41`, Phase 6): identical events,
   ~23% smaller encoding.

### The writer swap (§0.5, the capstone)

Staged across four commits on 2026-08-26, exactly as PLAN.md §0.5 scripted it
a month earlier:

- `92285d0` — `SMFWriterSpecs`: one reusable behavioral contract for anything
  behind the `SMFWriting` seam, asserting through the reader and structural
  scans, never exact bytes.
- `26bed04` — a second writer omits repeated status bytes, proven against the
  same specs and the round-trip property alongside the original.
- `a53e35b` — note-offs ride the note-on status at velocity zero.
- `8638b41` — **the naive writer is deleted in a single commit.** Only
  composition points moved; goldens re-baselined in the same commit.

The seed was planted in Phase 3: `dfcb10b` skipped running status *on purpose*
and said so in its header comment, and the reader was built to accept running
status it would not yet see (`1354fae`).

## Removed subsystems

- **The naive `SMFWriter`** (`dfcb10b` → deleted in `8638b41`) — the explicit
  status writer that existed to be replaced; its byte-level tests and spec
  conformance went with it.
- **The Phase 0 app empty state** — the scaffold's placeholder UI, superseded
  by the real library in Phase 5 (`11968c0`).
- Nothing else substantial has been deleted; the architecture has only accreted
  along the lines the scaffold drew.

## Cadence and contributors

Single author throughout (139 commits). The shape is bursts, not a steady
drip: the scaffold on 2026-07-27, Phase 1's 27 commits in one day (08-14),
then a striking 08-25 in which Phases 2, 3, and 4 — some 70 behavior commits
— all land, and Phases 5–6 close on 08-26. The dates record when work was
*committed*, not necessarily when it was thought through: PLAN.md §6's bug
catalog and the phase acceptance criteria predate the bursts, which is much of
why the bursts read as executions rather than explorations.

## Findings about the history itself

Recorded per §0.1 — a gap in the narrative is a retrospective finding, not
something to rewrite away:

- **Three duplicated subjects** sit adjacent in the log: `820771c` repeats
  `81d2865` ("Writes the Type 1 header and tempo track"), `b4cbac8` repeats
  `6a4beec` ("Skips argumented engraving commands…"), and `3f2c108` repeats
  `7c678d6` ("Assembles named voices…"). Each pair is a red commit followed by
  its green twin that should have been one commit or a fixup; three other
  instances of the same mistake *were* squashed before landing, these slipped
  through. The lesson stands: a piped `swift test | tail` masks the test
  run's exit code, and history discipline needs tooling, not vigilance.
- **Phase 0's scaffold is one commit.** The month between `9abd75d` and Phase 1
  is invisible — corpus decisions, license research, and PLAN.md drafting
  happened off-log and only surface in the 08-12/08-14 documentation commits.
- **The tags start at the end.** `v0.1.0` is the first tag; earlier phase
  boundaries are only findable through the `PLAN: mark Phase N done` commits.
