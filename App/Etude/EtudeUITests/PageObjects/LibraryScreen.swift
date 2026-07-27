import XCTest

/// Page Object for the Library screen (PLAN.md §8). UI test bodies talk to this, never
/// to raw `app.buttons[...]` queries — that indirection is the lesson.
struct LibraryScreen {
    let app: XCUIApplication

    var isDisplayed: Bool {
        app.otherElements["library.screen"].waitForExistence(timeout: 5)
            || app.navigationBars["Étude"].waitForExistence(timeout: 5)
    }

    var showsEmptyState: Bool {
        app.staticTexts["No pieces yet"].waitForExistence(timeout: 5)
    }
}
