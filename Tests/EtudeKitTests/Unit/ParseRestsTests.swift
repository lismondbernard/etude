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

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }
}
