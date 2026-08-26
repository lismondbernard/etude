import Testing
import EtudeKit

// The PieceBuilding seam (§0.3): the app's view models depend on this
// protocol, so these tests exert the consumer's design pressure on the
// concrete builder — and the corpus double proves no file system is needed.
@Suite("Build pieces through the seam")
struct BuildPiecesThroughSeamTests {
    private let piece = CorpusPiece(
        id: "tiny", title: "Tiny", composer: "Nobody",
        velocities: ["melody": 92])

    private func makeSUT(source: String) -> EnginePieceBuilder {
        EnginePieceBuilder(corpus: CorpusStub(source: source))
    }

    @Test("builds a piece to a validated score and its MIDI bytes", .tags(.unit))
    func buildsCleanPiece() async throws {
        let sut = makeSUT(source: """
            melody = { \\time 3/4 \\tempo 4 = 66 c'4 d' e' }
            \\score { \\new Staff \\melody }
            """)
        let built = try await sut.build(piece)

        #expect(built.score.voices.map(\.name) == ["melody"])
        #expect(built.score.voices[0].events.map(\.velocity) == [92, 92, 92])
        #expect(built.findings.isEmpty)
        let file = try SMFReader().read(built.midi)
        #expect(file.beatsPerMinute == 66)
        #expect(file.tracks.count == 2)
    }

    @Test("reports validator findings instead of throwing them", .tags(.unit))
    func reportsFindings() async throws {
        // A sub-audible register artifact: the app's Diagnostics screen needs
        // the findings AND the (still emitted) score.
        let sut = makeSUT(source: """
            melody = { c,,,4 }
            \\score { \\new Staff \\melody }
            """)
        let built = try await sut.build(piece)

        #expect(built.findings == [.registerViolation(voice: "melody", pitch: 12)])
        #expect(built.midi.isEmpty == false)
    }

    @Test("a tempo override restamps the emitted MIDI", .tags(.unit))
    func tempoOverride() async throws {
        let sut = makeSUT(source: """
            melody = { \\tempo 4 = 66 c'4 }
            \\score { \\new Staff \\melody }
            """)
        let built = try await sut.build(piece, tempoBeatsPerMinute: 100)

        #expect(built.score.tempo?.beatsPerMinute == 100)
        #expect(try SMFReader().read(built.midi).beatsPerMinute == 100)
    }

    @Test("a malformed source throws; nothing half-builds", .tags(.unit))
    func malformedSource() async throws {
        let sut = makeSUT(source: "melody = { <c e")
        await #expect(throws: (any Error).self) {
            try await sut.build(piece)
        }
    }

    // MARK: - Helpers

    private struct CorpusStub: CorpusProviding {
        let source: String
        func source(for piece: CorpusPiece) throws -> String { source }
    }
}
