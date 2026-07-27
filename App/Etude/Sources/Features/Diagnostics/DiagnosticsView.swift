import SwiftUI
import EtudeKit

/// Diagnostics (PLAN.md §8, screen 3): after a build, render the Validator's findings —
/// all green for the six clean pieces, and Clair de Lune's alignment failure shown
/// honestly (ADR-0001, ADR-0003). The app is as candid in its UI as the tests are.
/// Stubbed in Phase 0; wired to the Validator in Phase 5.
struct DiagnosticsView: View {
    var body: some View {
        ContentUnavailableView(
            "No diagnostics yet",
            systemImage: "checklist",
            description: Text("Validator findings appear here after a build (Phase 5).")
        )
        .accessibilityIdentifier("diagnostics.screen")
    }
}
