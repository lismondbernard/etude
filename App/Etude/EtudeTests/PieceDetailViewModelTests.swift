import XCTest
import EtudeKit
@testable import Etude

@MainActor
final class PieceDetailViewModelTests: XCTestCase {
    func testBuildExposesTracksAndLoadsThePlayer() async {
        let (sut, builder, player) = makeSUT()
        builder.stub(voiceNames: ["melody", "bass"])

        await sut.build()

        XCTAssertEqual(sut.phase, .built)
        XCTAssertEqual(sut.tracks.map(\.name), ["melody", "bass"])
        XCTAssertTrue(sut.canPlay)
        XCTAssertEqual(player.loadedData?.isEmpty, false)
        XCTAssertEqual(builder.requests.count, 1)
    }

    func testBuildFailureIsPresentedNotSwallowed() async {
        let (sut, builder, _) = makeSUT()
        builder.stubbedError = StubError.broken

        await sut.build()

        guard case .failed(let message) = sut.phase else {
            return XCTFail("expected .failed, got \(sut.phase)")
        }
        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(sut.canPlay)
        XCTAssertTrue(sut.tracks.isEmpty)
    }

    func testFindingsSurfaceFromTheBuild() async {
        let (sut, builder, _) = makeSUT()
        builder.stub(voiceNames: ["lhDown"],
                     findings: [.registerViolation(voice: "lhDown", pitch: 13)])

        await sut.build()

        XCTAssertEqual(sut.findings, [.registerViolation(voice: "lhDown", pitch: 13)])
        XCTAssertEqual(sut.phase, .built, "findings are honesty, not failure")
    }

    func testTogglePlaybackDrivesThePlayer() async {
        let (sut, builder, player) = makeSUT()
        builder.stub(voiceNames: ["melody"])
        await sut.build()

        sut.togglePlayback()
        XCTAssertTrue(player.isPlaying)
        XCTAssertTrue(sut.isPlaying)

        sut.togglePlayback()
        XCTAssertFalse(player.isPlaying)
    }

    func testPlaybackNeedsABuild() {
        let (sut, _, player) = makeSUT()
        sut.togglePlayback()
        XCTAssertFalse(player.isPlaying)
    }

    func testApplyingATempoRebuildsAtTheOverride() async {
        let (sut, builder, _) = makeSUT()
        builder.stub(voiceNames: ["melody"])
        await sut.build()

        await sut.applyTempo(100)

        XCTAssertEqual(builder.requests.map(\.tempo), [nil, 100])
        XCTAssertEqual(sut.tempoBeatsPerMinute, 100)
    }

    func testExportWritesTheBuiltMIDI() async throws {
        let (sut, builder, _) = makeSUT()
        builder.stub(voiceNames: ["melody"])
        await sut.build()

        let url = try sut.exportURL()

        XCTAssertEqual(try Data(contentsOf: url), Data(builder.stubbedMIDI))
        XCTAssertEqual(url.pathExtension, "mid")
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath, line: UInt = #line
    ) -> (PieceDetailViewModel, BuilderSpy, PlayerSpy) {
        let builder = BuilderSpy()
        let player = PlayerSpy()
        let sut = PieceDetailViewModel(
            piece: CorpusPiece(id: "tiny", title: "Tiny", composer: "Nobody"),
            builder: builder, player: player)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(builder, file: file, line: line)
        trackForMemoryLeaks(player, file: file, line: line)
        return (sut, builder, player)
    }

    private enum StubError: Error { case broken }

    @MainActor
    private final class BuilderSpy: PieceBuilding {
        private(set) var requests: [(piece: CorpusPiece, tempo: Int?)] = []
        var stubbedError: Error?
        var stubbedMIDI: [UInt8] = [0x4D, 0x54, 0x68, 0x64]
        private var stubbedScore = Score(title: "Tiny", tempo: nil, meter: nil, voices: [])
        private var stubbedFindings: [ValidationFinding] = []

        func stub(voiceNames: [String], findings: [ValidationFinding] = []) {
            stubbedScore = Score(
                title: "Tiny",
                tempo: TempoMark(label: nil, beatUnit: 4, beatsPerMinute: 66),
                meter: nil,
                voices: voiceNames.map { Voice(name: $0, events: [], totalTicks: 0) })
            stubbedFindings = findings
        }

        func build(_ piece: CorpusPiece, tempoBeatsPerMinute: Int?) async throws -> BuiltPiece {
            requests.append((piece, tempoBeatsPerMinute))
            if let stubbedError { throw stubbedError }
            var score = stubbedScore
            if let tempoBeatsPerMinute {
                score = Score(title: score.title,
                              tempo: TempoMark(label: nil, beatUnit: 4,
                                               beatsPerMinute: tempoBeatsPerMinute),
                              meter: score.meter, voices: score.voices)
            }
            return BuiltPiece(score: score, midi: stubbedMIDI, findings: stubbedFindings)
        }
    }

    @MainActor
    private final class PlayerSpy: MIDIPlaying {
        private(set) var isPlaying = false
        private(set) var loadedData: Data?

        func load(_ midi: Data) throws { loadedData = midi }
        func play() { isPlaying = true }
        func pause() { isPlaying = false }
    }
}
