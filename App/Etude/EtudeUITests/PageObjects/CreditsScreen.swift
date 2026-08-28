import XCTest

/// Page Object for the Credits screen (Phase 6).
struct CreditsScreen {
    let app: XCUIApplication

    var isDisplayed: Bool {
        app.navigationBars["Credits"].waitForExistence(timeout: 5)
    }

    var showsAppCredit: Bool {
        element("credits.app").waitForExistence(timeout: 5)
    }

    func showsCredit(for pieceID: String) -> Bool {
        element("credits.piece.\(pieceID)").waitForExistence(timeout: 5)
    }

    var showsSoundBankCredit: Bool {
        element("credits.soundbank").waitForExistence(timeout: 5)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }
}
