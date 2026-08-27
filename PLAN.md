# Étude — a LilyPond→MIDI engine and SwiftUI app that teaches testing

**Audience for this document:** students and contributors. This is the build plan
and the course syllabus in one. It is executed phase by phase; each phase has
explicit acceptance criteria, and the test infrastructure is never deferred to
reach features faster — the tests ARE the product as much as the app is. §0
defines the working method that binds every phase — read it before §10.

---

## 0. Method — how this gets built

The discipline below is adapted from the **Essential Developer** curriculum the
author completed years ago. Étude borrows the *method*, not the material — these
rules are reshaped for a parser/emitter engine, and they are project law for
every phase in §10.

### 0.1 The git history is a deliverable

The git history should read as a TDD transcript: nearly every commit a single
red→green→refactor step with a behavior-named subject. Étude commits accordingly:

- **One behavior per commit** during engine phases. Write the failing test, make
  it pass minimally, refactor, commit. Never batch multiple behaviors.
- **Commit subjects name the behavior**, not the file: *"Resolves relative octaves
  within a fourth of the previous note"*, not *"Update Resolver.swift"*.
- **Refactor commits are labeled as refactors** (*"Extract duplicate token-table
  assertions into helper"*) — the history should record the refactoring
  discipline, not just feature delivery.
- **Linear `main`**, no long-lived branches. A student should be able to `git log
  --oneline --reverse` and replay the course.
- Phase 6 produces Étude's own `HISTORY.md` from this history — if the log doesn't
  read as a lesson plan, the commits were wrong.

### 0.2 Behavior-first naming

Test files are named for **use cases/behaviors, not types**:
`TokenizeChordsTests`, `ExpandRepeatsTests`,
`ResolveRelativeOctavesTests` — not `TokenizerTests` grab-bags. Swift Testing
`@Test` display names state the behavior in domain language: *"delivers a typed
error on an unterminated chord"*.

### 0.3 Abstractions before implementations

A concrete implementation appears only after the logic that consumes it is fully
proven against a test double. Étude applies this at its seams:

- Design each seam as a **protocol, from the consumer's side**, often extracted
  from the test double that drove it.
- Étude's seams: **`PieceBuilding`** (app → engine: the view models never see
  pipeline internals), **`SMFWriting`** (score → bytes), **`CorpusProviding`**
  (where pieces come from — bundled today, downloadable someday).
- Concrete adapters land *after* their consumers' tests are green against doubles.

### 0.4 Boundary models stay at boundaries

External-format shapes never travel into the domain — mapping happens at the
seams, and each layer owns its own model. Étude's pipeline applies the rule one
layer at a time:

- The **parse tree is LilyPond-shaped** (relative pitches, unexpanded repeats,
  `\times` fractions) and never travels past the Resolver.
- **`Score` is the domain model** — a musician's vocabulary (voices, bars, ticks),
  zero LilyPond concepts. A future MusicXML front end must require no `Score` change.
- The **MIDI writer owns its event model** (delta times, running status concerns);
  `Score` knows nothing about SMF encoding.
- Mapping code lives at the seams and is tested there. Don't collapse these
  models "for convenience" — the separation is the lesson.

### 0.5 Behavioral spec suites make swaps safe

Before swapping one implementation of a seam for another, write one reusable
behavioral contract both implementations must pass — then delete the old one in
a single commit once the replacement is proven. Étude stages this lesson
deliberately:

- When a seam will ever have two implementations, write a **reusable spec suite**
  first (a protocol listing the required behaviors + shared assertion helpers).
- The planned swap: §4.5's first SMF writer deliberately skips running status.
  Phase 6 introduces `SMFWriterSpecs`, implements a running-status writer, proves
  both against the specs *and* the round-trip property, swaps, and **deletes the
  naive writer in one commit** — the low-risk-replacement lesson, on purpose.

### 0.6 Shared test-helper discipline

Every suite shares the same helper shape — factories, builders, and assertion
helpers that keep test bodies down to their intent:

- **`makeSUT()`** per suite; test bodies stay three lines of intent.
- **Domain sample builders** (`anyNote()`, `gymnopedieOpening()`,
  `chord(_:duration:)`) in `Tests/EtudeKitTests/Helpers/`.
