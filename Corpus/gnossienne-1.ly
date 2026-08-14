\version "2.24.0"
\language "english"
% Gnossienne No. 1 — Erik Satie (composition public domain).
%
% RECONSTRUCTED performing text from the prior-art prototype (music/gnossienne.py),
% which cleaned it from a Mutopia edition (that typesetting is CC-BY-SA — see
% Corpus/LICENSES.md). Exercises: ENGLISH note names (cs/df style), bare
% \relative theme blocks, the `q` chord-repeat, \crossStaff grouping braces
% (BUG-003 territory), grace notes, and — deliberately preserved verbatim —
% a `<<` polyphony wrapper glued directly to a pitch token (BUG-005).
% 82 bars; opening melody C5 Eb5 D5 C5 B4 (PLAN.md Appendix B).
% Original edition: https://www.mutopiaproject.org/ (search "Satie Gnossienne")

\header {
  title = "Gnossienne No. 1"
  composer = "Erik Satie"
}

themeOneMelody = \relative {
  r4 c''8 ( ef d4 c |
  \grace { c8 } b2 \grace { c8 } b!2 ) |
  r4 c8 ( ef d4 c |
  \grace { e8 } f2 \grace { e!8 } f2 ) |
  r4 c8 ( ef d4 c |
  \grace { c8 } b2 \grace { af8 } g2 |
  \grace { f8 } g4 \grace { f8 } g2 ~ g8 ) r |
  \grace { af8 } g4 \grace{ g8 } f4 ~ f2 ~ |
  f1 |
}
themeOneUpper = \relative {
  \crossStaff { \repeat unfold 6 { s4 <c' f>2 q4 | } }
  s1 | \crossStaff { s4 <c f>2 q4 | s4 <c f>2 q4 | }
}
themeOneLower = \relative {
  \crossStaff { \repeat unfold 6 { af4\rest af2 af4 | } }
  af4\rest <ef g c>2 q4 |
  \crossStaff { af4\rest <<af2 \new Voice{\voiceOne \once \hideNotes af4 }>> af4 | af4\rest af2 af4 | }
}
themeOneBass = \relative { \repeat unfold 6 { f,1 | } c'1 | f,1 | f1 | }

themeTwoMelody = \relative {
  \grace { af'8 } bf2 ( \grace { af8 } g2
  \grace { af8 } bf2 \grace { af8 } g2
  \grace { af8 } g4 \grace{ g8 } f4 ~ f2 ~ |
  f1 ) |
}
themeTwoUpper = \relative {
  \crossStaff { s4 df'2 df4 | s4 df2 df4 | s4 <c f>2 q4 | s4 <c f>2 q4 | }
}
themeTwoLower = \relative {
  \crossStaff { af4\rest <f bf>2 q4 | af4\rest <f bf>2 q4 |
  af4\rest <<af2 \new Voice{\voiceOne \once \hideNotes af4 }>> af4 | af4\rest af2 af4 | }
}
themeTwoBass = \relative { bf,,1 | bf1 | f'1 | f1 | }

themeThreeMelody = \relative {
  r8 c'' ( d e f g b g |
  f4 \grace { g8 } f4 ~ f2 |
  \grace { g8 } f2 \grace { f8 } e2 |
  \grace { df!8 } c2 \grace { c8 } b2 |
  \grace { af8 } g4 \grace{ g8 } f4 ~ f2 ~ |
  f1 ) |
}
themeThreeUpper = \relative {
  \crossStaff { \repeat unfold 6 { s4 <c' f>2 q4 | } }
}
themeThreeLower = \relative {
  \crossStaff { \repeat unfold 4 { af4\rest af2 af4 | }
  af4\rest <<af2 \new Voice{\voiceOne \once \hideNotes af4 }>> af4 | af4\rest af2 af4 | }
}
themeThreeBass = \relative { \repeat unfold 6 { f,1 | } }

themeFourMelody = \relative {
  r4 c''8 ( ef d4 c |
  \grace { c8 } b1 ) |
  r4 c8 ( ef d4 c |
  \grace { e8 } f1 ) |
}
themeFourUpper = \relative {
  \crossStaff { \repeat unfold 4 { s4 <c' f>2 q4 | } }
}
themeFourLower = \relative {
  \crossStaff { \repeat unfold 4 { af4\rest af2 af4 | } }
}
themeFourBass = \relative { \repeat unfold 4 { f,1 | } }

% Performed arrangement: 1 1 2 2 3 3 2 2 4 4 2 2 3 3 2 2
melody = {
  \time 4/4
  \tempo 4 = 72
  \themeOneMelody \themeOneMelody \themeTwoMelody \themeTwoMelody
  \themeThreeMelody \themeThreeMelody \themeTwoMelody \themeTwoMelody
  \themeFourMelody \themeFourMelody \themeTwoMelody \themeTwoMelody
  \themeThreeMelody \themeThreeMelody \themeTwoMelody \themeTwoMelody
}
upperChords = {
  \themeOneUpper \themeOneUpper \themeTwoUpper \themeTwoUpper
  \themeThreeUpper \themeThreeUpper \themeTwoUpper \themeTwoUpper
  \themeFourUpper \themeFourUpper \themeTwoUpper \themeTwoUpper
  \themeThreeUpper \themeThreeUpper \themeTwoUpper \themeTwoUpper
}
lowerChords = {
  \themeOneLower \themeOneLower \themeTwoLower \themeTwoLower
  \themeThreeLower \themeThreeLower \themeTwoLower \themeTwoLower
  \themeFourLower \themeFourLower \themeTwoLower \themeTwoLower
  \themeThreeLower \themeThreeLower \themeTwoLower \themeTwoLower
}
bass = {
  \themeOneBass \themeOneBass \themeTwoBass \themeTwoBass
  \themeThreeBass \themeThreeBass \themeTwoBass \themeTwoBass
  \themeFourBass \themeFourBass \themeTwoBass \themeTwoBass
  \themeThreeBass \themeThreeBass \themeTwoBass \themeTwoBass
}

\score {
  <<
    \new Staff \melody
    \new Staff <<
      \new Voice \upperChords
      \new Voice \lowerChords
      \new Voice \bass
    >>
  >>
}
