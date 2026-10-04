import XCTest

/// The happy path (PLAN.md §8): launch → open the Gymnopédie → it builds on
/// its own and Play unlocks → Play → the export sheet appears. Explicit
/// waits only.
final class BuildAndPlayFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testOpenPlayAndExportTheGymnopedie() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let detail = LibraryScreen(app: app).openPiece("gymnopedie-1")
        XCTAssertTrue(detail.isDisplayed)

        detail.waitForBuild()
        XCTAssertTrue(app.staticTexts["detail.track.melody"].waitForExistence(timeout: 5),
                      "the built tracks should be listed")

        detail.tapPlay()
        XCTAssertTrue(detail.showsPause, "playing should flip the control to Pause")

        detail.tapExport()
        XCTAssertTrue(detail.showsShareSheet, "export should present the share sheet")
    }
}
