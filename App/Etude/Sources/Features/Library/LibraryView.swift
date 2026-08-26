import SwiftUI
import EtudeKit

/// The corpus browser (PLAN.md §8, screen 1): a plain view over the engine's
/// catalog — no view model, per §0.9, until the corpus becomes dynamic.
struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List(CorpusPiece.all) { piece in
                NavigationLink(value: piece.id) {
                    row(for: piece)
                }
                .accessibilityIdentifier("library.row.\(piece.id)")
            }
            .navigationDestination(for: String.self) { id in
                if let piece = CorpusPiece.all.first(where: { $0.id == id }) {
                    PieceDetailView(piece: piece)
                }
            }
            .navigationTitle("Étude")
            .accessibilityIdentifier("library.screen")
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
