import Testing
import EtudeKit

// Deliberately NOT @testable: the resolver is exercised through its public API
// only, the same design pressure its real consumers (Validator, MIDI writer)
// will exert. Convention: middle C is written `c'` and resolves to MIDI 60,
// so absolute `c` is MIDI 48.
@Suite("Resolve pitch spellings")
struct ResolvePitchSpellingsTests {
    @Test("resolves bare Dutch letters in absolute mode", .tags(.unit))
    func dutchLetters() throws {
        let resolved = try makeSUT().resolve([note("c", dur(4)), note("d", dur(4)), note("b", dur(4))])
        #expect(resolved.notes.map(\.midiNote) == [48, 50, 59])
    }

    @Test("resolves Dutch accidental suffixes", .tags(.unit), arguments: [
        ("fis", 54), ("cis", 49), ("bes", 58), ("des", 49), ("fisis", 55), ("beses", 57),
    ])
    func dutchAccidentals(name: String, midi: Int) throws {
        let resolved = try makeSUT().resolve([note(name, dur(4))])
        #expect(resolved.notes.map(\.midiNote) == [midi])
    }

    @Test("resolves English accidental suffixes", .tags(.unit), arguments: [
        ("cs", 49), ("df", 49), ("ef", 51), ("bf", 58), ("af", 56), ("bff", 57), ("css", 50),
    ])
    func englishAccidentals(name: String, midi: Int) throws {
        let resolved = try makeSUT().resolve([note(name, dur(4))])
        #expect(resolved.notes.map(\.midiNote) == [midi])
    }

    @Test("octave marks shift an absolute pitch by twelve", .tags(.unit))
    func octaveMarks() throws {
        let resolved = try makeSUT().resolve([
            note("c", marks: 1, dur(4)), note("c", marks: 2, dur(4)), note("c", marks: -1, dur(4)),
        ])
        #expect(resolved.notes.map(\.midiNote) == [60, 72, 36])
    }

    @Test("delivers a typed error on a word that is no pitch in any language", .tags(.unit))
    func unknownSpelling() throws {
        #expect(throws: ResolveError.unknownPitchName("h")) {
            try makeSUT().resolve([note("h", dur(4))])
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> Resolver { Resolver() }
}