- **Assertion helpers** that speak the domain: `expect(_ score:, toOpenWith:)`,
  `expect(_ writer:, toEmit:)`.
- **Memory-leak tracking** where reference types live: EtudeKit is value types
  (§4.4, ADR-0002), so the engine largely can't leak — but the app's view models
  and the `AVMIDIPlayer` wrapper can. App-layer unit tests use a
  `trackForMemoryLeaks` teardown helper.

### 0.7 Ubiquitous language

The code speaks the language domain experts use. Étude's domain language is the
musician's: Voice, bar, anacrusis, tick, grace note. When a name turns out wrong,
rename it the moment the domain says so, as a dedicated refactor commit.

### 0.8 Focused sweeps, not dribbled changes

Cross-cutting idiom changes in Étude (error-type reshaping, a Swift
language-mode migration) are never scattered across feature commits — each gets
one dedicated, single-purpose sweep with its own commits.

### 0.9 Architecture principles: SOLID and pragmatic MVVM

§0.1–0.8 *are* SOLID, applied rather than recited — teach the mapping explicitly:

- **S**ingle responsibility → the pipeline layering (§4): each stage does one
  transformation; boundary models (§0.4) keep it that way.
- **O**pen/closed → the seams (§0.3): a MusicXML front end or downloadable corpus
  arrives behind `CorpusProviding` without modifying consumers.
- **L**iskov substitution → `SMFWriterSpecs` (§0.5) is LSP made executable: any
  writer passing the behavioral contract is substitutable.
- **I**nterface segregation → three small seams, never one god `Engine` protocol.
- **D**ependency inversion → §0.3 wholesale.

The app layer (§8) follows **MVVM, pragmatically**: a view model exists where
there is presentation logic or async state worth testing — not one per screen by
default.

- **PieceDetail** earns one (async build, player state, tempo) — unit-tested
  against a `PieceBuilding` spy, leak-tracked (§0.6).
- **Library** stays a plain view over the bundled corpus until the corpus becomes
  dynamic; a view model there today is boilerplate.
- **Diagnostics** formats Validator findings — pure functions, more testable than
  a view model would be.
- **No ceremony:** don't protocol-ize view models, don't add coordinator/router
  layers for three screens. SwiftUI's `@Observable` is the binding machinery;
  chase testability, not textbook shape. Knowing when *not* to add a view model
  is part of the curriculum.

---

## 1. What this project is

An open-source iOS app (SwiftUI) + Swift package that:

1. Parses a practical subset of **LilyPond** notation (`.ly` files, the plain-text
   score format used by the Mutopia Project) into an internal score model.
2. Validates the score against musical invariants.
3. Emits standard **Type-1 MIDI** files (one track per voice/hand).
4. Lets the user browse a bundled corpus of public-domain classical pieces, build
   them on-device, play them (`AVMIDIPlayer`), adjust tempo, and export the `.mid`
   via the share sheet (for GarageBand, games, DAWs).

It is simultaneously a **teaching vehicle for software testing architecture**:
unit testing (Swift Testing), property-based testing, golden-file/snapshot testing,
regression testing from real historical bugs, invariant validation, and UI testing
(XCUITest with page objects). It will eventually ship on the App Store with source
publicly available.

### Origin / prior art (context, not code to port verbatim)

A working Python prototype already proved the pipeline on six pieces sourced from
Mutopia/music21: Petzold **Minuet in G** (BWV Anh. 114, full AABB form with real
left hand + ornaments), Bach **Prelude in C** (BWV 846), Bach **Air on the G
String** (BWV 1068, flute+guitar edition), Vivaldi **Largo from "Winter"** (RV 297,
five aligned string parts), Satie **Gymnopédie No. 1**, and Satie **Gnossienne
No. 1**. Debussy **Clair de Lune** defeated the prototype (see §7, the Boss Fight)
and is carried forward as a permanently visible known-issue acceptance test.

The prototype's real bugs are catalogued in §6. Each becomes a named regression
test in Swift. Do not lose them — they are the pedagogical crown jewels.

---

## 2. Repository layout

