\version "2.24.0"
% Gymnopédie No. 1 — Erik Satie (composition public domain).
%
% RECONSTRUCTED performing text: pitches, durations, chords, repeats, and voice
% structure are the prototype-proven note streams from the prior-art repo
% (music/gymnopedie.py), which cleaned them from a Mutopia edition. The
% engraving layer (dynamics, pedal, page markup) is omitted. 78 performed bars,
% opening melody F#5 A5 G5 F#5 (PLAN.md Appendix B).
%
% BUG-004 note: the prototype reduced the ending's `<< … >>` octave-reference
% bar to its sustained bass note after register drift was clamped (and hidden).
% The Swift Validator must THROW on that figure — see docs/adr/0001-clamp-vs-throw.md.
%
% Ending provenance (issues #1/#2): the alternatives below are Evin Robertson's
% original text verbatim (the `<< \context Voice … >>` figure bar restored, the
% closing chords `<g' a,> <d a d,>` in his marks). The Phase 3 "correction"
% had re-marked them toward the prototype's clamp targets — G2+A2 where the
% engraving has G3+A2, doubled D2s in the final chord, B2 for the first
% ending's B1, and no voicelet at all. All of that descended from BUG-007
% (the prototype and this engine both mis-resolved parallel and alternative
% relative context, so the clamp targets themselves were an octave off).
% Restored and pitch-verified bar-by-bar against Robertson's own LilyPond
% rendering (gymnopedie_1.mid).
% Also: this engine threads relative context through pitched rests (`d4\rest`)
% as LilyPond does; the prototype ignored rest pitches, so its MIDI put the
% first-ending chords an octave higher than the engraving implies. The golden
% fixture encodes this engine's engraving-faithful reading.
% Original edition: https://www.mutopiaproject.org/ftp/SatieE/gymnopedie_1/

\header {
  title = "Gymnopédie No. 1"
  composer = "Erik Satie"
}

melody = \relative c'' {
  \time 3/4
  \tempo "Lent" 4 = 66
  \repeat volta 2 {
    R2. R2. R2. R2.
    s4 fis( a g fis cis b cis d a2. fis2.~ fis2.~ fis2.~ fis2.
    s4 fis'( a g fis cis b cis d a2. cis2. fis2. e,2.~ e2.~ e2.
    a4( b c e d b d c b d2.~ d2 d4( e f g a c, d e d b d2.~ d2) d4
  }
  \alternative {
    { g2.( fis2. b,4 a b cis d e cis d e fis,2. <c' a e c>2. <d a fis d>2. }
    { g2.( f2. b,4 c f e d c e d c f,2. <c' a e c>2. <d a f d>2. }
  }
}

accompaniment = \relative c' {
  \time 3/4
  \repeat volta 2 {
    r4 <fis d b>2 r4 <fis cis a>2 r4 <fis d b>2 r4 <fis cis a>2 r4 <fis d b>2
    r4 <fis cis a>2 r4 <fis d b>2 r4 <fis cis a>2 r4 <fis d b>2 r4 <fis cis a>2
    r4 <fis d b>2 r4 <fis cis a>2 r4 <fis d b>2 r4 <fis cis a>2 r4 <fis d b>2
    r4 <fis cis a>2 r4 <fis cis a>2 r4 <fis d b>2 r4 <b, g>2 r4 <g' d b>2 r4 <d a f>2
    r4 <e c a>2 r4 <e b g>2 r4 <e b g d>2 r4 <d a e c>2 r4 <d a fis c>2 r4 <f c a>2
    r4 <e c a>2 r4 <e b g d>2 r4 <d a e c>2 r4 <d a fis c>2
  }
  \alternative {
    { e4\rest <g e b>2 e4\rest <fis cis a>2 d4\rest <fis d b>2 d4\rest <a' e cis>2
      d,4\rest <a' fis cis a>2 a,4\rest <d a>4 <g d b> s2. s2. }
    { e4\rest <g e b>2 e4\rest <a f d a>2 d,4\rest <f c a>2 d4\rest <a' e c>2
      d,4\rest <a' f c a>2 a,4\rest <d a>4 <g d b> s2. s2. }
  }
}

bass = \relative c {
  \time 3/4
  \repeat volta 2 {
    g2. d2. g2. d2. g2. d2. g2. d2. g2. d2. g2. d2. g2. d2. g2. d2.
    fis2. b2. e,2. e2. d2. a'2. d,2. d2. d2. d2. d2. d2. d2. d2. d2.
  }
  \alternative {
    { e2. fis2. b,2. e2. e2.
      << \context Voice = "othervoice" { c'4\rest b e } e,2. >>
      <g' a,>2. <d a d,>2. }
    { e,2. e2. e2. e2. e2.
      << \context Voice = "othervoice" { c'4\rest b e } e,2. >>
      <g' a,>2. <d a d,>2. }
  }
}

\score {
  <<
    \new Staff \melody
    \new Staff <<
      \new Voice \accompaniment
      \new Voice \bass
    >>
  >>
}
