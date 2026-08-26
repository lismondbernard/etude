import Foundation
import EtudeKit

/// The `CorpusProviding` adapter for the shipping app: sources come from the
/// bundle's vendored `Corpus/*.ly` files (§0.3 — a download service could
/// replace this without the view models noticing).
struct BundledCorpus: CorpusProviding {
    enum Failure: Error, Equatable {
        case missingSource(String)
    }

    func source(for piece: CorpusPiece) throws -> String {
        guard let url = Bundle.main.url(forResource: piece.id, withExtension: "ly") else {
            throw Failure.missingSource(piece.id)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
