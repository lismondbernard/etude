\version "2.24.0"
% Air on the G String — J.S. Bach, BWV 1068 (Wilhelmj) (public domain composition).
%
% RECONSTRUCTED performing text from the prior-art prototype (music/air.py),
% which cleaned the Mutopia flute+guitar edition. Written in its PERFORMED
% form: the edition's volta repeats play once and only the first ending
% sounds — the prototype's proven 18-bar reading, kept so the piece matches
% its golden fixture. KNOWN EDITION QUIRK (PLAN.md §5): the separate bass part
% has a 1-bar repeat mismatch vs the melody, so this piece is flute melody +
% guitar-upper accompaniment only — a deliberate "real data is messy" lesson.
% String-number fingerings were stripped. 2 acciaccaturas. ~66 BPM.
% NOTE: the guitar's partial chord-to-note ties (`< fis a >8 ~ a`) SUSTAIN the
% shared pitch here, as LilyPond does; the prototype re-attacked it, so this
% engine emits two fewer guitar note events than the prototype's MIDI.
% Original edition: https://www.mutopiaproject.org/ (search "Air on the G String BWV 1068")

\header {
  title = "Air on the G String"
  composer = "Johann Sebastian Bach"
}

melody = \relative c' {
  \time 4/4
  \tempo 4 = 66
 fis'1 ~ |
 fis8 b16 g \acciaccatura { fis8 } e16 d cis d cis4 \acciaccatura { b8 } a4 |
 a'2 ~ a16 fis c! ( b ) e ( dis! ) a' g | g2 ~ g16 e b ( a ) d ( cis ) g' ( fis ) |
 fis4. gis!16 ( a ) d,8 d32 e fis16 ~ fis e e ( d ) |
 cis16 b b32 cis d16 ~ d8 cis16 b a2 |
 cis4 ~ cis16 d32 cis b cis a16 a'4. c,!8 |
 b b' ~ b16 a g fis g4 ~ g32 fis e d cis!16 b |
 ais! b cis8 ~ cis16 d e8 ~ e16 fis g8 ~ g fis |
 e16 d cis b cis ( d32 e ) d8 b2
 d4 ~ d16 fis e d b'4 ~ b8 a16 gis! |
 fis32 e a16 a,8 b8. ( cis32 d ) cis8. b16 a4 |
 d4. fis16 ( e ) e4. g16 ( fis ) |
 fis4. a16 ( g ) g2 |
 a,4 ~ a16 cis e g g e fis8 ~ fis ~ fis16 g32 a |
 d,4 ~ d16 fis a c! b4. d,8 |
 cis!16 e g4 b,8 a e'16 fis32 g~ g16 fis8 e16 |
 d32 cis b8 cis16 d8 ( cis16 ) d d2
}

accompaniment = \relative c' {
  \time 4/4
 < a' d >2 b |
 <b d,>4 < e, b' > < e a >2 ~ |
 < e a >8 c'!16 b c8 a'16 c, b8 r r4 |
 b8 e16 d e fis g e < e, a >8 r r4 |
 a2 ~ a8 gis!16 a b8 gis |
 < e a >8 < fis a > ~ a < e gis! > < e a >2 |
 < e a >2 ~ a16 b < dis,! c'! > e fis b a g |
 fis g a fis dis8 < b' dis! > < b e >2 |
 cis16 d! e fis g fis g e fis d cis b ais! b cis8 |
 < fis, b > < e b' >16 d < g b >8 < fis ais! >16 e fis2
 e8 b' a16 gis! a8 b, e16 fis gis! a b8 ~ |
 b a4 gis!8 < e a >8. d16 cis d e cis |
 a'8 b16 c! b cis! d8 ~ d cis16 b cis dis! e8 ~ |
 e dis!16 cis dis e fis8 ~ fis16 dis! e b e, b' g e |
 r8 e16 a cis8 a ~ a cis16 d d,4 ~ |
 d8 e fis4 < d g >2 |
 e16 b e g b a g fis e d' cis b a8 b |
 a4 g16 fis g8 fis2
}

\score {
  <<
    \new Staff \melody
    \new Staff \accompaniment
  >>
}
