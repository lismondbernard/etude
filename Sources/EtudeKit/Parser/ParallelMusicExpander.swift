// ParallelMusicExpander — round-robin bar distribution   (Phase 4)
//
// `\parallelMusic #'(a b c) { … }` writes several voices interleaved: bar 1
// of voice a, bar 1 of voice b, bar 1 of voice c, bar 2 of voice a, … — the
// bars are dealt like cards to the named voices. This ports the prototype's
// PROVEN expansion (PLAN.md §7: it correctly dealt Clair de Lune's 72 bars
// per voice; timing the result is the part that remains issue #1).
//
// PLAN.md places the expander "in the Resolver" after the prototype, which
// expanded during resolution; here distribution is a structural fact about
// the source, so it lives beside the parser and feeds file definitions.

public struct ParallelMusicExpander: Sendable {
    public init() {}

    /// Deals the block's top-level bars (split at `|`) round-robin to
    /// `names`, returning one sequence per voice. A segment that parses to no
    /// performed music (engraving noise, a trailing `|`) is not a bar.
    public func expand(
        names: [String], body: [Token]
    ) throws(ParseError) -> [String: MusicNode] {
        var segments: [[Token]] = [[]]
        var depth = 0
        for token in body {
            switch token {
            case .braceOpen, .parallelStart, .chordStart:
                depth += 1
                segments[segments.count - 1].append(token)
            case .braceClose, .parallelEnd, .chordEnd:
                depth -= 1
                segments[segments.count - 1].append(token)
            case .barCheck where depth == 0:
                segments.append([])
            default:
                segments[segments.count - 1].append(token)
            }
        }

        var bars: [[MusicNode]] = []
        for segment in segments {
            let music = try Parser().parseMusic(segment)
            if !music.isEmpty { bars.append(music) }
        }

        var voices: [String: [MusicNode]] = [:]
        for (index, bar) in bars.enumerated() {
            voices[names[index % names.count], default: []] += bar
        }
        return voices.mapValues { .sequence($0) }
    }
}
