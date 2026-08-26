import Testing
import EtudeKit

/// **BUG-003 — `\crossStaff { }` braces treated as parallel separators.**
///
/// *Symptom:* the prototype treated the braces after `\crossStaff` like the
/// walls of a simultaneous group, splitting one voice's music into phantom
/// parallel voices and corrupting the structure that followed.
///
/// *Root cause:* brace semantics are context-dependent — `\crossStaff` is an
/// engraving hint about which staff to print on, and its braces group exactly
/// like bare `{ }`.
///
/// *Guard:* the parse tree keeps a `\crossStaff` group's events sequential in
/// the surrounding voice. The test uses the exact Gnossienne accompaniment
/// shape (PLAN.md §6).
@Suite("BUG-003: crossStaff braces group without splitting voices")
struct BUG003_CrossStaffBracesSplitVoices {
    @Test("the exact Gnossienne accompaniment shape", .tags(.regression))
    func exactSourceShape() throws {
        let fragment = "\\crossStaff { \\repeat unfold 6 { s4 <c' f>2 q4 | } } s1"
        #expect(try makeSUT().parseMusic(tokens(fragment)) == [
            .sequence([
                .repeated(.unfold, count: 6, body: [
                    .rest(RestToken(kind: .spacer, duration: dur(4))),
                    .chord([NoteToken(name: "c", octaveMarks: 1), NoteToken(name: "f")],
                           duration: dur(2), tied: false),
                    .chordRepeat(duration: dur(4)),
                ], alternatives: []),
            ]),
            .rest(RestToken(kind: .spacer, duration: dur(1))),
        ])
    }

    @Test("no parallel node appears anywhere under a crossStaff group", .tags(.regression))
    func neverParallel() throws {
        let tree = try makeSUT().parseMusic(tokens("\\crossStaff { c d e }"))
        #expect(containsParallel(tree) == false)
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }

    private func containsParallel(_ nodes: [MusicNode]) -> Bool {
        nodes.contains { node in
            switch node {
            case .parallel: true
            case .sequence(let body), .relative(_, let body),
                 .tuplet(_, _, let body), .grace(let body, _):
                containsParallel(body)
            case .repeated(_, _, let body, let alternatives):
                containsParallel(body) || alternatives.contains(where: containsParallel)
            case .context(_, let body): containsParallel([body])
            default: false
            }
        }
    }
}
