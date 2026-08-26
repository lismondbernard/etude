import EtudeKit

// Parser-level sample builders (PLAN.md §0.6): parser tests feed LilyPond
// source through the Phase 1-proven tokenizer so test bodies read in the
// domain language instead of hand-assembled token arrays.

func tokens(_ source: String) throws -> [Token] {
    try Tokenizer().tokenize(source)
}

func note(
    _ name: String, marks: Int = 0, _ duration: DurationToken? = nil, tied: Bool = false
) -> MusicNode {
    .note(NoteToken(name: name, octaveMarks: marks, duration: duration), tied: tied)
}

func dur(_ value: Int, dots: Int = 0) -> DurationToken {
    DurationToken(value, dots: dots)
}
