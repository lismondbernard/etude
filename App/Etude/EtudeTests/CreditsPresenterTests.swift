import XCTest
import EtudeKit
@testable import Etude

final class CreditsPresenterTests: XCTestCase {
    func testLineNamesPieceAndComposer() {
        let piece = CorpusPiece(id: "clair-de-lune", title: "Clair de Lune",
                                composer: "Claude Debussy")
        XCTAssertEqual(CreditsPresenter.line(for: piece), "Clair de Lune — Claude Debussy")
    }

    func testPublicDomainPiecesGetOneCombinedNote() {
        let piece = CorpusPiece(id: "minuet-in-g", title: "Minuet in G major",
                                composer: "Christian Petzold")
        XCTAssertEqual(CreditsPresenter.licenseNote(for: piece),
                       "Composition and typesetting: public domain.")
    }

    func testLicensedTypesettingsAreCalledOutSeparately() {
        let piece = CorpusPiece(id: "winter-largo", title: "Winter (Largo)",
                                composer: "Antonio Vivaldi",
                                licenseBadge: "CC-BY-SA typesetting")
        XCTAssertEqual(CreditsPresenter.licenseNote(for: piece),
                       "Composition: public domain. Typesetting: CC-BY-SA typesetting.")
    }

    func testSoundBankCreditNamesTheFontItsSourceAndItsLicense() {
        XCTAssertTrue(CreditsPresenter.soundBankCredit.contains("Upright Piano KW"))
        XCTAssertTrue(CreditsPresenter.soundBankCredit.contains("FreePats"))
        XCTAssertTrue(CreditsPresenter.soundBankCredit.contains("CC0"))
    }

    func testAppCreditPointsAtTheAuthoritativeLicenseFile() {
        XCTAssertTrue(CreditsPresenter.appCredit.contains("Apache-2.0"))
        XCTAssertTrue(CreditsPresenter.appCredit.contains("Corpus/LICENSES.md"))
    }
}
