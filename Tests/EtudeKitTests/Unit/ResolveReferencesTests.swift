import Testing
import EtudeKit

@Suite("Resolve references")
struct ResolveReferencesTests {
    @Test("inlines a reference from the definitions", .tags(.unit))
    func inlinesDefinition() throws {
        // The Gnossienne arrangement shape: a line of theme references.
        let theme: MusicNode = .relative(anchor: nil, body: [note("c", marks: 2, dur(4))])
        let resolved = try makeSUT().resolve(
            [.reference("themeOneMelody"), .reference("themeOneMelody")],
            definitions: ["themeOneMelody": theme])
        #expect(resolved.notes.map(\.midiNote) == [72, 72])
        #expect(resolved.notes.map(\.startTick) == [0, 480])
    }

    @Test("a definition may reference another definition", .tags(.unit))
    func nestedReferences() throws {
        let resolved = try makeSUT().resolve(
            [.reference("outer")],
            definitions: [
                "outer": .sequence([.reference("inner"), note("d", dur(4))]),
                "inner": .sequence([note("c", dur(4))]),
            ])
        #expect(resolved.notes.map(\.midiNote) == [48, 50])
    }

    @Test("delivers a typed error on a reference with no definition", .tags(.unit))
    func unknownReference() throws {
        #expect(throws: ResolveError.unknownReference("ghostTheme")) {
            try makeSUT().resolve([.reference("ghostTheme")])
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