```
etude/
├── PLAN.md                        # this file
├── LICENSE                        # Apache-2.0 (see §9)
├── README.md
├── CONTRIBUTING.md                # PRs must include tests; explain test taxonomy
├── Package.swift                  # SPM package: EtudeKit (engine, platform-agnostic)
├── Sources/
│   └── EtudeKit/
│       ├── Tokenizer/             # .ly text → [Token]
│       ├── Parser/                # [Token] → raw music events (relative pitches, durations, repeats, tuplets, graces, chords)
│       ├── Resolver/              # relative→absolute octaves, repeat expansion, tie/grace timing
│       ├── Model/                 # Score, Voice, NoteEvent, TimeSignature… (value types) + Validator
│       └── MIDI/                  # Score → [UInt8] Type-1 SMF writer + minimal SMF reader (for round-trips)
├── Tests/
│   └── EtudeKitTests/
│       ├── Helpers/               # makeSUT factories, sample builders, assertion helpers (§0.6)
│       ├── Unit/                  # table-driven tokenizer/parser tests
│       ├── Property/              # generator-based law tests
│       ├── Regression/            # BUG-001…BUG-006, one file each, story in doc comment
│       ├── Golden/                # byte-compare emitted MIDI vs known-good fixtures
│       └── Acceptance/            # full-piece corpus builds; ClairDeLune via withKnownIssue
├── Corpus/                        # vendored Mutopia .ly sources + per-file LICENSE notes
│   ├── minuet-in-g.ly
│   ├── prelude-in-c.ly            # (or note: sourced via music21 export — see §5)
│   ├── air-on-the-g-string.ly
│   ├── winter-largo/              # multi-part: solo, vln1, vln2, viola, cello
│   ├── gymnopedie-1.ly
│   ├── gnossienne-1.ly
│   └── clair-de-lune.ly           # the boss fight
├── App/
│   └── Etude/                     # Xcode project, SwiftUI app target + XCUITest target
│       ├── EtudeApp.swift
│       ├── Features/
│       │   ├── Library/           # piece list (bundled corpus)
│       │   ├── PieceDetail/       # build, play, tempo slider, track list, export
│       │   └── Diagnostics/       # shows validator output — the app UI teaches the invariants too
│       └── EtudeUITests/
│           ├── PageObjects/       # LibraryScreen, PieceDetailScreen…
│           └── Flows/             # browse→build→play→export happy paths + failure surfacing
└── docs/
    ├── adr/                       # Architecture Decision Records (numbered)
    │   ├── 0001-clamp-vs-throw.md         # defensive clamping hid BUG-004; why validators throw instead
    │   ├── 0002-value-types-for-score.md
    │   ├── 0003-known-issue-not-skip.md   # why Clair de Lune is withKnownIssue, not disabled
    │   └── 0004-license-choice.md
    └── lessons/                   # one write-up per bug: symptom → root cause → the test that now guards it
```

**Two-target philosophy:** `EtudeKit` is a pure SPM package with **zero** UIKit/
SwiftUI imports — fully testable on any platform, fast unit tests, no simulator
needed. The app is a thin SwiftUI shell over it. This separation is itself Lesson 1
in designing for testability.

---

## 3. Toolchain and testing stack

