import SwiftUI
import EtudeKit

/// The corpus browser (PLAN.md §8, screen 1): a plain view over the engine's
/// catalog — no view model, per §0.9, until the corpus becomes dynamic.
///
/// A split view: at regular width the library stays beside the open piece;
/// at compact width it collapses to the same stack as before. Width decides,
/// never the device idiom, because a foldable's inner display reports itself
/// as a phone.
struct LibraryView: View {
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            List(CorpusPiece.all, selection: $selection) { piece in
                NavigationLink(value: piece.id) {
                    row(for: piece)
                }
                .accessibilityIdentifier("library.row.\(piece.id)")
            }
            .navigationTitle("Étude")
            .accessibilityIdentifier("library.screen")
            .toolbar {
                NavigationLink {
                    CreditsView()
                } label: {
                    Label("Credits", systemImage: "info.circle")
                }
                .accessibilityIdentifier("library.button.credits")
            }
        } detail: {
            // The detail keeps its own stack so Diagnostics pushes inside
            // the column. `.id` gives each piece a fresh view model: the
            // detail holds its build and playback state, and switching
            // pieces must not carry the last one's over.
            if let piece = CorpusPiece.all.first(where: { $0.id == selection }) {
                NavigationStack {
                    PieceDetailView(piece: piece)
                }
                .id(piece.id)
            }
        }
    }

    private func row(for piece: CorpusPiece) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(piece.title).font(.headline)
            Text(piece.composer).font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(piece.licenseBadge)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
                if piece.knownIssue != nil {
                    // The catalog is as honest as the tests (ADR-0003).
                    Label("Known issue", systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    LibraryView()
}
