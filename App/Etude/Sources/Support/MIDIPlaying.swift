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
@MainActor
final class SystemMIDIPlayer: MIDIPlaying {
    private var player: AVMIDIPlayer?

    var isPlaying: Bool { player?.isPlaying ?? false }

    func load(_ midi: Data) throws {
        player = try AVMIDIPlayer(data: midi, soundBankURL: nil)
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
