import Testing
import EtudeKit

@Suite("Corpus catalog")
struct CorpusCatalogTests {
    @Test("catalogs all seven bundled pieces with unique ids", .tags(.unit))
    func sevenPieces() throws {
        #expect(CorpusPiece.all.count == 7)
        #expect(Set(CorpusPiece.all.map(\.id)).count == 7)
        #expect(CorpusPiece.all.allSatisfy { !$0.title.isEmpty && !$0.composer.isEmpty })
    }

    @Test("only Clair de Lune carries a known issue", .tags(.unit))
    func knownIssues() throws {
        let flagged = CorpusPiece.all.filter { $0.knownIssue != nil }
        #expect(flagged.map(\.id) == ["clair-de-lune"])
    }

    @Test("pieces without a score block name their voices explicitly", .tags(.unit))
    func explicitVoices() throws {
        let clair = CorpusPiece.all.first { $0.id == "clair-de-lune" }
        #expect(clair?.voices == ["rhUp", "rhDown", "lhUp", "lhDown"])
        #expect(CorpusPiece.all.filter { $0.id != "clair-de-lune" }.allSatisfy { $0.voices == nil })
    }

    @Test("every piece states its typesetting license for the library badge", .tags(.unit))
    func licenseBadges() throws {
        #expect(CorpusPiece.all.allSatisfy { !$0.licenseBadge.isEmpty })
        let winter = CorpusPiece.all.first { $0.id == "winter-largo" }
        #expect(winter?.licenseBadge.contains("CC-BY-SA") == true)
    }
}
