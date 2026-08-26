import Testing
import Foundation
import EtudeKit

/// Phase 2 parser acceptance: the vendored Satie sources parse end-to-end into
/// well-formed trees. Musical truth (fingerprints, bar counts) is asserted at
/// the Resolver's acceptance suite; here we assert structural health.
@Suite("Parse corpus sources")
struct ParseCorpusSourcesTests {
    @Test("parses the Gymnopédie source end-to-end", .tags(.acceptance))
    func gymnopedie() throws {
        let file = try makeSUT().parseFile(tokens(corpusSource("gymnopedie-1.ly")))

        #expect(file.header["title"] == "Gymnopédie No. 1")
        #expect(Set(file.definitions.keys) == ["melody", "accompaniment", "bass"])
        #expect(file.score != nil)
        // Every voice is an anchored relative block wrapping a volta repeat
        // with two alternative endings.
        for (name, definition) in file.definitions {
            guard case .relative(let anchor, let body) = definition else {
                Issue.record("\(name) is not a relative block")
                continue
            }
            #expect(anchor != nil, "\(name) should carry its anchor pitch")
            let voltaEndings = body.compactMap { node -> [[MusicNode]]? in
                if case .repeated(.volta, 2, _, let alternatives) = node { alternatives } else { nil }
            }
            #expect(voltaEndings.count == 1, "\(name) should hold exactly one volta repeat")
            #expect(voltaEndings.first?.count == 2, "\(name) should have two endings")
        }
    }

    @Test("parses the Gnossienne source end-to-end", .tags(.acceptance))
    func gnossienne() throws {
        let file = try makeSUT().parseFile(tokens(corpusSource("gnossienne-1.ly")))

        #expect(file.header["composer"] == "Erik Satie")
        // 4 themes × 4 lines + the 4 performed arrangements.
        #expect(file.definitions.count == 20)
        #expect(file.score != nil)
        // The arrangement lists 16 theme uses per line; definitions capture by
        // value, so each is the inlined theme — a relative block.
        guard case .sequence(let melody) = file.definitions["melody"] else {
            Issue.record("melody is not a sequence")
            return
        }
        let themes = melody.filter { if case .relative = $0 { true } else { false } }
        #expect(themes.count == 16)
        #expect(themes.first == file.definitions["themeOneMelody"])
    }

    // MARK: - Helpers

    private func makeSUT() -> Parser { Parser() }

    private func tokens(_ source: String) throws -> [Token] {
        try Tokenizer().tokenize(source)
    }

    private func corpusSource(_ name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus")
            .appendingPathComponent(name)
        return try String(contentsOf: url, encoding: .utf8)
    }
}
