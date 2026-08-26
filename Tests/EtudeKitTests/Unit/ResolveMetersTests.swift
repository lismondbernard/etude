import Testing
import EtudeKit

@Suite("Resolve meters")
struct ResolveMetersTests {
    @Test("captures the time signature and counts bars", .tags(.unit))
    func meterAndBarCount() throws {
        let resolved = try makeSUT().resolve([
            .meter(beats: 3, beatUnit: 4),
            note("c", dur(2, dots: 1)), note("d", dur(2, dots: 1)),
        ])
        #expect(resolved.meter == Meter(beats: 3, beatUnit: 4))
        #expect(resolved.barCount == 2)
    }

    @Test("a partial final bar still counts as a bar", .tags(.unit))
    func partialFinalBar() throws {
        let resolved = try makeSUT().resolve([
            .meter(beats: 4, beatUnit: 4),
            note("c", dur(1)), note("d", dur(4)),
        ])
        #expect(resolved.barCount == 2)
    }

    @Test("without a meter there is no bar count", .tags(.unit))
    func noMeter() throws {
        let resolved = try makeSUT().resolve([note("c", dur(4))])
        #expect(resolved.meter == nil)
        #expect(resolved.barCount == nil)
    }

    @Test("captures the tempo mark", .tags(.unit))
    func tempoMark() throws {
        // Verbatim shape from the Gymnopédie: `\tempo "Lent" 4 = 66`
        let resolved = try makeSUT().resolve([
            .tempo(label: "Lent", beatUnit: 4, beatsPerMinute: 66),
            note("c", dur(4)),
        ])
        #expect(resolved.tempo == TempoMark(label: "Lent", beatUnit: 4, beatsPerMinute: 66))
    }

    @Test("the first tempo mark governs the piece", .tags(.unit))
    func firstTempoGoverns() throws {
        // Clair de Lune writes "Andante très expressif" at the top and
        // "a Tempo 1º" mid-piece; the piece's tempo is the opening one.
        let resolved = try makeSUT().resolve([
            .tempo(label: "Andante", beatUnit: nil, beatsPerMinute: nil),
            note("c", dur(4)),
            .tempo(label: "a Tempo", beatUnit: nil, beatsPerMinute: nil),
        ])
        #expect(resolved.tempo == TempoMark(label: "Andante", beatUnit: nil, beatsPerMinute: nil))
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
