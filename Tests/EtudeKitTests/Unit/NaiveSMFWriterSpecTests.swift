import Testing
import EtudeKit

/// The naive explicit-status writer, held to the shared contract
/// (`SMFWriterSpecs`, PLAN.md §0.5). When its replacement passes this same
/// suite, deleting this writer is a one-commit, low-risk change.
@Suite("Naive SMF writer meets the writer contract")
struct NaiveSMFWriterSpecTests: SMFWriterSpecs {
    @Test("writes a Type 1 header: meta track + one track per voice", .tags(.unit))
    func header() {
        assertWritesType1HeaderWithMetaTrackPlusOneTrackPerVoice()
    }

    @Test("the meta track carries the tempo, defaulting to 120", .tags(.unit))
    func tempo() throws {
        try assertMetaTrackCarriesTempo()
    }

    @Test("the meta track carries the meter", .tags(.unit))
    func meter() {
        assertMetaTrackCarriesMeter()
    }

    @Test("voices round-trip through the reader", .tags(.unit))
    func roundTrip() throws {
        try assertVoicesRoundTripThroughTheReader()
    }

    @Test("back-to-back repeated pitches re-attack", .tags(.unit))
    func repeatedPitches() throws {
        try assertBackToBackRepeatedPitchesReattack()
    }

    @Test("long silences survive multi-byte delta encoding", .tags(.unit))
    func longSilences() throws {
        try assertLongSilencesSurvive()
    }

    @Test("every track is terminated and chunks tile the file", .tags(.unit))
    func structure() {
        assertEveryTrackIsTerminatedAndTheFileIsTiledByChunks()
    }

    @Test("output is deterministic", .tags(.unit))
    func deterministic() {
        assertOutputIsDeterministic()
    }

    // MARK: - Helpers

    func makeSUT() -> any SMFWriting { SMFWriter() }
}
