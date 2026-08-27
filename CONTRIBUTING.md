# Contributing to Étude

Thanks for wanting to work on this. Étude is both a working app and a course in
testing architecture: **the tests are the product**, and the **git history is a
deliverable** (PLAN.md §0.1; ADR-0005). Contributions are judged on the same
discipline the history demonstrates — that's the point of the project, and it
applies to human and AI-assisted work alike.

## Before you start

- **New here?** Read the README's course map first — eight stops, each naming
  the test file that best teaches one technique. Then skim PLAN.md §0 (the
  method) and `docs/adr/` (the load-bearing decisions, all short).
- **Looking for something to do?** Check the open issues. Good first
  contributions are usually a new corpus piece that exposes a parser gap, or a
  lesson-quality regression test for a bug you found.

## The commit rules a PR must follow

These come from PLAN.md §0 and are checked in review:

1. **One behavior per commit.** Never batch behaviors. If your change is "parse
   X and also fix Y," that's two commits.
2. **Behavior-named subjects.** The subject line states the behavior in the
   code's voice: "Resolves relative octaves within a fourth of the previous
   note" — not "Update Resolver.swift" or "Fix bug".
3. **Test first.** Each behavior lands red→green→refactor. The failing test is
   written before the code that passes it. (Run `swift test` unpiped — piping
   through `tail` masks the exit code, a mistake this repo has made and
   documented in HISTORY.md.)

## Where your tests go — the taxonomy

`EtudeKit` tests use [Swift Testing](https://developer.apple.com/documentation/testing)
(`import Testing`, `@Test`, `#expect`, `#require`) and are tagged for suite slicing
(`swift test --filter-tag <tag>`):

| Folder | Tag | What it proves |
|---|---|---|
| `Tests/EtudeKitTests/Unit/` | `.unit` | Table-driven tokenizer/parser behavior; one rule per case. Prefer **parameterized** tests over copy-pasted cases. |
| `Tests/EtudeKitTests/Property/` | `.property` | Laws that hold for *all* inputs — resolve/transpose commutation, `unfold n` = n identical copies, octave-mark inverses. Generators are hand-rolled (seeded, shrink by halving); see the ADR on why we took no dependency. |
| `Tests/EtudeKitTests/Regression/` | `.regression` | One file per historical bug (`BUG00N_*.swift`), with the story in a doc comment. **Never delete these** — they are the curriculum. |
| `Tests/EtudeKitTests/Golden/` | `.golden` | Emitted `.mid` compared byte-for-byte to known-good fixtures. On mismatch, decode both and print an event-level diff — failures must be diagnosable. |
| `Tests/EtudeKitTests/Acceptance/` | `.acceptance` | Full-piece corpus builds asserting bar count, voice count, opening fingerprint, duration, and byte-equality. |

UI tests live in `App/Etude/EtudeUITests/` and use **XCTest/XCUITest** (UI testing is
XCTest-only). Use the **Page Object pattern** — no raw `app.buttons[...]` in test bodies —
give every interactive element a stable `accessibilityIdentifier`, and wait on explicit
expectations (no `sleep`).

## Ground rules

- **PRs require tests.** A behavior change with no test will be sent back.
- **Fix a bug? Add a regression test first** (red), then make it green, then write the
  `docs/lessons/` entry (symptom → root cause → guard).
- **The two-model boundary holds.** The LilyPond-shaped parse tree never appears in
  any signature past the Resolver (§0.4). `Score` speaks a musician's vocabulary,
  zero LilyPond concepts.
- **Validators throw; they do not clamp** (ADR-0001). Don't "repair" bad data into looking
  correct — surface it.
- **No subtly wrong music.** If a piece can't be rendered faithfully yet, mark it a visible
  known issue; don't disable the test (ADR-0003).
- **Goldens change loudly.** If your change re-baselines a golden `.mid` fixture, say so
  in the commit and record the reasoning in
  `Tests/EtudeKitTests/Golden/Fixtures/README.md`. A silent golden diff is a review blocker.
- **Decisions get an ADR.** Non-obvious architectural choices go in `docs/adr/` (numbered).
- **Corpus licensing matters.** New or edited `.ly` sources update `Corpus/LICENSES.md`
  in the same PR — edition, typesetter, license, verified from the source's own header.
  CC-BY-SA typesettings (currently Winter and the Gnossienne) stay CC-BY-SA and attributed.

## Before you open the PR

```sh
swift test                      # engine, fast lane — must be green
cd App/Etude && xcodegen generate && xcodebuild test -scheme Etude \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

CI runs both lanes on every PR; both must be green.

## Scope notes

- The engine (`Sources/EtudeKit/`) imports no UI frameworks. Keep it that way.
- The app's name, icon, and branding are not licensed for derivative App Store
  submissions (see README § License).
- AI-assisted contributions are welcome under the same rules; the discipline is
  enforced on the output, not the tool.
