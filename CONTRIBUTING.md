# Contributing to Étude

Thanks for wanting to work on this. Étude is both a working app and a course in
testing architecture, and its **git history is a deliverable** (PLAN.md §0.1;
ADR-0005). Contributions are judged on the same discipline the history
demonstrates — that's the point of the project, and it applies to human and
AI-assisted work alike.

## Before you start

- **New here?** Read the README's course map first — eight stops, each naming
  the test file that best teaches one technique. Then skim PLAN.md §0 (the
  method) and `docs/adr/` (the load-bearing decisions, all short).
- **Looking for something to do?** Check the open issues. Good first
  contributions are usually a new corpus piece that exposes a parser gap, or a
  lesson-quality regression test for a bug you found.

## The rules a PR must follow

These come from PLAN.md §0 and are checked in review:

1. **One behavior per commit.** Never batch behaviors. If your change is "parse
   X and also fix Y," that's two commits.
2. **Behavior-named subjects.** The subject line states the behavior in the
   code's voice: "Resolves relative octaves within a fourth of the previous
   note" — not "Update Resolver.swift" or "Fix bug".
3. **Test first.** Each behavior lands red→green→refactor. The failing test is
   written before the code that passes it. (Run `swift test` unpiped — piping
   through `tail` masks the exit code, a mistake this repo has made and
   documented.)
4. **The two-model boundary holds.** The LilyPond-shaped parse tree never
   appears in any signature past the Resolver (§0.4). `Score` speaks a
   musician's vocabulary, zero LilyPond concepts.
5. **Findings, not repairs.** The Validator throws structured findings; never
   add a clamp, fallback, or silent correction where an invariant belongs
   (ADR-0001). A defect we can't fix yet ships as a *visible known issue*
   (ADR-0003), not a skipped test.
6. **Goldens change loudly.** If your change re-baselines a golden `.mid`
   fixture, say so in the commit and record the reasoning in
   `Tests/EtudeKitTests/Golden/Fixtures/README.md`. A silent golden diff is a
   review blocker.
7. **Corpus changes carry provenance.** New or edited `.ly` sources update
   `Corpus/LICENSES.md` in the same PR — edition, typesetter, license,
   verified from the source's own header. CC-BY-SA typesettings stay CC-BY-SA
   and attributed.

## Build & test

```sh
swift test                      # fast lane: the engine (run this constantly)
cd App/Etude && xcodegen generate && \
  xcodebuild test -scheme Etude \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'   # slow lane
```

CI runs both lanes on every PR; both must be green.

## Scope notes

- The engine (`Sources/EtudeKit/`) imports no UI frameworks. Keep it that way.
- The app's name, icon, and branding are not licensed for derivative App Store
  submissions (see README § License).
- AI-assisted contributions are welcome under the same rules; the discipline is
  enforced on the output, not the tool.
