import Testing
import Foundation
@testable import EtudeKit

/// Phase 0 smoke test: proves the test harness, module import, and resource bundle
/// are all wired up. Real coverage arrives in Phase 1+ (see PLAN.md §10).
@Suite("Scaffold")
struct ScaffoldTests {
    @Test("EtudeKit module imports and exposes a version", .tags(.unit))
    func moduleImports() {
        #expect(!Etude.version.isEmpty)
    }

    @Test("Golden fixtures are bundled and reachable", .tags(.golden))
    func goldenFixturesResolve() throws {
        // The Golden/Fixtures directory is copied into Bundle.module. Confirm at least
        // one .mid fixture is present; byte-level golden comparison lands in Phase 3.
        let fixtures = Bundle.module.url(forResource: "Fixtures", withExtension: nil)
        let dir = try #require(fixtures, "Golden/Fixtures should be bundled as a resource")
        let mids = try FileManager.default
            .contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "mid" }
        #expect(mids.count == 7, "expected the seven prototype golden fixtures")
    }
}
