import Testing
import EtudeKit

/// **BUG-004 — Sub-audible octave-0 bass in the Gymnopédie ending.**
///
/// *Symptom:* the bass ending bar `<< {c'\rest b e} e,2. >>` drifted the
/// relative context an octave per pass, marching the closing chords toward
/// octave 0. The prototype **clamped** pitches below C2 back into range
/// (`clamp(ev, lo=36)` in music/gymnopedie.py), so the output "sounded roughly
/// fine" and the resolver bug stayed hidden until noticed by ear.
///
/// *Root cause:* defensive repair where an invariant belonged (ADR-0001).
///
/// *Guard:* two halves. The resolver places the reconstructed figure correctly
/// under LilyPond's parallel rule; and when a register artifact does appear,
/// the pipeline throws a finding — there is no clamp to hide behind.
@Suite("BUG-004: clamped sub-audible bass")
struct BUG004_ClampedSubAudibleBass {
    @Test("the reconstructed ending figure keeps its bass at E2", .tags(.regression))
    func exactEndingFigure() throws {
        // Bass context, then the original (unreduced) bar: an upper voicelet
        // parallel to the sustained low e.
        let source = "\\relative c { e2. << { c'4\\rest b4 e4 } { e,2. } >> <g a,>2. <d a d,>2. }"
        let music = try Parser().parseMusic(try Tokenizer().tokenize(source))
        let resolved = try Resolver().resolve(music)

        // e (E3), voicelet b/e, sustained E2 — and the closing chords place
        // from the voicelet's E4, all comfortably above the audible floor.
        #expect(resolved.notes.map(\.midiNote) == [52, 59, 64, 40, 67, 57, 62, 57, 50])
        #expect(resolved.notes.allSatisfy { $0.midiNote >= 21 })
    }

    @Test("a drifted sub-audible register throws; nothing clamps it", .tags(.regression))
    func driftThrowsInsteadOfClamping() throws {
        // The drifted shape the prototype used to clamp: the same figure
        // spiralled two octaves low.
        let source = """
            bass = \\relative c,,, { e2. <g a,>2. <d a d,>2. }
            \\score { \\new Staff \\bass }
            """
        let file = try Parser().parseFile(try Tokenizer().tokenize(source))
        let score = try ScoreBuilder().score(from: file)

        #expect(throws: ValidationError(findings: [
            .registerViolation(voice: "bass", pitch: 16),
            .registerViolation(voice: "bass", pitch: 19),
            .registerViolation(voice: "bass", pitch: 9),
            .registerViolation(voice: "bass", pitch: 14),
            .registerViolation(voice: "bass", pitch: 2),
        ])) {
            try Validator().validate(score)
        }
    }
}
