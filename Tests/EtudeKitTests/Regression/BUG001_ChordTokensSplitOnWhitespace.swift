import Testing
import EtudeKit

/// **BUG-001 — Chord tokens split on whitespace.**
///
/// *Symptom:* in the prototype, `<c e g>` came out as garbage — the tokenizer
/// split source text on whitespace, so a chord's inner pitches were torn into
/// fragments like `<c`, `e`, `g>` and re-glued by a fragile repair loop.
///
/// *Root cause:* whitespace is not a token boundary inside `<…>`; chords are a
/// structural unit whose delimiters happen to enclose spaces.
///
/// *Guard:* the tokenizer scans structurally — `<` and `>` are tokens in their
/// own right and the pitches between them tokenize exactly like pitches
/// anywhere else, whatever duration or ornament suffix follows the chord.
@Suite("BUG-001: chords tokenize structurally, never by whitespace split")
struct BUG001_ChordTokensSplitOnWhitespace {
    @Test("chord with every duration and ornament suffix", .tags(.regression), arguments: [
        ("<fis d b>2", DurationToken(2), [Token]()),
        ("<c e g>", nil, []),
        ("<d a fis d>2.", DurationToken(2, dots: 1), []),
        ("<d a>4", DurationToken(4), []),
        ("<c e g>2~", DurationToken(2), [.tie]),
        ("<c e g>4(", DurationToken(4), [.slurOpen]),
    ] as [(String, DurationToken?, [Token])])
    func chordSuffixes(source: String, duration: DurationToken?, trailing: [Token]) throws {
        let sut = makeSUT()
        let tokens = try sut.tokenize(source)
        #expect(tokens.first == .chordStart)
        #expect(tokens.dropLast(trailing.count).last == .chordEnd(duration: duration))
        #expect(Array(tokens.suffix(trailing.count)) == trailing)
        // Every token between the delimiters is a pitch — nothing was torn apart.
        let inner = tokens.dropFirst().prefix { $0 != .chordEnd(duration: duration) }
        #expect(inner.allSatisfy { if case .note = $0 { true } else { false } })
        #expect(!inner.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }
}
