import Testing
import EtudeKit

/// **BUG-005 — Polyphony wrapper glued to a pitch broke chord parsing.**
///
/// *Symptom:* in the Gnossienne source, a `<<` polyphony wrapper appears glued
/// directly to a pitch token — `<<af2` — and the prototype's tokenizer, seeing
/// `<`-prefixed text, treated the whole word as a malformed chord opening and
/// corrupted the voice structure that followed.
///
/// *Root cause:* structural markers and pitch tokens were separated by
/// whitespace assumptions, not by grammar.
///
/// *Guard:* `<<` is recognized as a marker wherever it appears; the pitch that
/// follows it tokenizes exactly as it would after whitespace. The test uses the
/// exact source fragment (PLAN.md §6).
@Suite("BUG-005: a parallel marker glued to a pitch stays two tokens")
struct BUG005_ParallelMarkerGluedToPitch {
    @Test("the exact Gnossienne fragment", .tags(.regression))
    func exactSourceFragment() throws {
        let sut = makeSUT()
        let fragment = #"\language "english" <<af2 \new Voice{\voiceOne \once \hideNotes af4 }>> af4"#
        #expect(try sut.tokenize(fragment) == [
            .command("language"),
            .string("english"),
            .parallelStart,
            .note(NoteToken(name: "af", duration: DurationToken(2))),
            .command("new"),
            .identifier("Voice"),
            .braceOpen,
            .command("voiceOne"),
            .command("once"),
            .command("hideNotes"),
            .note(NoteToken(name: "af", duration: DurationToken(4))),
            .braceClose,
            .parallelEnd,
            .note(NoteToken(name: "af", duration: DurationToken(4))),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
