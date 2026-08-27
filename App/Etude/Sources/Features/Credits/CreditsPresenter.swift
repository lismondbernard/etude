import EtudeKit

/// Pure formatting of the catalog's provenance — functions, not a view model
/// (§0.9). `Corpus/LICENSES.md` is the authority; the badge on `CorpusPiece`
/// is its short form, and this screen is where the app says so out loud.
enum CreditsPresenter {
    static let appCredit =
        "Étude is an open-source study in test-driven development. " +
        "Code and Étude typesettings: Apache-2.0. " +
        "Full provenance for every piece: Corpus/LICENSES.md in the repository."

    static func line(for piece: CorpusPiece) -> String {
        "\(piece.title) — \(piece.composer)"
    }

    static func licenseNote(for piece: CorpusPiece) -> String {
        piece.licenseBadge == "Public domain"
            ? "Composition and typesetting: public domain."
            : "Composition: public domain. Typesetting: \(piece.licenseBadge)."
    }
}
