import Testing
import EtudeKit

/// The writer/reader law (PLAN.md §4.5): write→read is the identity on
/// events, for voices with no same-pitch overlap. (Overlapping equal pitches
/// are ambiguous in MIDI itself — on/off pairing cannot tell nested from
/// sequential — so they are outside the law, not outside the tests: the
/// corpus goldens cover the one real case, byte for byte.) Any writer swapped
/// in behind `SMFWriting` (§0.5) must keep this property — it is what makes
/// the Phase 6 replacement safe.
@Suite("SMF round trip")
struct SMFRoundTripTests {
    static let writers: [any SMFWriting] = [SMFWriter(), RunningStatusSMFWriter()]

    @Test("write then read restores every voice's events", .tags(.property),
          arguments: 0..<writers.count)
    func roundTrip(writerIndex: Int) throws {
        let writer = Self.writers[writerIndex]
        var random = SeededRandom(seed: 0x51DE)
        for _ in 0..<30 {
            let voices = (0..<Int.random(in: 1...4, using: &random)).map { index in
                randomVoice(named: "voice\(index)", using: &random)
            }
            let original = score(
                voices,
                meter: Meter(beats: Int.random(in: 2...9, using: &random), beatUnit: 4),
                tempo: TempoMark(label: nil, beatUnit: 4,
                                 beatsPerMinute: Int.random(in: 40...200, using: &random)))

            let file = try SMFReader().read(writer.bytes(for: original))

            #expect(file.division == 480)
            #expect(file.beatsPerMinute == original.tempo?.beatsPerMinute)
            #expect(file.tracks.dropFirst().map(\.name) == original.voices.map(\.name))
            for (track, voice) in zip(file.tracks.dropFirst(), original.voices) {
                #expect(track.events == voice.events, "seed 0x51DE")
            }
        }
    }

    // MARK: - Helpers

    private func randomVoice(named name: String, using random: inout SeededRandom) -> Voice {
        var tick = 0
        var events: [NoteEvent] = []
        var openUntil: [UInt8: Int] = [:]
        for _ in 0..<Int.random(in: 1...40, using: &random) {
            let duration = [60, 120, 240, 480, 960, 1440].randomElement(using: &random)!
            // Chords, distinct-pitch overlaps, and gaps all happen in real
            // scores; a pitch never overlaps itself (ties merge upstream).
            let gap = [0, 0, 240, 480].randomElement(using: &random)!
            tick += gap
            var pitch = UInt8.random(in: 21...108, using: &random)
            while (openUntil[pitch] ?? 0) > tick {
                pitch = UInt8.random(in: 21...108, using: &random)
            }
            openUntil[pitch] = tick + duration
            events.append(NoteEvent(
                pitch: pitch, startTick: tick,
                durationTicks: duration,
                velocity: UInt8.random(in: 1...127, using: &random)))
            if Bool.random(using: &random) { tick += duration }
        }
        return Voice(name: name, events: events, totalTicks: tick + 1440)
    }
}
