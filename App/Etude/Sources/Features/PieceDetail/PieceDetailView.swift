import SwiftUI
import EtudeKit

/// Piece detail (PLAN.md §8, screen 2): Build → track list → Play/Pause (AVMIDIPlayer),
/// tempo slider, and Export via ShareLink. Fleshed out in Phase 5; stubbed here so the
/// navigation and accessibility-identifier scheme are established.
struct PieceDetailView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.title2)
            Button("Build") {}
                .accessibilityIdentifier("detail.button.build")
                .disabled(true)
            Text("Play, tempo slider, and export arrive in Phase 5.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(title)
        .accessibilityIdentifier("detail.screen")
    }
}
