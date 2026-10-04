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

    /// The `-uiTesting-corpusFailsOnce` seam: the first read fails the way a
    /// missing source does, the next reads come from the bundle.
    func testTheFailOnceCorpusFailsThenRecovers() throws {
        let sut = FailOnceCorpus(wrapping: BundledCorpus())
        let piece = try XCTUnwrap(CorpusPiece.all.first)

        XCTAssertThrowsError(try sut.source(for: piece))
        XCTAssertFalse(try sut.source(for: piece).isEmpty)
    }
}
