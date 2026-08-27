import SwiftUI
import EtudeKit

/// Credits and licensing (PLAN.md Phase 6): every composer named, every
/// typesetting license stated — the app-facing face of `Corpus/LICENSES.md`.
struct CreditsView: View {
    var body: some View {
        List {
            Section {
                Text(CreditsPresenter.appCredit)
                    .font(.footnote)
                    .accessibilityIdentifier("credits.app")
            }
            Section("Pieces") {
                ForEach(CorpusPiece.all) { piece in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(CreditsPresenter.line(for: piece))
                            .font(.subheadline)
                        Text(CreditsPresenter.licenseNote(for: piece))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("credits.piece.\(piece.id)")
                }
            }
        }
        .navigationTitle("Credits")
        .accessibilityIdentifier("credits.screen")
    }
}

#Preview {
    NavigationStack { CreditsView() }
}
