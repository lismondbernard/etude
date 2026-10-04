/// Track names in the musician's language. Voice names are LilyPond
/// variable names from the sources (`rhUp`, `violinOne`); a pure function
/// maps them, like `DiagnosticsPresenter` (§0.9: no view model for this).
/// The voice name itself stays the track's identity everywhere else.
enum TrackPresenter {
    private static let known: [String: String] = [
        "rhUp": "Right hand, upper",
        "rhDown": "Right hand, lower",
        "lhUp": "Left hand, upper",
        "lhDown": "Left hand, lower",
        "solo": "Solo violin",
        "violinOne": "Violin I",
        "violinTwo": "Violin II",
    ]

    static func name(for voice: String) -> String {
        known[voice] ?? spelledOut(voice)
    }

    /// `upperChords` → "Upper chords": split the camel case into words and
    /// capitalize the first, so a new piece's voices read sensibly unmapped.
    private static func spelledOut(_ voice: String) -> String {
        var words: [String] = []
        for character in voice {
            if character.isUppercase || words.isEmpty {
                words.append(String(character).lowercased())
            } else {
                words[words.count - 1].append(character)
            }
        }
        guard let first = words.first else { return voice }
        return ([first.prefix(1).uppercased() + first.dropFirst()] + words.dropFirst())
            .joined(separator: " ")
    }
}
