/// Étude — a LilyPond→MIDI engine that doubles as a software-testing curriculum.
///
/// This module is intentionally free of any UIKit/SwiftUI import: it is a pure
/// value-oriented pipeline (Tokenizer → Parser → Resolver → Model/Validator → MIDI)
/// so its tests run fast on any platform with no simulator. The SwiftUI app under
/// `App/Etude` is a thin shell over this package.
///
/// See `PLAN.md` for the phased build plan. Phase 0 (this scaffold) establishes the
/// package, docs, corpus, and CI; later phases fill in the layers test-first.
public enum Etude {
    /// Semantic version of the engine, surfaced in the app's credits screen.
    public static let version = "0.0.0"
}
