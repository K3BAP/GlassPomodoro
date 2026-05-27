import SwiftUI

/// Shown when a break is due: skip, snooze (+5), or start the break now.
/// If `autoStartBreaks` is on, a countdown auto-starts the break.
struct BreakPromptView: View {
    let engine: PomodoroEngine
    let showCountdown: Bool

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Image(systemName: engine.pendingBreakPhase.symbolName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(engine.pendingBreakPhase.tint)
                Text("Time for a \(engine.pendingBreakPhase.title.lowercased())")
                    .font(.headline)
                if showCountdown {
                    Text("Starts in \(engine.promptCountdownRemaining)s")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: engine.promptCountdownRemaining)
                } else {
                    Text("Choose how to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                Button {
                    engine.startBreakNow()
                } label: {
                    Label("Start break", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(engine.pendingBreakPhase.tint)

                HStack(spacing: 8) {
                    Button {
                        engine.snooze()
                    } label: {
                        Label("+5 min", systemImage: "hourglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button {
                        engine.skipBreak()
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
            }
            .controlSize(.large)

            Text("Skipping doubles your next break.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(width: 260)
    }
}
