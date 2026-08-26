import Testing
import Foundation
import EtudeKit

@Suite("Scratch dump") struct ScratchDumpTests {
    @Test("clair") func clair() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus/clair-de-lune.ly")
        let file = try Parser().parseFile(try Tokenizer().tokenize(String(contentsOf: url, encoding: .utf8)))
        print("DEFS:", file.definitions.keys.sorted().joined(separator: " "))
        for name in ["rhUp", "rhDown", "lhUp", "lhDown"] {
            do {
                let r = try Resolver().resolve([file.definitions[name]!], definitions: file.definitions)
                print("VOICE", name, "notes", r.notes.count, "ticks", r.totalTicks,
                      "bars9/8", Double(r.totalTicks) / 2160.0)
            } catch {
                print("VOICE", name, "resolve error:", error)
            }
        }
    }
}
