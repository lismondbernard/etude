import Testing
import Foundation
import EtudeKit

/// The repo carries Clair de Lune twice: the compact `\parallelMusic` source
/// and a hand-checked expanded copy (prototype-era, voices written out with
/// per-section anchors). Resolving BOTH through the pipeline and demanding
/// note-for-note agreement corroborates the ParallelMusicExpander with an
/// independently-derived witness — this is the check that exposed the
/// vendored source's wrong lhDown anchor.
@Suite("Clair de Lune sources agree")
struct ClairDeLuneSourcesAgreeTests {
    @Test("the compact and expanded sources resolve identically", .tags(.acceptance))
    func sourcesAgree() throws {
        let compact = try parse("clair-de-lune.ly")
        let expanded = try parse("clair-de-lune.expanded.ly")

        let compactVoices = try ["rhUp", "rhDown", "lhUp", "lhDown"].map {
            try Resolver().resolve([compact.definitions[$0]!], definitions: compact.definitions)
        }

        // The expanded score inlines 4 voices × 7 sections, voice-major.
        let blocks = inlineRelativeBlocks(in: try #require(expanded.score))
        #expect(blocks.count == 28)
        for (voiceIndex, voice) in compactVoices.enumerated() {
            var notes: [ResolvedNote] = []
            var offset = 0
            for section in 0..<7 {
                let resolved = try Resolver().resolve(
                    [blocks[voiceIndex * 7 + section]], definitions: expanded.definitions)
                notes += resolved.notes.map {
                    ResolvedNote(midiNote: $0.midiNote, startTick: $0.startTick + offset,
                                 durationTicks: $0.durationTicks)
                }
                offset += resolved.totalTicks
            }
            #expect(notes == voice.notes)
            #expect(offset == voice.totalTicks)
        }
    }

    // MARK: - Helpers

    private func parse(_ name: String) throws -> LilyFile {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name)
        return try Parser().parseFile(try Tokenizer().tokenize(String(contentsOf: url, encoding: .utf8)))
    }

    private func inlineRelativeBlocks(in node: MusicNode) -> [MusicNode] {
        switch node {
        case .relative: [node]
        case .sequence(let body): body.flatMap(inlineRelativeBlocks(in:))
        case .parallel(let children): children.flatMap(inlineRelativeBlocks(in:))
        case .context(_, let body): inlineRelativeBlocks(in: body)
        default: []
        }
    }
}
