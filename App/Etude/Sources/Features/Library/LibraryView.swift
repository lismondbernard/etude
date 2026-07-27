import SwiftUI
import EtudeKit

/// The corpus browser (PLAN.md §8, screen 1). Phase 0 intentionally shows an EMPTY
/// library: the corpus loader lands once the engine can build pieces (Phase 5). The
/// empty state and its accessibility identifiers exist now so the first UI test has a
/// stable surface to assert against.
struct LibraryView: View {
    /// Placeholder row model. Replaced by an EtudeKit-backed corpus type in Phase 5.
    struct PieceRow: Identifiable {
        let id: String
        let title: String
        let composer: String
    }

    /// Empty in Phase 0 — no pieces are loadable until the pipeline exists.
    private let pieces: [PieceRow] = []

    var body: some View {
        NavigationStack {
            Group {
                if pieces.isEmpty {
                    ContentUnavailableView(
                        "No pieces yet",
                        systemImage: "music.note.list",
                        description: Text("The corpus loads once the engine can build pieces (Phase 5).")
                    )
                    .accessibilityIdentifier("library.emptyState")
                } else {
                    List(pieces) { piece in
                        VStack(alignment: .leading) {
                            Text(piece.title).font(.headline)
                            Text(piece.composer).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("library.row.\(piece.id)")
                    }
                }
            }
            .navigationTitle("Étude")
            .accessibilityIdentifier("library.screen")
        }
    }
}

#Preview {
    LibraryView()
}
