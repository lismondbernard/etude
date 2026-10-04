import XCTest

/// Page Object for the Library screen (PLAN.md §8). UI test bodies talk to
/// this, never to raw `app.buttons[...]` queries — that indirection is the
/// lesson.
struct LibraryScreen {
    let app: XCUIApplication

    var isDisplayed: Bool {
        app.navigationBars["Étude"].waitForExistence(timeout: 5)
    }

    /// A regular horizontal size class (iPad, a foldable's inner display)
    /// puts the library in a split view; compact shows one screen at a time.
    /// Read from the app's own size class, never the device idiom or the
    /// window's width.
    var isWide: Bool {
        let probe = app.staticTexts["debug.horizontalSizeClass"].firstMatch
        return probe.waitForExistence(timeout: 5) && probe.label == "regular"
    }

    /// The prompt in the empty detail column before a piece is chosen.
    var showsChoosePrompt: Bool {
        app.staticTexts["Choose a piece"].waitForExistence(timeout: 5)
    }

    /// Where the two columns don't fit side by side, the system hides the
    /// library once a piece is open and offers this button to bring it back.
    var showSidebarButton: XCUIElement {
        app.buttons["Show Sidebar"].firstMatch
    }

    /// Brings the library back if the system tucked it away; does nothing
    /// where it is already on screen.
    func revealIfHidden() {
        if showSidebarButton.exists && showSidebarButton.isHittable {
            showSidebarButton.tap()
        }
    }

    func row(for pieceID: String) -> XCUIElement {
        app.buttons["library.row.\(pieceID)"].firstMatch
    }

    func showsRow(for pieceID: String) -> Bool {
        row(for: pieceID).waitForExistence(timeout: 5)
    }

    @discardableResult
    func openCredits() -> CreditsScreen {
        let button = app.buttons["library.button.credits"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "credits button should exist")
        button.tap()
        return CreditsScreen(app: app)
    }

    @discardableResult
    func openPiece(_ pieceID: String) -> PieceDetailScreen {
        let row = row(for: pieceID)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "row for \(pieceID) should exist")
        row.tap()
        return PieceDetailScreen(app: app)
    }
}
