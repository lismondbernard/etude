import XCTest

/// Captures the App Store screenshot set (SSS-88). Not a behavior test: it
/// walks the pipeline the way the store listing tells the story — build,
/// play, diagnostics, export — and attaches a full-screen capture at each
/// stop. Run it alone, on the marketing simulators:
///
///   xcodebuild test -project App/Etude/Etude.xcodeproj -scheme Etude \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2' \
///     -only-testing:EtudeUITests/ScreenshotCaptureTests \
///     -resultBundlePath shots.xcresult
///
/// then export with `xcrun xcresulttool export attachments`. The shots lead
/// with the pipeline, never the bare song list — the listing positions Étude
/// as a tool, and the screenshots carry that argument.
final class ScreenshotCaptureTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let library = LibraryScreen(app: app)
        XCTAssertTrue(library.isDisplayed)
        snap("04-library")

        let detail = library.openPiece("clair-de-lune")
        detail.buildAndWait()
        detail.tapPlay()
        XCTAssertTrue(detail.showsPause)
        snap("01-build-and-play")

        let diagnostics = detail.openDiagnostics()
        XCTAssertTrue(diagnostics.isDisplayed)
        snap("02-diagnostics")
        app.navigationBars.buttons.firstMatch.tap()

        detail.tapExport()
        XCTAssertTrue(detail.showsShareSheet)
        snap("03-export")
        app.tap() // dismiss the share sheet

        _ = app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5)
        app.navigationBars.buttons.firstMatch.tap()
        let credits = library.openCredits()
        XCTAssertTrue(credits.isDisplayed)
        snap("05-credits")
    }

    /// Full-screen capture (status bar included) so the export is directly
    /// usable as an App Store asset.
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
