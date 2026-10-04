import SwiftUI
import EtudeKit

/// The corpus browser (PLAN.md §8, screen 1): a plain view over the engine's
/// catalog — no view model, per §0.9, until the corpus becomes dynamic.
///
/// A split view: in a regular horizontal size class the library sits beside
/// the open piece; in a compact one it collapses to the same stack as before.
/// The size class decides, never the device idiom, because a foldable's inner
/// display reports itself as a phone.
struct LibraryView: View {
    @State private var selection: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// The library shows until a piece is chosen, then the system decides.
    /// Left to itself, a wide but tall window (a foldable's inner display
    /// held upright) hides the sidebar and opens on an empty column. Forced
    /// to stay, the sidebar covers the open piece where the two columns
    /// don't fit side by side. So: all columns at launch, automatic after.
    @State private var columns: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
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
            } else {
                ContentUnavailableView(
                    "Choose a piece",
                    systemImage: "music.note.list",
                    description: Text("Pick a piece from the library to build it and play it."))
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selection) { _, chosen in
            columns = chosen == nil ? .all : .automatic
        }
        .overlay(alignment: .bottomTrailing) { sizeClassProbe }
    }

    /// UI tests (`-uiTesting`) read the horizontal size class from this
    /// invisible label, so they decide "wide" the way the layout does, by
    /// size class, rather than by measuring the window.
    @ViewBuilder private var sizeClassProbe: some View {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            Text(horizontalSizeClass == .regular ? "regular" : "compact")
                .font(.system(size: 1))
                .opacity(0.01)
                .accessibilityIdentifier("debug.horizontalSizeClass")
                .allowsHitTesting(false)
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
