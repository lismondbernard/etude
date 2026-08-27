# Lesson: BUG-007 — Parallel music placed from the door, not the thread

> The first bug found *after* v0.1.0 — and the only one in the catalog that shipped
> inside this engine rather than the prototype. Found while closing issue #1.
> The matching tests are `ResolveParallelMusicTests` ("relative context threads
> through children in source order") and the corrected
> `BUG004_ClampedSubAudibleBass` expectations.

## Symptom
Clair de Lune's `lhDown` sank below the piano's floor (to MIDI 3) in bars 22–24 and
63–65 — the visible half of known issue #1. Quieter symptoms hid elsewhere: the
Minuet's written bar 29 played D4 where Allen Garvin's edition engraves D3, and
BUG-004's regression expectations placed the Gymnopédie's closing chords an octave
above the score.

## Root cause
Phase 3 implemented the *intuitive* rule for `\relative` across `<< … >>`: every
child places from the octave context at the group's door, and the first child's end
leads afterwards. LilyPond's actual rule is stranger: for octave purposes the
children resolve **as if written sequentially** — each child threads from the
previous child's end, and the last child's end leads. In Clair de Lune's §2 climax,
every `<< {chord} {countermelody} >>` bar therefore entered one octave lower than
LilyPond intended, and the errors compounded bar over bar until the bass fell off
the piano.

The rule survived Phase 3's verification because the **Python prototype had the
same bug** — its MIDI matched ours in the affected Minuet bars, so
prototype-comparison confirmed the wrong pitches. Two independent implementations
agreeing proves consistency, not correctness.

## The guard now in place
`ResolveParallelMusicTests.childrenThreadTheRelativeContext` pins the sequential
rule directly. The corpus goldens pin it end-to-end — and this time against the
right referee: the fix was proven bar-by-bar against **Mutopia's own
LilyPond-rendered MIDI** of Clair de Lune, the Minuet, and the Gymnopédie ending,
an oracle independent of both this engine and the prototype.

## Lesson
Verify against an oracle that did not share your assumptions. The prototype was
close kin to this engine — same source texts, same cleaning, same intuitions — so
agreement with it was weak evidence. The upstream renderer's own output was the
ground truth all along, one `curl` away. Corollary: when a "correction" makes data
fit a rule (Phase 4 re-anchoring §1 to `c,` because the register "only made sense
there"), consider that the rule, not the data, may be wrong — the anchor was the
original's `c'`, and it was the resolver that misread it.
