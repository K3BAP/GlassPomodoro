import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @Binding var isPresented: Bool

    private var settings: Settings { model.settings }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.smooth) { isPresented = false }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section("Durations (minutes)") {
                        stepperRow("Focus", value: bind(\.focusMinutes), range: 1...120)
                        stepperRow("Short break", value: bind(\.shortBreakMinutes), range: 1...60)
                        stepperRow("Long break", value: bind(\.longBreakMinutes), range: 1...60)
                        stepperRow("Sessions before long break", value: bind(\.iterationsBeforeLongBreak), range: 1...12)
                    }

                    section("Break prompt") {
                        stepperRow("Snooze length", value: bind(\.snoozeMinutes), range: 1...30)
                        stepperRow("Auto-start countdown (sec)", value: bind(\.promptCountdownSeconds), range: 3...60)
                        toggleRow("Auto-start breaks", value: bind(\.autoStartBreaks))
                        toggleRow("Auto-start focus", value: bind(\.autoStartFocus))
                    }

                    section("Notifications & feedback") {
                        toggleRow("Sound on phase change", value: bind(\.soundEnabled))
                        toggleRow("System notifications", value: bind(\.notificationsEnabled))
                        toggleRow("Show countdown in menu bar", value: bind(\.showMenuBarCountdown))
                    }

                    section("General") {
                        toggleRow("Launch at login", value: bind(\.launchAtLogin))
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 280, height: 440)
    }

    // MARK: Helpers

    private func bind<V>(_ keyPath: ReferenceWritableKeyPath<Settings, V>) -> Binding<V> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: {
                settings[keyPath: keyPath] = $0
                model.settingsChanged()
            }
        )
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.secondary)
            VStack(spacing: 10) {
                content()
            }
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
        }
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("\(value.wrappedValue)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
    }

    private func toggleRow(_ label: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Text(label).font(.subheadline)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}
