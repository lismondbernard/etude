import XCTest

/// Phase 0 UI smoke: the app launches and the Library shows its empty state. The full
/// browse→build→play→export happy path and the Clair de Lune failure-surfacing flow are
/// added in Phase 5 (PLAN.md §8). Explicit waits only — no `sleep` (flake discipline).
final class LibrarySmokeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testLibraryLaunchesAndShowsEmptyState() {
        let app = XCUIApplication()
        app.launch()

        let library = LibraryScreen(app: app)
        XCTAssertTrue(library.isDisplayed, "Library screen should appear on launch")
        XCTAssertTrue(library.showsEmptyState, "Phase 0 corpus is empty; empty state should show")
    }
}
