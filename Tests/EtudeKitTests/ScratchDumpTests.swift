import Testing
import Foundation
import EtudeKit

@Suite("Scratch dump") struct ScratchDumpTests {
    @Test("clair validate") func clairValidate() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Corpus/clair-de-lune.ly")
        let file = try Parser().parseFile(try Tokenizer().tokenize(String(contentsOf: url, encoding: .utf8)))
        let score = try ScoreBuilder().score(
            from: file, voices: ["rhUp", "rhDown", "lhUp", "lhDown"],
            title: "Clair de Lune",
            velocities: ["rhUp": 82, "rhDown": 82, "lhUp": 72, "lhDown": 72],
            assumingBeatsPerMinute: 60)
        print("TEMPO", score.tempo as Any)
        print("METER", score.meter as Any)
        print("OPENING", score.voices[0].events.prefix(6).map(\.pitch))
        for v in score.voices {
            print("RANGE", v.name, v.events.map(\.pitch).min() ?? 0, v.events.map(\.pitch).max() ?? 0)
        }
        for event in score.voices[3].events where event.pitch < 21 {
            print("LOW bar", event.startTick / 2160 + 1, "tick", event.startTick,
                  "pitch", event.pitch, "dur", event.durationTicks)
        }
    }
}
