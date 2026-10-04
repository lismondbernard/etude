import Foundation
import os
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

/// The `-uiTesting-corpusFailsOnce` corpus: the first read fails the way a
/// missing source does, every later read comes from the wrapped corpus. It
/// is the second launch-argument seam beside `SilentMIDIPlayer`, and it lets
/// a UI test reach the failed state and then recover from it.
final class FailOnceCorpus: CorpusProviding {
    private let wrapped: any CorpusProviding
    private let hasFailed = OSAllocatedUnfairLock(initialState: false)

    init(wrapping wrapped: any CorpusProviding) {
        self.wrapped = wrapped
    }

    func source(for piece: CorpusPiece) throws -> String {
        let firstRead = hasFailed.withLock { failed in
            defer { failed = true }
            return !failed
        }
        if firstRead { throw BundledCorpus.Failure.missingSource(piece.id) }
        return try wrapped.source(for: piece)
    }
}
