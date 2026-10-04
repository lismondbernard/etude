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
        XCTAssertTrue(credits.showsSoundBankCredit,
                      "the bundled CC0 piano SoundFont is credited (issue #3)")
    }

    /// In a regular size class (iPad, the inner display of a foldable) opening a
    /// piece shows it uncovered, and the library stays within reach: beside
    /// the piece where both columns fit, one tap away where they don't.
    /// Decided by the size class, never by the device idiom: a foldable
    /// reports itself as a phone.
    func testWideWindowOpensAPieceWithTheLibraryWithinReach() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let library = LibraryScreen(app: app)
        try XCTSkipUnless(library.isWide, "a compact size class collapses to a stack by design")

        let detail = library.openPiece("gymnopedie-1")
        XCTAssertTrue(detail.isDisplayed, "the piece opens")
        XCTAssertTrue(detail.buildButton.isHittable, "the piece is not covered by the library")
        library.revealIfHidden()
        XCTAssertTrue(library.row(for: "minuet-in-g").isHittable,
                      "the library is beside the piece or one tap away")
    }

    /// Before a piece is chosen, the wide detail column says what to do
    /// instead of showing an empty pane.
    func testWideWindowAsksForAPieceBeforeOneIsChosen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let library = LibraryScreen(app: app)
        try XCTSkipUnless(library.isWide, "a compact size class shows the library alone")

        XCTAssertTrue(library.showsChoosePrompt, "the empty detail column asks for a piece")
    }

    /// A tall wide window (iPad held upright, a foldable's inner display)
    /// still shows the library at launch. A split view's default hides the
    /// sidebar in portrait, which would land the user on an empty column.
    func testTallWideWindowShowsTheLibraryAtLaunch() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let library = LibraryScreen(app: app)
        try XCTSkipUnless(library.isWide, "a compact size class shows the library alone")

        XCTAssertTrue(library.showsRow(for: "gymnopedie-1"), "the row exists")
        XCTAssertTrue(library.row(for: "gymnopedie-1").isHittable,
                      "the library is on screen, not hidden behind the sidebar button")
    }

    /// The Credits button lives in the sidebar, so it still works while a
    /// piece is open beside it.
    func testWideWindowOpensCreditsWithAPieceOpen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let library = LibraryScreen(app: app)
        try XCTSkipUnless(library.isWide, "a compact size class covers this in the credits test")

        XCTAssertTrue(library.openPiece("gymnopedie-1").isDisplayed, "the piece opens")
        library.revealIfHidden()
        let credits = library.openCredits()
        XCTAssertTrue(credits.isDisplayed, "Credits open from the sidebar")
    }
}
