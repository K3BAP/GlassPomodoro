import SwiftUI

/// Circular progress ring with the remaining time in the center.
struct TimerRingView: View {
    let progress: Double
    let timeString: String
    let phase: Phase
    let isRunning: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(
                    phase.tint.gradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            VStack(spacing: 4) {
                Image(systemName: phase.symbolName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(phase.tint)
                Text(timeString)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: timeString)
                Text(phase.title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 190, height: 190)
        .opacity(isRunning ? 1 : 0.85)
    }
}
