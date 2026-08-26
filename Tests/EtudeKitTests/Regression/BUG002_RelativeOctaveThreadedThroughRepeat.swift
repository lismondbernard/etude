import Testing
import EtudeKit

/// **BUG-002 — Relative octave threaded through `\repeat unfold`.**
///
/// *Symptom:* the Gnossienne's bass pedal `\repeat unfold 6 { f,1 | }` spiraled
/// F2→F1→F0 across repetitions — each pass re-applied the `,` mark to the
/// context left by the previous pass, marching the pedal into the sub-audible.
///
/// *Root cause:* the prototype resolved the repeat by re-walking the body text
/// per pass, threading the relative context through every repetition.
///
/// *Guard:* the resolver resolves the body ONCE and copies the resolved
/// events; a property test pins the law that `unfold n` is n identical copies
/// (PLAN.md §6).
@Suite("BUG-002: relative octave threaded through repeat")
struct BUG002_RelativeOctaveThreadedThroughRepeat {
    @Test("the exact Gnossienne bass fragment holds its pedal", .tags(.regression))
    func exactSourceFragment() throws {
        let source = "\\language \"english\" \\relative { \\repeat unfold 6 { f,1 | } c'1 | f,1 | f1 | }"
        let music = try Parser().parseMusic(try Tokenizer().tokenize(source))
        let resolved = try Resolver().resolve(music)

        // Six identical F2 pedal bars — no spiral — then C3, F2, F2.
        #expect(resolved.notes.map(\.midiNote) == [41, 41, 41, 41, 41, 41, 48, 41, 41])
    }

    @Test("unfold n is n identical copies of the resolved body", .tags(.property))
    func unfoldLaw() throws {
        var random = SeededRandom(seed: 0xB002)
        let names = ["c", "d", "e", "f", "g", "a", "b", "fis", "bes"]
        for _ in 0..<50 {
            let body: [MusicNode] = (0..<Int.random(in: 1...6, using: &random)).map { _ in
                note(names.randomElement(using: &random)!,
                     marks: Int.random(in: -1...1, using: &random),
                     dur([1, 2, 4, 8].randomElement(using: &random)!))
            }
            let count = Int.random(in: 2...5, using: &random)

            let onePass = try Resolver().resolve([
                .relative(anchor: NoteToken(name: "c"), body: body),
            ])
            let unfolded = try Resolver().resolve([
                .relative(anchor: NoteToken(name: "c"),
                          body: [.repeated(.unfold, count: count, body: body, alternatives: [])]),
            ])

            #expect(unfolded.totalTicks == count * onePass.totalTicks)
            let copies = (0..<count).flatMap { pass in
                onePass.notes.map {
                    ResolvedNote(midiNote: $0.midiNote,
                                 startTick: $0.startTick + pass * onePass.totalTicks,
                                 durationTicks: $0.durationTicks)
                }
            }
            #expect(unfolded.notes == copies, "seed 0xB002 — copies must be pairwise identical")
        }
    }
}
