import XCTest

/// Page Object for the Piece Detail screen: build, playback, tempo, export,
/// diagnostics — wrapped queries and explicit waits, no sleeps.
struct PieceDetailScreen {
    let app: XCUIApplication

    var buildButton: XCUIElement { app.buttons["detail.button.build"] }
    var playButton: XCUIElement { app.buttons["detail.button.play"] }
    var exportButton: XCUIElement { app.buttons["detail.button.export"] }
    var diagnosticsLink: XCUIElement { app.buttons["detail.link.diagnostics"] }

    var isDisplayed: Bool {
        buildButton.waitForExistence(timeout: 5)
    }

    /// Taps Build and waits until playback unlocks — the signal the build
    /// finished and the player is loaded.
    func buildAndWait(timeout: TimeInterval = 20) {
        XCTAssertTrue(buildButton.waitForExistence(timeout: 5), "Build button should exist")
        buildButton.tap()
        XCTAssertTrue(
            playButton.waitForExistence(timeout: timeout) && waitEnabled(playButton, timeout: timeout),
            "Play should unlock after the build")
    }

    func tapPlay() {
        playButton.tap()
    }

    var showsPause: Bool {
        app.buttons["detail.button.play"].label.contains("Pause")
    }

    @discardableResult
    func openDiagnostics() -> DiagnosticsScreen {
        XCTAssertTrue(diagnosticsLink.waitForExistence(timeout: 5))
        diagnosticsLink.tap()
        return DiagnosticsScreen(app: app)
    }

    func tapExport() {
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5))
        exportButton.tap()
    }

    /// The share sheet is OS-owned; accept any of its known faces.
    var showsShareSheet: Bool {
        let candidates = [
            app.otherElements["ActivityListView"],
            app.otherElements["ShareSheet.RemoteContainerView"],
            app.sheets.firstMatch,
        ]
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if candidates.contains(where: { $0.exists }) { return true }
            _ = candidates[0].waitForExistence(timeout: 0.5)
        }
        return false
    }

    private func waitEnabled(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
