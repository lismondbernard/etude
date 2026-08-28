import Foundation

/// Resolves the bundled SoundFont (issue #3): iOS ships no built-in sound
/// bank for `AVMIDIPlayer`, so the app carries its own — the CC0 "Upright
/// Piano KW" from the FreePats project (license + provenance ride in the
/// bundle beside it). Every corpus track renders as GM piano (the writer
/// emits no program changes), so one piano bank covers the whole library.
enum SoundBank {
    static var bundledPiano: URL? {
        Bundle.main.url(
            forResource: "UprightPianoKW-small-20190703", withExtension: "sf2")
    }
}

/// A missing bank must be a thrown, user-visible error — silence that
/// reports success is the failure mode this whole seam exists to prevent.
struct SoundBankMissingError: LocalizedError {
    let url: URL?
    var errorDescription: String? {
        "The piano sound bank is missing from the app bundle, so playback would be silent."
    }
}
