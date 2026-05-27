import SwiftUI

/// Full-screen blurred overlay shown across the break lifecycle:
/// 1. the break-due prompt (with optional auto-start countdown),
/// 2. the running break countdown,
/// 3. the "ready to focus again?" confirmation after the break ends.
struct BreakOverlayView: View {
    @Bindable var engine: PomodoroEngine

    private var accent: Color {
        if engine.awaitingFocusConfirmation { return Phase.focus.tint }
        if engine.breakPromptActive { return engine.pendingBreakPhase.tint }
        return engine.phase.tint
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            RadialGradient(
                colors: [accent.opacity(0.18), .black.opacity(0.28)],
                center: .center,
                startRadius: 80,
                endRadius: 700
            )
            .ignoresSafeArea()

            Group {
                if engine.breakPromptActive {
                    promptMode
                } else if engine.awaitingFocusConfirmation {
                    confirmMode
                } else {
                    breakMode
                }
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Mode 1 — break is due

    private var promptMode: some View {
        VStack(spacing: 28) {
            header(symbol: engine.pendingBreakPhase.symbolName,
                   title: "Time for a \(engine.pendingBreakPhase.title.lowercased())",
                   tint: engine.pendingBreakPhase.tint)

            Text("Starts in \(engine.promptCountdownRemaining)s")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: engine.promptCountdownRemaining)

            HStack(spacing: 14) {
                Button { engine.snooze() } label: {
                    Label("+\(engine.snoozeMinutes) min focus", systemImage: "hourglass")
                }
                .buttonStyle(.glass)

                Button { engine.skipBreak() } label: {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(.glass)

                Button { engine.startBreakNow() } label: {
                    Label("Start break", systemImage: "play.fill")
                }
                .buttonStyle(.glassProminent)
                .tint(engine.pendingBreakPhase.tint)
            }
            .controlSize(.extraLarge)

            Text("Skipping doubles your next break.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Mode 2 — break running

    private var breakMode: some View {
        VStack(spacing: 28) {
            header(symbol: engine.phase.symbolName,
                   title: engine.phase.title,
                   tint: engine.phase.tint)

            Text(engine.timeString)
                .font(.system(size: 130, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: engine.timeString)

            Button { engine.endBreak() } label: {
                Label("End break", systemImage: "stop.fill")
            }
            .buttonStyle(.glassProminent)
            .tint(engine.phase.tint)
            .controlSize(.extraLarge)

            Text("Press Esc to end the break")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Mode 3 — confirm ready to focus

    private var confirmMode: some View {
        VStack(spacing: 28) {
            header(symbol: "checkmark.circle.fill",
                   title: "Break complete",
                   tint: Phase.focus.tint)

            Text("Ready to focus?")
                .font(.system(size: 42, weight: .semibold, design: .rounded))

            Button { engine.confirmReadyToFocus() } label: {
                Label("Start focusing", systemImage: "brain.head.profile")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .tint(Phase.focus.tint)
            .controlSize(.extraLarge)

            Text("Press Esc to start")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Shared

    private func header(symbol: String, title: String, tint: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
        }
    }
}
