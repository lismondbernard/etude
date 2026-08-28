import AVFoundation
import Foundation

/// The playback seam: the view model talks to this, tests talk to a spy, and
/// UI tests swap in the silent player via the `-uiTesting` launch argument.
@MainActor
protocol MIDIPlaying: AnyObject {
    var isPlaying: Bool { get }
    func load(_ midi: Data) throws
    func play()
    func pause()
}

/// `AVMIDIPlayer` behind the seam. AVMIDIPlayer has no pause; stopping keeps
/// `currentPosition`, so play-after-pause resumes where it left off.
///
/// The player REQUIRES a sound bank: on iOS a nil `soundBankURL` renders
/// silence while reporting success (issue #3) — the worst kind of failure,
/// so a missing bank throws out of `load` instead.
@MainActor
final class SystemMIDIPlayer: MIDIPlaying {
    private let soundBankURL: URL?
    private var player: AVMIDIPlayer?

    init(soundBankURL: URL?) {
        self.soundBankURL = soundBankURL
    }

    var isPlaying: Bool { player?.isPlaying ?? false }

    func load(_ midi: Data) throws {
        guard let soundBankURL,
              FileManager.default.fileExists(atPath: soundBankURL.path) else {
            throw SoundBankMissingError(url: soundBankURL)
        }
        player = try AVMIDIPlayer(data: midi, soundBankURL: soundBankURL)
        player?.prepareToPlay()
    }

    func play() { player?.play(nil) }
    func pause() { player?.stop() }
}

/// No audio hardware, no timing: the `-uiTesting` player. It still keeps the
/// play/pause state machine honest so the UI can be exercised.
@MainActor
final class SilentMIDIPlayer: MIDIPlaying {
    private(set) var isPlaying = false
    func load(_ midi: Data) throws {}
    func play() { isPlaying = true }
    func pause() { isPlaying = false }
}