- **Swift 6 / Xcode 16+**, iOS 17+ deployment target.
- **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`) for all
  EtudeKit tests. Use **parameterized tests** for token/parse tables, **tags**
  (`.regression`, `.golden`, `.property`, `.acceptance`) for suite slicing, and
  **`withKnownIssue`** for Clair de Lune.
- **XCTest/XCUITest** for the UI test target (UI testing is XCTest-only). Use
  accessibility identifiers on every interactive element; **Page Object pattern**
  in `PageObjects/`.
- **Property-based tests:** hand-roll small generators (seeded
  `RandomNumberGenerator`, shrink by halving) inside Swift Testing rather than
  taking a dependency — building a 60-line generator is itself a lesson. Document
  this choice in an ADR.
- **Golden files:** known-good `.mid` fixtures live in test resources
  (`Bundle.module`). Compare bytes; on mismatch, print a structured event-level
  diff (decode both with the SMF reader) so failures are diagnosable, not just red.
- **Shared helpers** (per §0.6): `makeSUT()` factories, domain sample builders,
  and assertion helpers live in `Tests/EtudeKitTests/Helpers/`; app-layer tests
  add a `trackForMemoryLeaks` teardown helper.
- **CI:** GitHub Actions, `macos-15` runner: `swift test` for EtudeKit (fast lane)
  and `xcodebuild test` for app + UI tests (slow lane, can be nightly). The lane
  split is a lesson in target design: the engine tests run on
  macOS with no simulator *because* EtudeKit has zero UI imports — testability is
  an architecture property, not a tooling trick.

---

## 4. The engine, layer by layer (with its testing lesson)

### 4.1 Tokenizer — `.ly` text → `[Token]`
Handles: note names (Dutch default `c d e f g a b` + `is`/`es`; **English mode**
`\language "english"` with `cs`/`df` style used by the Gnossienne source), octave
marks `'`/`,`, durations (`1 2 4 8 16` + dots), chords `<c e g>`, chord-repeat `q`,
rests `r`/`s`, ties `~`, braces, `<< … >>` parallel markers, commands
(`\relative`, `\repeat`, `\times`/`\tuplet`, `\grace`, `\acciaccatura`, `\key`,
`\time`, `\tempo`, `\crossStaff`, `\ottava`), comments `%`, strings.
**Critical:** chords contain spaces — tokenize structurally, never by whitespace
split (BUG-001).
*Lessons:* table-driven parameterized tests; regression tests; fuzz with random
byte strings — tokenizer must never crash, only throw typed errors.

### 4.2 Parser — `[Token]` → raw event tree
Produces a tree of notes/chords/rests with **relative** pitch context still
unresolved; captures repeat blocks, tuplet groupings (`\times 2/3 { … }` scales
durations), grace groups (steal time from the following note; acciaccatura ≈ very
short), and parallel `<<…>>` groups. `\crossStaff { … }` braces are grouping
no-ops, **not** parallel separators (BUG-003).
*Lessons:* recursive-descent structure; typed `ParseError` with source location;
snapshot tests of the event tree (Codable → JSON, compare to fixture).

### 4.3 Resolver — event tree → absolute timed events
- `\relative` octave resolution: each note is placed within a fourth of the
  previous note, then `'`/`,` adjust. Chords: the **first chord note** relates to
  the previous context; subsequent chord notes relate within the chord; context
  after the chord continues from the first note (LilyPond semantics).
- `\repeat volta/unfold n { … }`: resolve the body **once**, then copy the
  resolved events — never re-thread the relative context through repetitions
  (BUG-002).
- Per-section `\relative` anchors: a multi-section piece re-anchors at each
  section head (the Gnossienne and Clair sources use this pattern).
*Lessons:* property-based laws —
  (a) resolve∘transpose == transpose∘resolve on pitch classes;
  (b) `unfold n` yields exactly n× the events of the body, pairwise identical;
  (c) octave marks are inverses: `'` then `,` restores pitch.

### 4.4 Model + Validator — `Score` value types, invariants as first-class code
`Score { title, tempo, timeSignature, voices: [Voice] }`,
`Voice { name, events: [NoteEvent] }`,
`NoteEvent { pitch: MIDINote(UInt8 0…127), startTick, durationTicks, velocity }`.
The **Validator** runs these invariants (each an independently unit-tested rule)
and throws structured findings rather than clamping (ADR-0001):
1. **Voice alignment** — all simultaneous voices in each section sum to equal
   tick length (this is exactly the check that exposed Clair de Lune's
   91 vs 46 vs 57 vs 54-beat mismatch).
2. **Register sanity** — per-track min/max pitch within a plausible instrument
   range; octave-0 or octave-8 artifacts are parser bugs, not music (BUG-004/006).
3. **Opening-phrase fingerprint** — corpus pieces carry expected first-notes
   metadata (e.g. Gnossienne melody opens C–E♭–D–C–B; Gymnopédie opens
   F♯5–A5–G5–F♯5) asserted in acceptance tests.
