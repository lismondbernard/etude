// Corpus catalog — the bundled pieces as engine metadata   (Phase 5)
//
// One entry per vendored source: everything the app and the acceptance tests
// need to locate, build, and present a piece. Musical truth (fingerprints,
// bar counts) stays in the acceptance tests; this is identity and build
// configuration. Velocities are the prototype's proven mix.

public struct CorpusPiece: Equatable, Sendable, Identifiable {
    /// The corpus file's basename: `Corpus/<id>.ly`.
    public let id: String
    public let title: String
    public let composer: String
    /// Per-voice velocities (the prototype's balance); unlisted voices get
    /// the builder's default.
    public let velocities: [String: UInt8]
    /// Voices named explicitly when the source carries no `\score` block.
    public let voices: [String]?
    /// Tempo assumed when the source's mark names a feel without a number.
    public let assumedBeatsPerMinute: Int?
    /// A recorded defect the piece ships with — presented, never hidden
    /// (ADR-0003). Diagnostics shows it; the goldens pin it.
    public let knownIssue: String?
    /// Short typesetting-license note for the library row (Corpus/LICENSES.md
    /// is the authority).
    public let licenseBadge: String

    public init(
        id: String, title: String, composer: String,
        velocities: [String: UInt8] = [:],
        voices: [String]? = nil,
        assumedBeatsPerMinute: Int? = nil,
        knownIssue: String? = nil,
        licenseBadge: String = "Public domain"
    ) {
        self.id = id
        self.title = title
        self.composer = composer
        self.velocities = velocities
        self.voices = voices
        self.assumedBeatsPerMinute = assumedBeatsPerMinute
        self.knownIssue = knownIssue
        self.licenseBadge = licenseBadge
    }

    public static let all: [CorpusPiece] = [
        CorpusPiece(
            id: "minuet-in-g", title: "Minuet in G major", composer: "Christian Petzold",
            velocities: ["melody": 92, "bass": 72]),
        CorpusPiece(
            id: "prelude-in-c", title: "Prelude in C major", composer: "Johann Sebastian Bach",
            velocities: ["figuration": 90, "tenor": 90, "bass": 90]),
        CorpusPiece(
            id: "air-on-the-g-string", title: "Air on the G String",
            composer: "Johann Sebastian Bach",
            velocities: ["melody": 92, "accompaniment": 78]),
        CorpusPiece(
            id: "winter-largo", title: "Winter (Largo)", composer: "Antonio Vivaldi",
            velocities: ["solo": 96, "violinOne": 60, "violinTwo": 60,
                         "viola": 66, "cello": 66],
            licenseBadge: "CC-BY-SA typesetting"),
        CorpusPiece(
            id: "gymnopedie-1", title: "Gymnopédie No. 1", composer: "Erik Satie",
            velocities: ["melody": 88, "accompaniment": 64, "bass": 64]),
        CorpusPiece(
            id: "gnossienne-1", title: "Gnossienne No. 1", composer: "Erik Satie",
            velocities: ["melody": 90, "upperChords": 62, "lowerChords": 62, "bass": 70],
            licenseBadge: "CC-BY-SA 4.0 typesetting"),
        CorpusPiece(
            id: "clair-de-lune", title: "Clair de Lune", composer: "Claude Debussy",
            velocities: ["rhUp": 82, "rhDown": 82, "lhUp": 72, "lhDown": 72],
            voices: ["rhUp", "rhDown", "lhUp", "lhDown"],
            assumedBeatsPerMinute: 60),
    ]
}
