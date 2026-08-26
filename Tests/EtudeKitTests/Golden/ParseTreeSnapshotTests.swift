import Testing
import Foundation
import EtudeKit

/// The parse tree is Codable so structure changes show up as a readable JSON
/// diff instead of a wall of Equatable noise (PLAN.md §4.2). The fixture is the
/// contract: an intentional tree change means deleting it, rerunning to
/// re-record, and reviewing the diff in the commit.
@Suite("Parse tree snapshots")
struct ParseTreeSnapshotTests {
    @Test("the Gnossienne first theme's tree matches its recorded snapshot", .tags(.golden))
    func gnossienneFirstTheme() throws {
        let fragment = """
            \\language "english"
            \\relative {
              r4 c''8 ( ef d4 c |
              \\grace { c8 } b2 \\grace { c8 } b!2 ) |
            }
            """
        let tree = try Parser().parseMusic(try Tokenizer().tokenize(fragment))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let json = try encoder.encode(tree)

        let fixture = fixtureURL("gnossienne-theme-one-opening.json")
        guard FileManager.default.fileExists(atPath: fixture.path) else {
            try json.write(to: fixture)
            Issue.record("No snapshot existed — recorded one; rerun to verify against it")
            return
        }
        #expect(json == (try Data(contentsOf: fixture)),
                "Tree no longer matches its snapshot — if intended, delete the fixture and re-record")
    }

    // MARK: - Helpers

    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
    }
}