4. **Bar arithmetic** — events in each bar sum to the time signature.
*Lessons:* invariants > defensive code; validators turn silent wrongness into loud
failure; designing errors as data (findings list) not just throws.

### 4.5 MIDI writer (+ minimal reader) — `Score` → `[UInt8]`
Standard MIDI File Type 1: `MThd` (format 1, ntrks, division e.g. 480 tpq), one
tempo/meta track + one `MTrk` per voice, running status **deliberately omitted**
in the first writer (say why in a comment — it is the seed of the §0.5 swap
lesson), every track ends with End-of-Track. The writer sits behind the
`SMFWriting` seam (§0.3). A minimal reader parses SMF back to events for
round-trip tests.
*Lessons:* golden-file byte comparison against the six known-good fixtures;
round-trip property (write→read == identity on events); structural checks (header
magic, track terminators, EOF) as cheap smoke tests. In Phase 6, `SMFWriterSpecs`
+ a running-status writer replay the safe-replacement lesson (§0.5).

### 4.6 Corpus acceptance suite
For each corpus piece: parse → resolve → validate → emit → assert the structural
fingerprint (bar count, voice count, opening pitches, total duration within
tolerance, byte-equality to golden fixture). Clair de Lune runs the same pipeline
inside `withKnownIssue("parallelMusic + dense polyphony — see issue #1")`.
*Lessons:* the test pyramid made concrete; fixtures you don't control; honest
failure as a feature.

---

## 5. Corpus notes (licensing + provenance)

