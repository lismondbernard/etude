import Testing

// Shared tag taxonomy for suite slicing (PLAN.md §3). Run one class of tests with,
// e.g., `swift test --filter-tag regression`.
extension Tag {
    @Tag static var unit: Self
    @Tag static var regression: Self
    @Tag static var property: Self
    @Tag static var golden: Self
    @Tag static var acceptance: Self
}
