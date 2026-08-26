\version "2.24.0"
% Winter — Largo (RV 297) — Antonio Vivaldi, "The Four Seasons" Op. 8 No. 4,
% second movement (public domain composition).
%
% RECONSTRUCTED performing text from the prior-art prototype (music/winter.py),
% which cleaned a Mutopia edition. That edition's TYPESETTING is CC-BY-SA —
% see Corpus/LICENSES.md for attribution status before redistributing this
% file. 18 bars, five string parts. Trilled notes play plain (the prototype's
% reading, baked into the goldens). The solo opens the E-flat major theme:
% Eb5 Bb5 Ab5 G5 F5 (the original source spelled some of these enharmonically
% as D#/A#; the prototype normalized the spelling). ~52 BPM.
% Original edition: https://www.mutopiaproject.org/ (search "Vivaldi Four Seasons Winter")

\header {
  title = "Winter (Largo)"
  composer = "Antonio Vivaldi"
}

solo = \relative ees'' {
  \time 4/4
  \tempo 4 = 52
ees8 bes'16 aes g8 f16 ees f8 bes, r8 bes |
aes'16 g f ( ees) d8 aes' aes g r g |
f8 g16 aes bes8 c16 d ees,8 f16 g aes8 bes16 c |
d,8 ees16 f g8 aes16 bes c,8 d16 ees f8 g16 ees |
d4 ~ d16 bes ( a! bes) f'4 ~ f16 bes, ( a! bes) |
g'4 ~ g16 bes, ( a! bes) a'!4 ~ a16 f ( ees f) |
bes8 bes, r bes' bes16 ( aes) g ( f) ees ( d) c ( bes) |
c4.\trill bes8 bes4 r |
bes8 f'16 ees d8 c16 bes c8 f, r f |
ees'16 d c bes a!8 ees' ees\trill d r bes |
aes'16 g f ees d8 aes' aes\trill g r g |
c,8 d16 ees f8 g16 aes d,8 ees16 f g8 aes16 bes |
ees,8 f16 g aes8 bes16 c d,4 r8 d16 ees |
f d ( c bes) g' ( aes bes) g f8 bes, r8 d16 ees |
f d ( c bes) g' ( aes bes) g f8 bes, r8 f'16 bes |
g8 f16 ees d8. ees16 ees2\trill ~ |
ees1 |
ees1
}

violinOne = \relative ees'' {
  \time 4/4
ees16 g bes g ees g bes g d f bes f d f bes f |
d f aes f d f aes f ees g bes g ees g bes g |
f d bes' aes g f ees d g c, aes' g f ees d c |
f bes, g' f ees d c bes ees aes, f' ees d c bes a! |
d f bes f d f bes f d f bes f d f bes f |
ees g bes g ees g bes g f a! c a f a! c a |
d, f bes f d f bes f c f bes f c f bes f |
c f a! f c f a! c, bes d f d bes d f d |
bes d f d bes d f bes, a! c f c a! c f c |
a! c ees c a! c ees c d f bes f d f bes f |
d f aes f d f aes f ees g bes g ees g bes g |
ees aes ees aes f aes f aes f bes f bes g bes g bes |
g c g c aes c aes c d, f bes f d f bes f |
d f bes f ees g bes ees, d f bes f d f bes f |
d f bes f ees g bes ees, d f bes f d f bes f |
ees g bes ees, d f bes f ees g bes g ees g bes ees, |
bes ees g ees bes ees g ees g, bes ees bes g bes ees bes |
g1
}

violinTwo = \relative ees'' {
  \time 4/4
bes16 ees g ees bes ees g bes, bes d f d bes d f d |
bes d f d bes d f d bes ees g ees bes ees g bes, |
d aes' g f bes aes g f ees g f ees aes g f ees |
d f ees d g f ees d c ees d c f ees d c |
bes d f d bes d f d bes d f d bes d f d |
bes ees g ees bes ees g ees c f a! f c f a! c, |
bes d f d bes d f bes, bes c f c bes c f c |
a! c f c a! c f a, f bes d bes f bes d bes |
f bes d bes f bes d f, f a! c a f a! c a |
f a! c a f a! c a bes d f d bes d f d |
bes d f d bes d f d bes ees g ees bes ees g ees |
c ees c ees c f c f d f d f d g d g |
ees g ees g ees aes ees aes bes, d f d bes d f d |
bes d f d bes ees g bes, bes d f d bes d f d |
bes d f d bes ees g bes, bes d f d bes d f bes, |
bes ees g bes, bes d f d bes ees g ees bes ees g bes, |
g bes ees bes g bes ees bes ees, g bes g ees g bes g |
ees1
}

viola = \relative ees'' {
  \time 4/4
bes1 ~ | bes1 ~ | bes2. aes4 ~ | aes4 g2 f4 |
f2 ~ f4 bes4 | bes2 c4. a8 | f1 ~ | f1 ~ | f1 ~ | f1 ~ |
f4 bes4 bes2 | c2 d2 | ees,2 f2 | bes,1 ~ | bes1 ~ | bes1 ~ | bes1 ~ | bes1
}

cello = \relative ees {
  \time 4/4
ees8 ees ees ees bes bes bes bes | bes bes bes bes ees ees ees ees |
d d d d c c c c | bes bes bes bes aes aes a a |
bes bes bes bes bes bes bes bes | ees ees ees ees ees ees ees ees |
bes bes bes bes f f f f | f f f f bes bes bes bes |
bes bes bes bes f f f f | f f f f bes bes bes bes |
bes bes bes bes ees ees ees ees | aes, aes aes aes bes bes bes bes |
c c c c bes bes bes bes | bes bes bes bes bes bes bes bes |
bes bes bes bes bes bes bes bes | ees, ees bes' bes ees, ees ees ees |
ees ees ees ees ees ees ees ees | ees1
}

\score {
  <<
    \new Staff \solo
    \new Staff <<
      \new Voice \violinOne
      \new Voice \violinTwo
    >>
    \new Staff <<
      \new Voice \viola
      \new Voice \cello
    >>
  >>
}
