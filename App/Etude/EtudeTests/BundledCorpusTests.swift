import XCTest
import EtudeKit
@testable import Etude

final class BundledCorpusTests: XCTestCase {
    func testEveryCatalogedPieceHasABundledSource() throws {
        let sut = BundledCorpus()
        for piece in CorpusPiece.all {
            let source = try sut.source(for: piece)
            XCTAssertFalse(source.isEmpty, "\(piece.id) should ship in the bundle")
        }
    }

    func testAMissingPieceFailsLoudly() {
        let sut = BundledCorpus()
        let ghost = CorpusPiece(id: "ghost-piece", title: "Ghost", composer: "Nobody")
        XCTAssertThrowsError(try sut.source(for: ghost))
    }
}
