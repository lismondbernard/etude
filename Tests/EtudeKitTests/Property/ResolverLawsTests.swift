import Testing
import EtudeKit

/// The resolver's octave laws (PLAN.md §4.3), pinned as properties over
/// seeded random note walks. The third law — unfold is n identical copies —
/// lives with its regression story in BUG002.
@Suite("Resolver laws")
struct ResolverLawsTests {
    @Test("transposing the anchor an octave transposes every note twelve", .tags(.property))
    func anchorTransposition() throws {
        var random = SeededRandom(seed: 0xA11)
        for _ in 0..<50 {
            let body = randomWalk(using: &random)
            for shift in [-2, -1, 1, 2] {
                let base = try Resolver().resolve([
                    .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: body),
                ])
                let transposed = try Resolver().resolve([
                    .relative(anchor: NoteToken(name: "c", octaveMarks: 1 + shift), body: body),
                ])
                #expect(transposed.notes.map(\.midiNote) == base.notes.map { $0.midiNote + 12 * shift },
                        "seed 0xA11 — resolve∘transpose must equal transpose∘resolve")
            }
        }
    }

    // MARK: - Helpers

    private func randomWalk(using random: inout SeededRandom) -> [MusicNode] {
        let names = ["c", "d", "e", "f", "g", "a", "b", "fis", "cis", "bes", "aes"]
        return (0..<Int.random(in: 2...10, using: &random)).map { _ in
            note(names.randomElement(using: &random)!,
                 marks: Int.random(in: -1...1, using: &random),
                 dur([2, 4, 8].randomElement(using: &random)!))
        }
    }
}
