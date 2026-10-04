import XCTest

/// Page Object for the Piece Detail screen: the build that opening starts,
/// playback, tempo, export, diagnostics — wrapped queries and explicit
/// waits, no sleeps.
struct PieceDetailScreen {
    let app: XCUIApplication

    var playButton: XCUIElement { app.buttons["detail.button.play"] }
    var exportButton: XCUIElement { app.buttons["detail.button.export"] }
    var diagnosticsLink: XCUIElement { app.buttons["detail.link.diagnostics"] }
    var retryButton: XCUIElement { app.buttons["detail.button.retry"] }
    var errorLabel: XCUIElement { app.staticTexts["detail.error"] }

    /// The screen itself, by its identifier: it is there whatever state the
    /// build is in, unlike any one control on it.
    var screen: XCUIElement { app.descendants(matching: .any)["detail.screen"].firstMatch }

    var isDisplayed: Bool {
        screen.waitForExistence(timeout: 5)
    }

    /// Waits for the build that opening the piece starts, without tapping
    /// anything: playback unlocking is the signal it finished.
    func waitForBuild(timeout: TimeInterval = 20) {
        XCTAssertTrue(
            playButton.waitForExistence(timeout: timeout) && waitEnabled(playButton, timeout: timeout),
            "the piece should build on its own when it opens")
    }

    var showsError: Bool {
        errorLabel.waitForExistence(timeout: 10)
    }

    func tapTryAgain() {
        XCTAssertTrue(retryButton.waitForExistence(timeout: 5), "a failed build offers Try again")
        retryButton.tap()
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