All **compositions** are public domain. The vendored **typesettings**:
- Mutopia sources for Minuet in G, Air, Gymnopédie 1, Gnossienne 1, Clair de Lune:
  public domain (verify each file's header and record it in `Corpus/LICENSES.md`).
- Vivaldi Winter typesetting is **CC-BY-SA** — fine to vendor with attribution;
  note that redistribution of the `.ly` itself carries that license (the emitted
  MIDI of public-domain notes does not).
- Bach Prelude in C: the prototype exported it from the music21 corpus rather than
  a Mutopia `.ly`. Either find/typeset a simple `.ly` for it or keep it as a
  golden-MIDI-only piece initially; note the decision in `Corpus/LICENSES.md`.
- Air on the G String: this edition's separate bass part has a known 1-bar repeat
  mismatch vs the melody — use flute melody + guitar-upper accompaniment only
  (document this quirk; it's a nice "real data is messy" teaching moment).

Golden `.mid` fixtures: if the original prototype files are provided, use them; if
not, the first byte-stable output of the finished pipeline becomes the golden
baseline (record the commit hash in each fixture's sidecar note).

---

## 6. The regression catalog (build one named test per bug)

Each gets `Tests/EtudeKitTests/Regression/BUG00N_*.swift` with the story in a doc
comment: symptom → root cause → the guard now in place.

- **BUG-001 — Chord tokens split on whitespace.** `<c e g>` was whitespace-split
  into garbage. Guard: tokenizer treats `<…>` structurally; test includes chords
  with every duration/ornament suffix.
- **BUG-002 — Relative octave threaded through `\repeat unfold`.** Bass spiraled
  F2→F1→F0 across repetitions. Guard: resolve body once, copy events; property
  test (unfold ×n == n identical copies).
- **BUG-003 — `\crossStaff { }` braces treated as parallel separators.** Grouping
  braces outside `<<…>>` corrupted voice structure. Guard: brace semantics are
  context-dependent; targeted parser tests.
- **BUG-004 — Sub-audible octave-0 bass in Gymnopédie ending.** `<<…>>` octave
  references drifted; prototype **clamped** the register, which hid the real bug.
  Guard: Validator *throws* on register violations (ADR-0001); resolver test on
  the exact ending figure.
- **BUG-005 — Polyphony wrapper glued to a pitch broke chord parsing**
  (Gnossienne: `<<` adjacent to a note token). Guard: tokenizer separates
  structural markers from pitch tokens; test the exact source fragment.
- **BUG-006 — Voice-length mismatch only caught at validation** (Clair de Lune,
  91/46/57/54 beats in section 1). Not fixed — *institutionalized*: the alignment
  invariant exists so this class of failure is always loud. The acceptance test
  documents it via `withKnownIssue`.

---

## 7. The Boss Fight — Clair de Lune (issue #1: CLOSED)

Debussy's score (Mutopia `.ly`) combines `\parallelMusic` (round-robin bar
distribution across voices), two independent voices per staff, cross-staff
writing, nested tuplets, and irregular spacing. The prototype correctly expanded
`\parallelMusic` to 72 bars/voice but could not time the dense polyphony (its
section 1 came out 91/46/57/54 beats across the four voices). **Phase 4 status:
the timing is SOLVED** — the Swift engine aligns all four voices at 72 bars of
9/8, section by section, and the compact and expanded sources resolve
identically. The residue — lhDown register drift below the piano's floor in
bars 8–13/22–24/63–65, recorded as issue #1 — shipped visible in v0.1.0 and
was then closed by executing its own fix path: recovering the original Mutopia
source revealed the diagnosis ("octave marks lost in cleaning") was wrong on
both counts. The note text was intact; a Phase 4 anchor "correction" had
diverged from the original, and the resolver's parallel-music octave rule was
itself wrong in a way the prototype shared (BUG-007 — LilyPond threads
relative context through `<< >>` children sequentially). Both fixes were
proven against Mutopia's own MIDI renderings. Carried forward as:
- `Corpus/clair-de-lune.ly` vendored,
- a `ParallelMusicExpander` in the Resolver (port the round-robin logic — it
  worked),
- an acceptance test under `withKnownIssue`,
- GitHub issue #1 describing exactly where it breaks, inviting contributors.
Success criteria if ever solved: all four voices equal length per section, opening
melody fingerprint matches, validator passes. **Never ship a subtly wrong
version** — a correct excerpt beats an incorrect whole (this is project policy,
stated in README).

---

## 8. The app (SwiftUI) and UI-testing curriculum

**Screens (MVP):**
1. **Library** — list of corpus pieces (title, composer, duration, license badge).
2. **Piece Detail** — Build button → progress → track list with per-track
   instrument names; Play/Pause (`AVMIDIPlayer`); tempo slider (rebuild MIDI at new
   BPM or set tempo meta); Export via `ShareLink`/share sheet.
3. **Diagnostics** — after a build, show the Validator's findings (all green for
   the six; Clair de Lune intentionally shows its alignment failure — the app is
   honest in the UI the same way the tests are).

**Architecture:** thin observable view models over `EtudeKit` — only where §0.9
says a screen earns one — talking to the engine through the `PieceBuilding` seam
(§0.3) so view-model unit tests run against a spy with no real parsing; builds
run off the main actor; every
interactive element gets a stable `accessibilityIdentifier`
(e.g. `library.row.gymnopedie-1`, `detail.button.build`, `detail.slider.tempo`).
View-model and player-wrapper unit tests use `makeSUT()` + `trackForMemoryLeaks`
(§0.6) — the app layer is where reference types (and leaks) live.

**UI-test curriculum (XCUITest):**
- Page objects (`LibraryScreen`, `PieceDetailScreen`) wrapping queries + waits —
  no raw `app.buttons[...]` in test bodies.
- Happy path: launch → tap Gymnopédie → Build → wait for Play enabled → Play →
  export sheet appears.
- Failure surfacing: open Clair de Lune → Build → Diagnostics shows alignment
  findings (testing that errors are *presented*, not just thrown).
- Launch-argument seams (`-uiTesting`) to skip audio hardware where needed and to
  make builds deterministic/fast in tests.
- Flake discipline: explicit expectations/waits, no `sleep`.

---

## 9. Open source + App Store

- **License: Apache-2.0** (explicit patent grant; permissive; compatible with App
  Store distribution — GPL is not). Record reasoning in ADR-0004.
- The app's name/branding is the practical protection against clone submissions;
  the README states the code is open but the name/icon are not to be used for
  derivative store submissions.
- Corpus licensing per §5; app credits screen lists Mutopia attributions.

---

## 10. Build phases (executed in order)

Every phase from 1 onward is executed under the §0 method: one behavior per
commit, behavior-named subjects, red→green→refactor. "History reads as a TDD
narrative" is an acceptance criterion of every phase, not a style preference.

### Phase 0 — Scaffold (done)
SPM package + Xcode workspace per §2; CI workflow; LICENSE, README (project
pitch + the "no subtly wrong music" policy), CONTRIBUTING (test taxonomy, PRs
require tests); empty ADR/lessons templates; vendor whatever corpus files are
available (fetch from Mutopia if network allows, else stub with TODO+URLs).
**Accept:** `swift test` runs (zero tests, green); app target builds and shows an
empty Library.

### Phase 1 — Tokenizer, test-first (done)
Token model + lexer per §4.1. Write the parameterized token tables and BUG-001/
BUG-005 regression tests **before** the implementation. Fuzz smoke test. Establish
the `Helpers/` conventions (§0.6) here — `makeSUT()`, sample builders — so every
later phase inherits them.
**Accept:** tokenizes the Gymnopédie and Gnossienne sources end-to-end without
error; all Unit+Regression tests green; `git log` for the phase reads as
red→green→refactor steps (§0.1).

### Phase 2 — Parser + Resolver (done)
Event tree, then relative-octave resolution, repeats, tuplets, graces per
§4.2–4.3. BUG-002/BUG-003 regression tests; the three resolver property tests.
Enforce the boundary-model rule (§0.4): the LilyPond-shaped tree must not appear
in any signature past the Resolver.
**Accept:** Gymnopédie and Gnossienne resolve to correct opening fingerprints and
bar counts (78 and 82 bars).

### Phase 3 — Model, Validator, MIDI writer (done)
§4.4–4.5 including the SMF reader and round-trip property. BUG-004 as a
validator-throws test. Golden fixtures established.
**Accept:** all six pieces build, validate, byte-stable across two consecutive
runs; golden tests green.

### Phase 4 — Acceptance suite + Boss Fight (done)
Corpus acceptance tests with fingerprints; ParallelMusicExpander port; Clair de
Lune under `withKnownIssue`; write `docs/lessons/` entries for all six bugs.
**Accept:** suite green with exactly one known issue recorded. *(Met — and the
issue is narrower than planned: §7's alignment problem is SOLVED; what remains
on record is lhDown register drift, GitHub issue #1.)*

### Phase 5 — App MVP + UI tests (done)
Screens per §8, page objects, the three UI test flows, accessibility identifiers
throughout. View models built against a `PieceBuilding` spy first (§0.3); leak
tracking in every app-layer `makeSUT()` (§0.6).
**Accept:** UI tests green on simulator; export produces a `.mid` that GarageBand
opens (manual check). *(UI tests green on iPhone 17 Pro / iOS 26.2; the
GarageBand open remains a manual checklist item before shipping.)*

### Phase 6 — Polish for store + course (done)
App icon, credits/licenses screen, README course map ("which test to read first"),
plus the two capstone lessons from §0:
- **The swap (§0.5):** write `SMFWriterSpecs` against the existing writer, add a
  running-status `SMFWriter`, prove both against the specs + round-trip property
  + re-baselined goldens, then delete the naive writer in a single commit.
  *(Done in four commits ending with the single-commit deletion; goldens came
  back ~23% smaller with identical events.)*
- **The history (§0.1):** generate Étude's `HISTORY.md` from the git log; if the
  narrative has gaps, that's a retrospective finding, not something to backfill.
  *(Done — three duplicate-subject red/green pairs and the scaffold's invisible
  month are on record in HISTORY.md as findings.)*
Tag `v0.1.0`.

### Phase 7 — Delivery (planned)

Phases 0–6 built the course; this phase puts it in front of students. The
artifact is finished — what follows is diligence, decisions, and distribution.
Unlike the build phases, most steps here are not code; the §0 commit discipline
applies only where code changes (7.4).

**7.1 Corpus licensing diligence (blocks going public).** Close every open row
in `Corpus/LICENSES.md`:
- **Winter** — recover the typesetter's name from the Mutopia edition and add
  the CC-BY-SA attribution string (action item 2).
- **Minuet, Air** — open each Mutopia source header, confirm its license, and
  record it (action item 1).
- **Gnossienne** — determine whether the edition's CC-BY-SA reaches our
  reconstruction. If yes, attribute + share-alike that file; if the answer is
  unclear, treat it as reaching (attribute anyway) or re-typeset from a PD
  edition — never ship an unresolved license question in a public repo.

**7.2 The history decision.** Decide, explicitly, whether the private-era
history publishes as-is or is squashed first — and record the reasoning as
**ADR-0005**. The tension is real: §0.1 says the history is a deliverable and
HISTORY.md already records its defects as findings; rewriting would erase the
very evidence the course teaches from. The default position is **publish
as-is** — a history with three documented duplicate subjects is a better
lesson than a laundered one. *(Decided: publish as-is — **ADR-0005**.)*

**7.3 Go public.** Flip the repo to public with: a description and topics;
retroactive lightweight tags at each `PLAN: mark Phase N done` commit so every
course stop is checkout-able (`phase-1` … `phase-6`); a short **CONTRIBUTING.md**
stating the §0 rules a PR must follow (one behavior per commit, behavior-named
subject, test first) and pointing new readers at the README course map; CI
green and public.

**7.4 App Store submission.** "A real product raises the stakes" is part of
the course's argument, so shipping is part of delivery:
- **Issue #3 is the gate** — silent in-app playback on device (no iOS sound
  bank, no audio session). Fixed under the §0 method; the bundled SoundFont's
  license lands in the credits screen and `Corpus/LICENSES.md`-style provenance.
- Store metadata, screenshots, privacy declarations (none to declare — the app
  is offline), and review. Ship as **1.0.0**, tagged.

**7.5 Student-facing extras (optional, after public).** Exercise checkpoints
("before reading the fix commit, try writing the failing test yourself") added
to the lessons; a first-issue label seeding contributions. Issue #4 (browse
and download from Mutopia) is the designated post-1.0 arc — real-world input
is the fuzzing curriculum arriving as a feature.

