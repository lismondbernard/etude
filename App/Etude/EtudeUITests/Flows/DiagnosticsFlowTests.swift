import XCTest

/// Failure surfacing (PLAN.md §8): diagnostics tell the truth either way.
/// While issue #1 was open this flow asserted Clair de Lune PRESENTED its
/// register findings (ADR-0001, ADR-0003); with the issue closed, the former
/// boss fight earns the same green seal as everything else. (The
/// findings-presentation formatting stays covered by DiagnosticsPresenter's
/// unit tests.)
final class DiagnosticsFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testFormerBossFightShowsItsGreenSeal() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let detail = LibraryScreen(app: app).openPiece("clair-de-lune")
        detail.buildAndWait()

        let diagnostics = detail.openDiagnostics()
        XCTAssertTrue(diagnostics.isDisplayed)
        XCTAssertTrue(diagnostics.summary.label.contains("All invariants hold"),
                      "issue #1 is closed; Clair de Lune validates clean")
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
