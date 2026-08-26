import XCTest

extension XCTestCase {
    /// §0.6: the app layer is where reference types live, so every app-layer
    /// `makeSUT()` registers its instances here — a leaked view model or
    /// player wrapper fails the test that created it.
    func trackForMemoryLeaks(
        _ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line
    ) {
        // The weak reference rides in an unchecked box because teardown blocks
        // are Sendable; the box is only ever read after the test body is done.
        let box = WeakBox(instance)
        addTeardownBlock { @MainActor in
            XCTAssertNil(
                box.value,
                "Instance should have been deallocated — potential memory leak.",
                file: file, line: line)
        }
    }
}

private final class WeakBox: @unchecked Sendable {
    private(set) weak var value: AnyObject?

    init(_ value: AnyObject) {
        self.value = value
    }
}
