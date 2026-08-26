import Testing
import EtudeKit

@Suite("Parse meter and tempo")
struct ParseMeterAndTempoTests {
    @Test("parses a time signature into a meter node", .tags(.unit))
    func timeSignature() throws {
        #expect(try makeSUT().parseMusic(tokens("\\time 3/4 c")) == [
            .meter(beats: 3, beatUnit: 4),
            note("c"),
        ])
    }

    @Test("parses a tempo with label, beat unit, and speed", .tags(.unit))
    func fullTempo() throws {
        // Verbatim shape from the Gymnopédie: `\tempo "Lent" 4 = 66`
        #expect(try makeSUT().parseMusic(tokens("\\tempo \"Lent\" 4 = 66")) == [
            .tempo(label: "Lent", beatUnit: 4, beatsPerMinute: 66),
        ])
    }

    @Test("parses a tempo with no label", .tags(.unit))
    func unlabeledTempo() throws {
        // Verbatim shape from the Gnossienne: `\tempo 4 = 72`
        #expect(try makeSUT().parseMusic(tokens("\\tempo 4 = 72")) == [
            .tempo(label: nil, beatUnit: 4, beatsPerMinute: 72),
        ])
    }

    @Test("parses a tempo that is only a label", .tags(.unit))
    func labelOnlyTempo() throws {
        // Verbatim shape from Clair de Lune: `\tempo"Andante très expressif"`
        #expect(try makeSUT().parseMusic(tokens("\\tempo \"Andante très expressif\" c")) == [
            .tempo(label: "Andante très expressif", beatUnit: nil, beatsPerMinute: nil),
            note("c"),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
