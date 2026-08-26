import Testing
import Foundation
import EtudeKit

/// Phase 2 acceptance (PLAN.md §10): the vendored Satie sources resolve to
/// their known opening fingerprints and performed bar counts (Appendix B).
/// This is the whole pipeline — tokenizer → parser → resolver — against real,
/// messy music.
@Suite("Resolve corpus sources")
struct ResolveCorpusSourcesTests {
    @Test("the Gymnopédie resolves to its fingerprint and 78 bars", .tags(.acceptance))
    func gymnopedie() throws {
        let file = try parsedCorpusFile("gymnopedie-1.ly")

        let melody = try Resolver().resolve([file.definitions["melody"]!])
        // Opening melody F#5 A5 G5 F#5, after four empty bars and a rest.
        #expect(melody.notes.prefix(4).map(\.midiNote) == [78, 81, 79, 78])
        #expect(melody.meter == Meter(beats: 3, beatUnit: 4))
        #expect(melody.tempo == TempoMark(label: "Lent", beatUnit: 4, beatsPerMinute: 66))
        #expect(melody.barCount == 78)

        // Every voice spans the same 78 bars.
        let accompaniment = try Resolver().resolve([file.definitions["accompaniment"]!])
        let bass = try Resolver().resolve([file.definitions["bass"]!])
        #expect(accompaniment.totalTicks == melody.totalTicks)
        #expect(bass.totalTicks == melody.totalTicks)
        // The bass opens on the low G pedal.
        #expect(bass.notes.first?.midiNote == 43)
    }

    @Test("the Gnossienne resolves to its fingerprint and 82 bars", .tags(.acceptance))
    func gnossienne() throws {
        let file = try parsedCorpusFile("gnossienne-1.ly")

        let melody = try Resolver().resolve(
            [file.definitions["melody"]!], definitions: file.definitions)
        // Opening melody C5 Eb5 D5 C5 B4 — with the written grace C5 sounding
        // just ahead of the B.
        #expect(melody.notes.prefix(6).map(\.midiNote) == [72, 75, 74, 72, 72, 71])
        #expect(melody.meter == Meter(beats: 4, beatUnit: 4))
        #expect(melody.tempo == TempoMark(label: nil, beatUnit: 4, beatsPerMinute: 72))
        #expect(melody.barCount == 82)

        // Every voice spans the same 82 bars, low-F pedal included.
        for name in ["upperChords", "lowerChords", "bass"] {
            let voice = try Resolver().resolve(
                [file.definitions[name]!], definitions: file.definitions)
            #expect(voice.totalTicks == melody.totalTicks, "\(name) must fill all 82 bars")
        }
        let bass = try Resolver().resolve(
            [file.definitions["bass"]!], definitions: file.definitions)
        #expect(bass.notes.first?.midiNote == 41)
    }

    // MARK: - Helpers

    private func parsedCorpusFile(_ name: String) throws -> LilyFile {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name)
        let source = try String(contentsOf: url, encoding: .utf8)
        return try Parser().parseFile(try Tokenizer().tokenize(source))
    }
}
