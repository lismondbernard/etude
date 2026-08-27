import XCTest

/// The library shows the seven-piece corpus with its honesty markers. The
/// Phase 0 empty state is gone: the engine can build pieces now.
final class LibrarySmokeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testLibraryListsTheCorpus() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let library = LibraryScreen(app: app)
        XCTAssertTrue(library.isDisplayed, "Library screen should appear on launch")
        XCTAssertTrue(library.showsRow(for: "gymnopedie-1"))
        XCTAssertTrue(library.showsRow(for: "minuet-in-g"))
        XCTAssertTrue(library.showsRow(for: "clair-de-lune"),
                      "the known-issue piece is in the catalog, not hidden")
    }

    func testCreditsNameEveryComposerAndLicense() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let credits = LibraryScreen(app: app).openCredits()
        XCTAssertTrue(credits.isDisplayed, "Credits screen should appear")
        XCTAssertTrue(credits.showsAppCredit, "the Apache-2.0 app credit is stated")
        XCTAssertTrue(credits.showsCredit(for: "winter-largo"),
                      "the CC-BY-SA typesetting is credited, not just badged")
    }
}
