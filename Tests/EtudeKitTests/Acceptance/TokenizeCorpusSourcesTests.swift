import Testing
import Foundation
import EtudeKit

/// Phase 1 acceptance (PLAN.md §10): the vendored Satie sources tokenize
/// end-to-end without error. Deeper fingerprints (bar counts, opening pitches)
/// belong to the Resolver and the Phase 4 acceptance suite — here we assert
/// only lexical health: the stream is non-trivial, structurally balanced, and
/// contains the landmarks each source is known for.
@Suite("Tokenize corpus sources")
struct TokenizeCorpusSourcesTests {
    @Test("tokenizes the Gymnopédie source end-to-end", .tags(.acceptance))
    func gymnopedie() throws {
        let tokens = try makeSUT().tokenize(try corpusSource("gymnopedie-1.ly"))
        #expect(tokens.count > 400)
        #expect(tokens.contains(.command("relative")))
        #expect(tokens.contains(.command("alternative")))
        // The opening melody's first sounding pitch.
        #expect(tokens.contains(.note(NoteToken(name: "fis"))))
        #expect(chordBalance(of: tokens))
    }

    @Test("tokenizes the Gnossienne source end-to-end", .tags(.acceptance))
    func gnossienne() throws {
        let tokens = try makeSUT().tokenize(try corpusSource("gnossienne-1.ly"))
        #expect(tokens.count > 300)
        #expect(tokens.contains(.string("english")))
        // English pitches only exist if the language switch took effect —
        // including the BUG-005 fragment's glued `<<af2`.
        #expect(tokens.contains(.note(NoteToken(name: "af", duration: DurationToken(2)))))
        #expect(tokens.contains(.chordRepeat(duration: DurationToken(4))))
        #expect(tokens.contains(.command("crossStaff")))
        #expect(chordBalance(of: tokens))
    }

    // MARK: - Helpers

    private func makeSUT() -> Tokenizer { Tokenizer() }

    private func chordBalance(of tokens: [Token]) -> Bool {
        let starts = tokens.count(where: { $0 == .chordStart })
        let ends = tokens.count(where: { if case .chordEnd = $0 { true } else { false } })
        return starts == ends && starts > 0
    }

    /// Corpus files are read from the repo checkout relative to this file —
    /// they are sources under test, not bundle resources like golden fixtures.
    private func corpusSource(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // this file
            .deletingLastPathComponent() // Acceptance/
            .deletingLastPathComponent() // EtudeKitTests/
            .deletingLastPathComponent() // Tests/
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
