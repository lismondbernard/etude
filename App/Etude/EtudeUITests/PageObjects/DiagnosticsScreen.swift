import XCTest

/// Page Object for the Diagnostics screen.
struct DiagnosticsScreen {
    let app: XCUIApplication

    var isDisplayed: Bool {
        app.navigationBars["Diagnostics"].waitForExistence(timeout: 5)
    }

    var summary: XCUIElement {
        app.staticTexts["diagnostics.summary"]
    }

    func finding(at index: Int) -> XCUIElement {
        app.staticTexts["diagnostics.finding.\(index)"]
    }
}
