import XCTest

/// Failure surfacing (PLAN.md §8): a build that fails says why and offers a
/// way back. The `-uiTesting-corpusFailsOnce` seam makes the first read of a
/// source fail, so the retry is the build that succeeds.
final class BuildFailureFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAFailedBuildShowsItsErrorAndCanBeTriedAgain() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-uiTesting-corpusFailsOnce"]
        app.launch()

        let detail = LibraryScreen(app: app).openPiece("gymnopedie-1")
        XCTAssertTrue(detail.isDisplayed)
        XCTAssertTrue(detail.showsError, "the failure is shown, not swallowed")

        detail.tapTryAgain()
        detail.waitForBuild()
        XCTAssertFalse(detail.errorLabel.exists, "the error clears once the piece builds")
    }
}
