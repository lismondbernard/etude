import Foundation
import Observation
import EtudeKit

/// Piece Detail earns a view model (§0.9): async build state, playback, and
/// tempo interplay are logic worth testing against spies. It never sees
/// pipeline internals — only the `PieceBuilding` seam.
@MainActor
@Observable
final class PieceDetailViewModel {
    enum BuildPhase: Equatable {
        case idle
        case building
        case built
        case failed(String)
    }

    let piece: CorpusPiece
    private let builder: any PieceBuilding
    private let player: any MIDIPlaying

    private(set) var phase: BuildPhase = .idle
    private(set) var builtPiece: BuiltPiece?
    /// Mirrored from the player as a STORED property so SwiftUI observes it —
    /// the player itself is behind a protocol and invisible to Observation
    /// (a bug the UI tests caught that the unit tests could not).
    private(set) var isPlaying = false
    /// Nil until the user moves the slider — the piece's own tempo governs.
    private(set) var tempoOverride: Int?

    init(piece: CorpusPiece, builder: any PieceBuilding, player: any MIDIPlaying) {
        self.piece = piece
        self.builder = builder
        self.player = player
    }

    var tracks: [Voice] { builtPiece?.score.voices ?? [] }
    var findings: [ValidationFinding] { builtPiece?.findings ?? [] }
    var canPlay: Bool { phase == .built }
    var tempoBeatsPerMinute: Int {
        tempoOverride ?? builtPiece?.score.tempo?.beatsPerMinute ?? 120
    }

    func build() async {
        phase = .building
        player.pause()
        isPlaying = false
        do {
            let built = try await builder.build(piece, tempoBeatsPerMinute: tempoOverride)
            builtPiece = built
            try player.load(Data(built.midi))
            phase = .built
        } catch {
            builtPiece = nil
            phase = .failed("\(error)")
        }
    }

    func togglePlayback() {
        guard canPlay else { return }
        isPlaying ? player.pause() : player.play()
        isPlaying = player.isPlaying
    }

    /// The tempo slider commits here: remember the override and rebuild the
    /// MIDI at the new speed (PLAN.md §8).
    func applyTempo(_ beatsPerMinute: Int) async {
        tempoOverride = beatsPerMinute
        guard builtPiece != nil else { return }
        await build()
    }

    /// Writes the built MIDI beside the temp dir for `ShareLink`.
    func exportURL() throws -> URL {
        guard let builtPiece else {
            throw CocoaError(.fileNoSuchFile)
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(piece.id).mid")
        try Data(builtPiece.midi).write(to: url)
        return url
    }
}
