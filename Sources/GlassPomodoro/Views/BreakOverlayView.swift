import SwiftUI

/// Full-screen blurred break view with a large centered countdown and controls.
struct BreakOverlayView: View {
    @Bindable var engine: PomodoroEngine

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Subtle phase-tinted vignette over the blur.
            RadialGradient(
                colors: [engine.phase.tint.opacity(0.18), .black.opacity(0.28)],
                center: .center,
                startRadius: 80,
                endRadius: 700
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: engine.phase.symbolName)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(engine.phase.tint)
                    Text(engine.phase.title)
                        .font(.system(size: 22, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }

                Text(engine.timeString)
                    .font(.system(size: 130, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: engine.timeString)
                    .foregroundStyle(.primary)

                HStack(spacing: 14) {
                    Button {
                        engine.extendBreak()
                    } label: {
                        Label("+5 min", systemImage: "hourglass")
                    }
                    .buttonStyle(.glass)

                    Button {
                        engine.endBreak()
                    } label: {
                        Label("End break", systemImage: "stop.fill")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(engine.phase.tint)
                }
                .controlSize(.extraLarge)

                Text("Press Esc to end the break")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
