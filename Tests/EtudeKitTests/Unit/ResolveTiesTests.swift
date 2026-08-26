import Testing
import EtudeKit

@Suite("Resolve ties")
struct ResolveTiesTests {
    @Test("merges a tied note into one sounding event", .tags(.unit))
    func mergesTiedPair() throws {
        // Verbatim shape from the Gymnopédie melody: `fis2.~ fis2.`
        let resolved = try makeSUT().resolve([
            note("fis", dur(2, dots: 1), tied: true),
            note("fis", dur(2, dots: 1)),
        ])
        #expect(resolved.notes == [ResolvedNote(midiNote: 54, startTick: 0, durationTicks: 2880)])
        #expect(resolved.totalTicks == 2880)
    }

    @Test("a tie chain merges across different written durations", .tags(.unit))
    func tieChain() throws {
        // Verbatim shape from the Gnossienne: `f4 ~ f2 ~ f1`
        let resolved = try makeSUT().resolve([
            note("f", dur(4), tied: true),
            note("f", dur(2), tied: true),
            note("f", dur(1)),
        ])
        #expect(resolved.notes == [ResolvedNote(midiNote: 53, startTick: 0, durationTicks: 480 + 960 + 1920)])
    }

    @Test("a tie to a different pitch does not merge", .tags(.unit))
    func differentPitchDoesNotMerge() throws {
        let resolved = try makeSUT().resolve([
            note("c", dur(4), tied: true),
            note("d", dur(4)),
        ])
        #expect(resolved.notes.count == 2)
        #expect(resolved.notes.map(\.durationTicks) == [480, 480])
    }

    @Test("tied chords merge note-for-note", .tags(.unit))
    func tiedChords() throws {
        // Verbatim shape from Clair de Lune: `<f af>\( <f' af> ~ <f af> 4.`
        let resolved = try makeSUT().resolve([
            .chord([NoteToken(name: "f"), NoteToken(name: "a")], duration: dur(2), tied: true),
            .chord([NoteToken(name: "f"), NoteToken(name: "a")], duration: dur(4), tied: false),
        ])
        #expect(resolved.notes == [
            ResolvedNote(midiNote: 53, startTick: 0, durationTicks: 1440),
            ResolvedNote(midiNote: 57, startTick: 0, durationTicks: 1440),
        ])
        #expect(resolved.totalTicks == 1440)
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
