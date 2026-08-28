import SwiftUI
import EtudeKit

/// Piece detail (PLAN.md §8, screen 2): Build → track list → Play/Pause,
/// tempo slider, Export, and the door to Diagnostics.
struct PieceDetailView: View {
    @State private var viewModel: PieceDetailViewModel
    @State private var sliderTempo: Double = 120
    @State private var exportURL: URL?

    init(piece: CorpusPiece) {
        _viewModel = State(initialValue: PieceDetailViewModel(
            piece: piece,
            builder: EnginePieceBuilder(corpus: BundledCorpus()),
            player: Self.makePlayer()))
    }

    /// UI tests pass `-uiTesting` to skip audio hardware (PLAN.md §8).
    @MainActor
    private static func makePlayer() -> any MIDIPlaying {
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
            ? SilentMIDIPlayer()
            : SystemMIDIPlayer(soundBankURL: SoundBank.bundledPiano)
    }

    var body: some View {
        List {
            buildSection
            if viewModel.phase == .built {
                tracksSection
                playbackSection
                diagnosticsSection
            }
        }
        .navigationTitle(viewModel.piece.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("detail.screen")
    }

    private var buildSection: some View {
        Section {
            switch viewModel.phase {
            case .building:
                ProgressView("Building…")
                    .accessibilityIdentifier("detail.progress.build")
            case .failed(let message):
                Label(message, systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("detail.error")
            case .idle, .built:
                Button(viewModel.phase == .built ? "Rebuild" : "Build") {
                    Task { await buildAndRefresh() }
                }
                .accessibilityIdentifier("detail.button.build")
            }
        } footer: {
            if let issue = viewModel.piece.knownIssue {
                Text("Ships with a recorded issue: \(issue)")
            }
        }
    }

    private var tracksSection: some View {
        Section("Tracks") {
            ForEach(viewModel.tracks, id: \.name) { track in
                HStack {
                    Text(track.name)
                    Spacer()
                    Text("\(track.events.count) notes")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .accessibilityIdentifier("detail.track.\(track.name)")
            }
        }
    }

    private var playbackSection: some View {
        Section("Playback") {
            Button {
                viewModel.togglePlayback()
            } label: {
                Label(viewModel.isPlaying ? "Pause" : "Play",
                      systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
            }
            .disabled(!viewModel.canPlay)
            .accessibilityIdentifier("detail.button.play")

            VStack(alignment: .leading) {
                Text("Tempo: \(Int(sliderTempo)) BPM").font(.caption)
                Slider(value: $sliderTempo, in: 40...200, step: 1) { editing in
                    if !editing {
                        Task {
                            await viewModel.applyTempo(Int(sliderTempo))
                            refreshExport()
                        }
                    }
                }
                .accessibilityIdentifier("detail.slider.tempo")
            }

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export MIDI", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("detail.button.export")
            }
        }
    }

    private var diagnosticsSection: some View {
        Section {
            NavigationLink {
                DiagnosticsView(findings: viewModel.findings)
            } label: {
                Label(DiagnosticsPresenter.summary(for: viewModel.findings),
                      systemImage: viewModel.findings.isEmpty ? "checkmark.seal" : "exclamationmark.triangle")
                    .foregroundStyle(viewModel.findings.isEmpty ? .green : .orange)
            }
            .accessibilityIdentifier("detail.link.diagnostics")
        }
    }

    private func buildAndRefresh() async {
        await viewModel.build()
        sliderTempo = Double(viewModel.tempoBeatsPerMinute)
        refreshExport()
    }

    private func refreshExport() {
        exportURL = try? viewModel.exportURL()
    }
}
