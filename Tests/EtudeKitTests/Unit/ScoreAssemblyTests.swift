import Testing
import EtudeKit

@Suite("Score assembly")
struct ScoreAssemblyTests {
    // A miniature two-staff file in the corpus's shape.
    private func makeFile() throws -> LilyFile {
        try Parser().parseFile(Tokenizer().tokenize("""
            \\header { title = "Tiny Piece" }
            melody = \\relative c'' { \\time 3/4 \\tempo 4 = 66 fis4 a g }
            bass = \\relative c { \\time 3/4 g2. }
            \\score { << \\new Staff \\melody \\new Staff \\bass >> }
            """))
    }

    @Test("assembles one voice per referenced definition, in score order", .tags(.unit))
    func voicesFromScoreBlock() throws {
        let score = try makeSUT().score(from: makeFile())

        #expect(score.title == "Tiny Piece")
        #expect(score.voices.map(\.name) == ["melody", "bass"])
        #expect(score.voices[0].events.map(\.pitch) == [78, 81, 79])
        #expect(score.voices[1].events.map(\.pitch) == [43])
        #expect(score.voices.map(\.totalTicks) == [1440, 1440])
    }

    @Test("carries tempo and meter from the voices into the score", .tags(.unit))
    func tempoAndMeter() throws {
        let score = try makeSUT().score(from: makeFile())
        #expect(score.meter == Meter(beats: 3, beatUnit: 4))
        #expect(score.tempo == TempoMark(label: nil, beatUnit: 4, beatsPerMinute: 66))
    }

    @Test("applies per-voice velocities, defaulting the rest", .tags(.unit))
    func velocities() throws {
        let score = try makeSUT().score(from: makeFile(), velocities: ["melody": 92])
        #expect(score.voices[0].events.map(\.velocity) == [92, 92, 92])
        #expect(score.voices[1].events.map(\.velocity) == [80])
    }

    @Test("delivers a typed error when the file has no score block", .tags(.unit))
    func missingScore() throws {
        let file = try Parser().parseFile(Tokenizer().tokenize("melody = { c }"))
        #expect(throws: ScoreBuildError.missingScoreBlock) {
            try makeSUT().score(from: file)
        }
    }

    @Test("delivers a typed error on a pitch outside the MIDI range", .tags(.unit))
    func pitchOutOfRange() throws {
        let file = try Parser().parseFile(Tokenizer().tokenize("""
            deep = { c,,,,,4 }
            \\score { \\new Staff \\deep }
            """))
        #expect(throws: ScoreBuildError.pitchOutOfMIDIRange(voice: "deep", midi: -12)) {
            try makeSUT().score(from: file)
        }
    }

    @Test("assembles explicitly named voices when a file has no score block", .tags(.unit))
    func namedVoices() throws {
        // Clair de Lune's vendored source defines its four voices but carries
        // no score assembly.
        let file = try Parser().parseFile(Tokenizer().tokenize(
            "melody = { c4 } bass = { e,4 }"))
        let score = try makeSUT().score(
            from: file, voices: ["melody", "bass"], title: "Nameless")

        #expect(score.title == "Nameless")
        #expect(score.voices.map(\.name) == ["melody", "bass"])
        #expect(score.voices.map(\.totalTicks) == [480, 480])
    }

    @Test("assumes a tempo when the mark has no metronome number", .tags(.unit))
    func assumedTempo() throws {
        // Clair's `\tempo"Andante très expressif"` names a feel, not a number.
        let file = try Parser().parseFile(Tokenizer().tokenize(
            "melody = { \\tempo \"Andante\" c4 }"))
        let score = try makeSUT().score(
            from: file, voices: ["melody"], title: "", assumingBeatsPerMinute: 60)

        #expect(score.tempo == TempoMark(label: "Andante", beatUnit: 4, beatsPerMinute: 60))
    }

    // MARK: - Helpers

    private func makeSUT() -> ScoreBuilder { ScoreBuilder() }
}