**Accept:** LICENSES.md has zero open action items; ADR-0005 exists; the repo
is public with phase tags and CONTRIBUTING.md; the app is live on the App
Store with audible playback; issues #3 closed and #4 groomed as the next arc.

---

## Appendix A — Validation checklist (run for every piece, always)
1. Voice alignment: simultaneous voices equal tick-length per section.
2. Opening pitches match the known tune.
3. Per-track register sane (no octave 0/8 artifacts).
4. SMF structure: `MThd`, every `MTrk` terminated, clean EOF.

## Appendix B — Known piece fingerprints (for acceptance tests)
| Piece | Voices/Tracks | Bars | Opening melody | Notes |
|---|---|---|---|---|
| Minuet in G (Petzold, BWV Anh. 114) | 2 (melody, bass) | AABB w/ repeats (16+16) | D5 G4 A4 B4 C5 | 4 mordents, 1 prall, 1 grace; ~126 BPM |
| Bach Prelude in C (BWV 846) | 3 (figuration, tenor, bass) | 34 (no Schwencke bar) | broken C-major figure (G4 C5 E5) | ~72 BPM |
| Air on the G String (BWV 1068) | 2 (flute, guitar-upper) | 18 | long F♯5 (tied whole + eighth) | 2 acciaccaturas; bass part omitted (edition mismatch); Phase 3 corrected this row's opening (was "long D5" — the prototype MIDI and the source both open on F♯5) |
| Winter Largo (RV 297) | 5 (solo, 2 violins, viola, cello) | 18 | E♭-major solo (D♯/A♯ enharmonic in source) | ~52 BPM, pizzicato accompaniment |
| Gymnopédie No. 1 | 3 (melody, accompaniment, bass) | 78 | F♯5 A5 G5 F♯5 | Gmaj7/Dmaj7 alternation; "Lent" |
| Gnossienne No. 1 | 4 (melody, upper, lower, bass) | 82 | C5 E♭5 D5 C5 B4 | English note names, bare `\relative`, `q` chord-repeat, low-F pedal |
| Clair de Lune | 4 voices | 72 | F4+A♭4, F5+A♭5 thirds | Aligned since Phase 4; register drift (issue #1) closed post-v0.1.0 against the recovered Mutopia original — no known issues remain |
