import Testing
import Foundation
import EtudeKit

/// The tokenizer's crash-safety contract: arbitrary bytes may produce tokens or
/// a typed `TokenizerError` — never a trap. (The *typed* half of the contract
/// is compile-time: `tokenize` declares `throws(TokenizerError)`, so nothing
/// else can escape. The fuzz run guards the *never crashes* half.)
@Suite("Tokenizer fuzz smoke")
struct TokenizerFuzzTests {
    @Test("never crashes on random bytes", .tags(.property))
    func randomBytes() {
        let sut = Tokenizer()
        var rng = SeededRandom(seed: 0xE7DE_0001)
        for _ in 0..<500 {
            let count = Int(rng.next() % 64)
            let bytes = (0..<count).map { _ in UInt8(truncatingIfNeeded: rng.next()) }
            _ = try? sut.tokenize(String(decoding: bytes, as: UTF8.self))
        }
    }

    @Test("never crashes on random runs of LilyPond-ish characters", .tags(.property))
    func randomStructuralCharacters() {
        // Random bytes rarely exercise the structural paths; this alphabet does.
        let alphabet = Array(#"abcdefgqrsR<>{}()~|=/\"%!',.0123456789 \n"#)
        let sut = Tokenizer()
        var rng = SeededRandom(seed: 0xE7DE_0002)
        for _ in 0..<500 {
            let count = Int(rng.next() % 48)
            let text = String((0..<count).map { _ in alphabet[Int(rng.next() % UInt64(alphabet.count))] })
            _ = try? sut.tokenize(text)
        }
    }
}
