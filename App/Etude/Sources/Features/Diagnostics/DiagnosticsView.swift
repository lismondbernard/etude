import SwiftUI
import EtudeKit

/// Diagnostics (PLAN.md §8, screen 3): the Validator's findings, rendered as
/// candidly in the UI as in the tests. Clean pieces show their green seal;
/// Clair de Lune shows its register drift (ADR-0001, ADR-0003).
struct DiagnosticsView: View {
    let findings: [ValidationFinding]

    var body: some View {
        List {
            Section {
                Label(DiagnosticsPresenter.summary(for: findings),
                      systemImage: findings.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(findings.isEmpty ? .green : .orange)
                    .accessibilityIdentifier("diagnostics.summary")
            }
            if !findings.isEmpty {
                Section("Findings") {
                    ForEach(Array(findings.enumerated()), id: \.offset) { index, finding in
                        Text(DiagnosticsPresenter.line(for: finding))
                            .accessibilityIdentifier("diagnostics.finding.\(index)")
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .accessibilityIdentifier("diagnostics.screen")
    }
}
