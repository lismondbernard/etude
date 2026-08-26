import EtudeKit

/// The corpus spec: each piece's source file and per-voice velocities (kept
/// at the prototype's proven mix so the pieces balance the same way).
/// Fingerprints and bar counts live in the piece's acceptance test.
struct CorpusPiece {
    let file: String
    let velocities: [String: UInt8]

    static let all: [CorpusPiece] = [
        CorpusPiece(file: "minuet-in-g",
                    velocities: ["melody": 92, "bass": 72]),
        CorpusPiece(file: "prelude-in-c",
                    velocities: ["figuration": 90, "tenor": 90, "bass": 90]),
        CorpusPiece(file: "air-on-the-g-string",
                    velocities: ["melody": 92, "accompaniment": 78]),
        CorpusPiece(file: "winter-largo",
                    velocities: ["solo": 96, "violinOne": 60, "violinTwo": 60,
                                 "viola": 66, "cello": 66]),
        CorpusPiece(file: "gymnopedie-1",
                    velocities: ["melody": 88, "accompaniment": 64, "bass": 64]),
        CorpusPiece(file: "gnossienne-1",
                    velocities: ["melody": 90, "upperChords": 62, "lowerChords": 62,
                                 "bass": 70]),
    ]
}
