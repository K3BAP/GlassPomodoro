import SwiftUI

/// Main menu-bar popover content with the Liquid Glass aesthetic.
struct PomodoroPanelView: View {
    @Bindable var model: AppModel
    @State private var showingSettings = false

    private var engine: PomodoroEngine { model.engine }

    var body: some View {
        Group {
            if engine.breakPromptActive {
                BreakPromptView(engine: engine)
            } else if engine.awaitingFocusConfirmation {
                confirmFocusView
            } else if showingSettings {
                SettingsView(model: model, isPresented: $showingSettings)
            } else {
                timerContent
            }
        }
        .frame(width: 280)
        .background(.clear)
    }

    private var timerContent: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 18) {
                header

                TimerRingView(
                    progress: engine.progress,
                    timeString: engine.timeString,
                    phase: engine.phase,
                    isRunning: engine.isRunning
                )
                .padding(.vertical, 4)

                iterationDots

                totalCounter

                controls
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack {
            Text("Glass Pomodoro")
                .font(.headline)
            Spacer()
            Button {
                withAnimation(.smooth) { showingSettings = true }
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(.glass)
            .controlSize(.small)

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.glass)
            .controlSize(.small)
        }
    }

    private var iterationDots: some View {
        let total = max(1, model.settings.iterationsBeforeLongBreak)
        let done = engine.completedFocusCount % total
        return HStack(spacing: 7) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < done ? engine.phase.tint : Color.white.opacity(0.18))
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.snappy, value: done)
    }

    private var confirmFocusView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Phase.focus.tint)
            Text("Break complete")
                .font(.headline)
            Text("Ready to focus?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                engine.confirmReadyToFocus()
            } label: {
                Label("Start focusing", systemImage: "brain.head.profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(Phase.focus.tint)
            .controlSize(.large)
        }
        .padding(20)
    }

    private var totalCounter: some View {
        Label("\(engine.totalFocusSessions) focus sessions completed", systemImage: "checkmark.seal.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
            .animation(.snappy, value: engine.totalFocusSessions)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                engine.startOrPause()
            } label: {
                Label(
                    engine.isRunning ? "Pause" : "Start",
                    systemImage: engine.isRunning ? "pause.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(engine.phase.tint)

            Button {
                engine.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.glass)
        }
        .controlSize(.large)
    }
}
