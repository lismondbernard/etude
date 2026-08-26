import Testing
import EtudeKit

@Suite("Parse rests")
struct ParseRestsTests {
    @Test("parses sounding, spacer, and multi-measure rests", .tags(.unit))
    func restKinds() throws {
        #expect(try makeSUT().parseMusic(tokens("r4 s2 R2.")) == [
            .rest(RestToken(kind: .sounding, duration: dur(4))),
            .rest(RestToken(kind: .spacer, duration: dur(2))),
            .rest(RestToken(kind: .multiMeasure, duration: dur(2, dots: 1))),
        ])
    }

    @Test("parses a rest with no written duration", .tags(.unit))
    func bareRest() throws {
        #expect(try makeSUT().parseMusic(tokens("r")) == [
            .rest(RestToken(kind: .sounding)),
        ])
    }

    @Test("parses a pitched rest from a note marked \\rest", .tags(.unit))
    func pitchedRest() throws {
        // Verbatim shape from the Gymnopédie accompaniment: `e4\rest` — the
        // pitch places the rest on the staff and threads the relative context,
        // but nothing sounds.
        #expect(try makeSUT().parseMusic(tokens("e4\\rest <g e b>2")) == [
            .pitchedRest(NoteToken(name: "e", duration: dur(4))),
            .chord([NoteToken(name: "g"), NoteToken(name: "e"), NoteToken(name: "b")],
                   duration: dur(2), tied: false),
        ])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
