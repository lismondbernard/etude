import Testing
import EtudeKit

// The SMF writer contract (PLAN.md §0.5).
//
// One reusable spec suite that EVERY writer behind `SMFWriting` must pass.
// The assertions are deliberately implementation-agnostic: they check the
// file's structure and what `SMFReader` decodes back, never exact bytes —
// exact encoding (explicit status vs running status) is the implementation's
// business. This is what makes the Phase 6 swap safe: prove the replacement
// against these specs, then delete the original in one commit.
//
// Swift Testing does not inherit `@Test` through protocols, so each
// conforming suite declares thin `@Test` methods that call these helpers.

protocol SMFWriterSpecs {
    func makeSUT() -> any SMFWriting
}

extension SMFWriterSpecs {
    /// Format-level facts every SMF Type 1 file must state in its header:
    /// format 1, one meta track plus one track per voice, division 480.
    func assertWritesType1HeaderWithMetaTrackPlusOneTrackPerVoice(
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let bytes = makeSUT().bytes(for: score([
            voice("melody", pitches: [60]),
            voice("bass", pitches: [48]),
        ]))
        #expect(Array(bytes.prefix(14)) == [
            0x4D, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 1, 0, 3, 0x01, 0xE0,
        ], sourceLocation: sourceLocation)
    }

    /// The score's tempo must come back off the file; without one, 120 BPM.
    func assertMetaTrackCarriesTempo(
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let sut = makeSUT()
        let lent = try SMFReader().read(sut.bytes(for: score(
            [voice("melody", pitches: [60])],
            tempo: TempoMark(label: "Lent", beatUnit: 4, beatsPerMinute: 66))))
        #expect(lent.beatsPerMinute == 66, sourceLocation: sourceLocation)

        let defaulted = try SMFReader().read(sut.bytes(for: score([voice("melody", pitches: [60])])))
        #expect(defaulted.beatsPerMinute == 120, sourceLocation: sourceLocation)
    }

    /// The meter must be stated as a time-signature meta in the meta track
    /// (beats, beat unit as a power of two). `SMFReader` does not decode
    /// meter, so this scans the first track chunk for the meta's payload.
    func assertMetaTrackCarriesMeter(
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let bytes = makeSUT().bytes(for: score(
            [voice("melody", pitches: [60])],
            meter: Meter(beats: 3, beatUnit: 8)))
        let metaTrack = firstTrackChunk(of: bytes)
        #expect(contains(metaTrack, subsequence: [0xFF, 0x58, 4, 3, 3]),
                "expected a 3/8 time-signature meta in track 0",
                sourceLocation: sourceLocation)
    }

    /// Voices survive the trip: names in order, and every event — chords at
    /// one tick, gaps, distinct-pitch overlaps — restored exactly.
    func assertVoicesRoundTripThroughTheReader(
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let original = score([
            Voice(name: "melody", events: [
                NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80),
                NoteEvent(pitch: 64, startTick: 0, durationTicks: 960, velocity: 72),
                NoteEvent(pitch: 67, startTick: 480, durationTicks: 240, velocity: 90),
                NoteEvent(pitch: 62, startTick: 1920, durationTicks: 480, velocity: 80),
            ], totalTicks: 2400),
            voice("bass", pitches: [48, 43, 45]),
        ])
        let file = try SMFReader().read(makeSUT().bytes(for: original))
        #expect(file.tracks.dropFirst().map(\.name) == ["melody", "bass"],
                sourceLocation: sourceLocation)
        for (track, voice) in zip(file.tracks.dropFirst(), original.voices) {
            #expect(track.events == voice.events, sourceLocation: sourceLocation)
        }
    }

    /// Back-to-back equal pitches must re-attack: the first note's off has to
    /// precede the second's on at their shared tick, or the reader (like any
    /// synthesizer) pairs the events wrongly and the durations come back skewed.
    func assertBackToBackRepeatedPitchesReattack(
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let original = score([voice("melody", pitches: [60, 60, 60])])
        let file = try SMFReader().read(makeSUT().bytes(for: original))
        #expect(file.tracks.dropFirst().first?.events == original.voices.first?.events,
                sourceLocation: sourceLocation)
    }

    /// Silences longer than 127 ticks force multi-byte delta encoding; the
    /// start tick must survive the trip exactly.
    func assertLongSilencesSurvive(
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let original = score([Voice(name: "melody", events: [
            NoteEvent(pitch: 60, startTick: 0, durationTicks: 480, velocity: 80),
            NoteEvent(pitch: 62, startTick: 100_000, durationTicks: 480, velocity: 80),
        ], totalTicks: 100_480)])
        let file = try SMFReader().read(makeSUT().bytes(for: original))
        #expect(file.tracks.dropFirst().first?.events == original.voices.first?.events,
                sourceLocation: sourceLocation)
    }

    /// Appendix A structure check: every declared track is a well-formed
    /// `MTrk` chunk ending in End-of-Track, and the chunks tile the file
    /// exactly — no trailing bytes.
    func assertEveryTrackIsTerminatedAndTheFileIsTiledByChunks(
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let bytes = makeSUT().bytes(for: score([
            voice("melody", pitches: [60, 62, 64]),
            voice("bass", pitches: [48]),
        ]))
        let declaredTracks = Int(bytes[10]) << 8 | Int(bytes[11])
        var i = 14
        var tracks = 0
        while i < bytes.count {
            #expect(Array(bytes[i..<(i + 4)]) == Array("MTrk".utf8),
                    sourceLocation: sourceLocation)
            let length = (4..<8).reduce(0) { $0 << 8 | Int(bytes[i + $1]) }
            let end = i + 8 + length
            #expect(end <= bytes.count, sourceLocation: sourceLocation)
            #expect(Array(bytes[(end - 3)..<end]) == [0xFF, 0x2F, 0],
                    "track \(tracks) must end with End-of-Track",
                    sourceLocation: sourceLocation)
            i = end
            tracks += 1
        }
        #expect(i == bytes.count, "no bytes may trail the last chunk",
                sourceLocation: sourceLocation)
        #expect(tracks == declaredTracks, sourceLocation: sourceLocation)
    }

    /// Same score in, same bytes out — golden fixtures depend on it.
    func assertOutputIsDeterministic(
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let sut = makeSUT()
        let sample = score([voice("melody", pitches: [60, 64, 67])])
        #expect(sut.bytes(for: sample) == sut.bytes(for: sample),
                sourceLocation: sourceLocation)
    }

    // MARK: - Structure helpers

    private func firstTrackChunk(of bytes: [UInt8]) -> [UInt8] {
        let length = (18..<22).reduce(0) { $0 << 8 | Int(bytes[$1]) }
        return Array(bytes[22..<(22 + length)])
    }

    private func contains(_ bytes: [UInt8], subsequence: [UInt8]) -> Bool {
        guard bytes.count >= subsequence.count else { return false }
        return (0...(bytes.count - subsequence.count)).contains { start in
            Array(bytes[start..<(start + subsequence.count)]) == subsequence
        }
    }
}
