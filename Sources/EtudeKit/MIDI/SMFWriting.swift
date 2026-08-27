/// The score→bytes seam (§0.3). The app and the golden tests depend on this
/// protocol, not a concrete writer — which is what let Phase 6 swap the naive
/// explicit-status writer for `RunningStatusSMFWriter` without touching
/// either (§0.5). Any future writer must pass the shared `SMFWriterSpecs`
/// contract suite before it may stand behind this protocol.
public protocol SMFWriting: Sendable {
    func bytes(for score: Score) -> [UInt8]
}
