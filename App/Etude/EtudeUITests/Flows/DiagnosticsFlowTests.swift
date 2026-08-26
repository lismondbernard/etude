import XCTest

/// Failure surfacing (PLAN.md §8): Clair de Lune builds, and its recorded
/// register drift is PRESENTED — the UI is as honest as the tests
/// (ADR-0001, ADR-0003).
final class DiagnosticsFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testClairDeLuneShowsItsFindings() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let detail = LibraryScreen(app: app).openPiece("clair-de-lune")
        detail.buildAndWait()

        let diagnostics = detail.openDiagnostics()
        XCTAssertTrue(diagnostics.isDisplayed)
        XCTAssertTrue(diagnostics.summary.label.contains("finding"),
                      "the summary should count findings, not hide them")
        XCTAssertTrue(diagnostics.finding(at: 0).waitForExistence(timeout: 5))
        XCTAssertTrue(diagnostics.finding(at: 0).label.contains("lhDown"),
                      "the drifted voice is named")
    }

    func testCleanPieceShowsItsGreenSeal() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let detail = LibraryScreen(app: app).openPiece("minuet-in-g")
        detail.buildAndWait()

        let diagnostics = detail.openDiagnostics()
        XCTAssertTrue(diagnostics.isDisplayed)
        XCTAssertTrue(diagnostics.summary.label.contains("All invariants hold"))
    }
}
