import XCTest
@testable import Etude

/// Voice names come from the LilyPond sources (`rhUp`, `violinOne`); the
/// track list speaks the musician's language instead.
final class TrackPresenterTests: XCTestCase {
    func testPianoVoicesAreNamedForTheHands() {
        XCTAssertEqual(TrackPresenter.name(for: "rhUp"), "Right hand, upper")
        XCTAssertEqual(TrackPresenter.name(for: "rhDown"), "Right hand, lower")
        XCTAssertEqual(TrackPresenter.name(for: "lhUp"), "Left hand, upper")
        XCTAssertEqual(TrackPresenter.name(for: "lhDown"), "Left hand, lower")
    }

    func testStringPartsTakeTheirOrchestralNames() {
        XCTAssertEqual(TrackPresenter.name(for: "solo"), "Solo violin")
        XCTAssertEqual(TrackPresenter.name(for: "violinOne"), "Violin I")
        XCTAssertEqual(TrackPresenter.name(for: "violinTwo"), "Violin II")
    }

    func testOtherNamesAreSpelledOutAsWords() {
        XCTAssertEqual(TrackPresenter.name(for: "melody"), "Melody")
        XCTAssertEqual(TrackPresenter.name(for: "upperChords"), "Upper chords")
    }
}
