import AVFoundation
import Foundation

/// The playback seam: the view model talks to this, tests talk to a spy, and
/// UI tests swap in the silent player via the `-uiTesting` launch argument.
@MainActor
protocol MIDIPlaying: AnyObject {
    var isPlaying: Bool { get }
    /// Called when the piece plays through to its end, never on `pause()`.
    var onFinish: (@MainActor () -> Void)? { get set }
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
    /// AVMIDIPlayer runs the completion on `stop()` too, not only at the end:
    /// counting plays and pauses lets a stale completion be recognized.
    private var playback = 0
    var onFinish: (@MainActor () -> Void)?

    init(soundBankURL: URL?) {
        self.soundBankURL = soundBankURL
    }

    var isPlaying: Bool { player?.isPlaying ?? false }

    func load(_ midi: Data) throws {
        guard let soundBankURL,
              FileManager.default.fileExists(atPath: soundBankURL.path) else {
            throw SoundBankMissingError(url: soundBankURL)
        }
        // .playback, not the default .soloAmbient: audition must survive the
        // ring/silent switch (issue #3's second cause).
        try AVAudioSession.sharedInstance().setCategory(.playback)
        player = try AVMIDIPlayer(data: midi, soundBankURL: soundBankURL)
        player?.prepareToPlay()
    }

    func play() {
        playback += 1
        let started = playback
        // AVMIDIPlayer calls back on its own queue, so the closure is
        // @Sendable and hops to the main actor before touching anything.
        player?.play { @Sendable [weak self] in
            Task { @MainActor in self?.didFinish(started) }
        }
    }

    func pause() {
        playback += 1
        player?.stop()
    }

    private func didFinish(_ started: Int) {
        guard started == playback else { return }
        // At the end of the file a resumed play would play nothing.
        player?.currentPosition = 0
        onFinish?()
    }
}

/// No audio hardware, no timing: the `-uiTesting` player. It still keeps the
/// play/pause state machine honest so the UI can be exercised.
@MainActor
final class SilentMIDIPlayer: MIDIPlaying {
    private(set) var isPlaying = false
    var onFinish: (@MainActor () -> Void)?
    func load(_ midi: Data) throws {}
    func play() { isPlaying = true }
    func pause() { isPlaying = false }
}
