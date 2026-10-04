import XCTest

/// Page Object for the Library screen (PLAN.md §8). UI test bodies talk to
/// this, never to raw `app.buttons[...]` queries — that indirection is the
/// lesson.
struct LibraryScreen {
    let app: XCUIApplication

    var isDisplayed: Bool {
        app.navigationBars["Étude"].waitForExistence(timeout: 5)
    }

    /// Regular width (iPad, a foldable's inner display) keeps the library
    /// beside the open piece; compact width shows one screen at a time.
    /// Measured from the window, never the device idiom.
    var isWide: Bool {
        app.windows.firstMatch.frame.width >= 600
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
