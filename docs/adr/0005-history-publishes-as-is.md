# ADR 0005 — The private-era history publishes as-is

**Status:** Accepted (Phase 7)

## Context
The entire history — 150+ commits — was written while the repo was private.
Going public (PLAN.md 7.3) is the last moment a rewrite is possible; after that,
rewriting `main` breaks every clone. The log has known defects, recorded in
HISTORY.md: three near-instant fixup commits that reuse their predecessor's
subject verbatim (each landed 14–22 seconds after its twin, when they should
have been amended or autosquashed), Phase 0's invisible month, tags only at the
end. The timestamps also expose the burst cadence — some 90 commits landed on a
single day, executing acceptance criteria written weeks earlier.

The alternative seriously considered was a **targeted cleanup**: autosquash only
the three fixup pairs, remap HISTORY.md's hash citations from the rebase map,
leave errata comments on the closed issues, and preserve the pre-rewrite tip
under an archived ref — edits documented, nothing denied. That is a coherent,
honest position: every other deliverable here was edited before publication
(PLAN.md was rewritten in the project's voice, goldens re-baselined, the naive
writer deleted), and the fixup pairs teach nothing that HISTORY.md's prose
doesn't.

## Decision
Publish the history **verbatim**. No squash, no reorder, no reword, no
timestamp edits — not even the three fixup pairs.

Three reasons, in order:

1. **The log is the course's evidence, and evidence loses its standing when
   edited — even once, even documented.** §0.1 claims a student can replay the
   history as a TDD transcript, and the README discloses that the transcript
   was produced with AI assistance under human-enforced discipline. That claim
   is only checkable against an unedited log. A curated log — however loudly
   the curation is recorded — invites the reasonable suspicion that it was
   curated because the original would not survive inspection.
2. **The hashes are load-bearing.** HISTORY.md's narrative and the closing
   comments on issues #1 and #2 cite commit hashes as the permanent record of
   closed investigations. Comments on closed issues cannot be honestly
   retconned to post-rebase hashes.
3. **It is what the project already practices.** ADR-0003's ethic — a defect is
   a *visible known issue*, never silently repaired — was applied to the code
   (Clair de Lune shipped loud) and HISTORY.md explicitly extends it to the
   history: "a gap in the narrative is a retrospective finding, not something
   to rewrite away." The history is the one deliverable whose value comes from
   being a record rather than a text, which is why it — unlike the PLAN or the
   goldens — does not get the editorial pass.

The log was audited before deciding: all subjects are composed, behavior-named
sentences under a single author identity; nothing requires laundering.

## Consequences
- The three duplicate subjects stay in the log. HISTORY.md's finding about them
  is **corrected** (they were misdescribed as red/green twins; they are
  near-instant fixups) — the correction is itself a new commit, not a rewrite.
- The retroactive `phase-1`…`phase-6` tags (7.3) annotate the existing commits;
  they do not restructure anything.
- The burst cadence and AI-assisted pace are public and answerable only by the
  log's own quality — which is the bet this ADR makes.
- Future history mistakes get the same treatment: recorded in HISTORY.md as
  findings, never repaired. The tooling lesson stands — enforce commit
  discipline mechanically (unpiped test runs, `--autosquash` habits), because
  after publication there is no second chance.
