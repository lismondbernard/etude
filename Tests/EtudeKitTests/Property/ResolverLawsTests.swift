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

    @Test("a raising mark then a lowering mark restores the walk", .tags(.property))
    func octaveMarksAreInverses() throws {
        var random = SeededRandom(seed: 0xC11)
        for _ in 0..<50 {
            let body = randomWalk(using: &random)
            let position = Int.random(in: 0..<body.count, using: &random)

            // Raise note `position` an octave and lower its successor back.
            var altered = body
            altered[position] = shifted(altered[position], by: 1)
            if position + 1 < altered.count {
                altered[position + 1] = shifted(altered[position + 1], by: -1)
            }

            let base = try Resolver().resolve([
                .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: body),
            ])
            let raised = try Resolver().resolve([
                .relative(anchor: NoteToken(name: "c", octaveMarks: 1), body: altered),
            ])

            var expected = base.notes.map(\.midiNote)
            expected[position] += 12
            #expect(raised.notes.map(\.midiNote) == expected,
                    "seed 0xC11 — `'` then `,` must restore every later pitch")
        }
    }

    // MARK: - Helpers

    private func shifted(_ node: MusicNode, by octaves: Int) -> MusicNode {
        guard case .note(let noteToken, let tied) = node else { return node }
        return .note(NoteToken(name: noteToken.name,
                               octaveMarks: noteToken.octaveMarks + octaves,
                               duration: noteToken.duration),
                     tied: tied)
    }

    private func randomWalk(using random: inout SeededRandom) -> [MusicNode] {
        let names = ["c", "d", "e", "f", "g", "a", "b", "fis", "cis", "bes", "aes"]
        return (0..<Int.random(in: 2...10, using: &random)).map { _ in
            note(names.randomElement(using: &random)!,
                 marks: Int.random(in: -1...1, using: &random),
                 dur([2, 4, 8].randomElement(using: &random)!))
        }
    }
}
