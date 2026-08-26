import XCTest

/// Page Object for the Library screen (PLAN.md §8). UI test bodies talk to
/// this, never to raw `app.buttons[...]` queries — that indirection is the
/// lesson.
struct LibraryScreen {
    let app: XCUIApplication

    var isDisplayed: Bool {
        app.navigationBars["Étude"].waitForExistence(timeout: 5)
    }

    func row(for pieceID: String) -> XCUIElement {
        app.buttons["library.row.\(pieceID)"].firstMatch
    }

    func showsRow(for pieceID: String) -> Bool {
        row(for: pieceID).waitForExistence(timeout: 5)
    }

    @discardableResult
    func openPiece(_ pieceID: String) -> PieceDetailScreen {
        let row = row(for: pieceID)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "row for \(pieceID) should exist")
        row.tap()
        return PieceDetailScreen(app: app)
    }
}
