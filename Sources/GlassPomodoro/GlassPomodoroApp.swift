import SwiftUI

@main
struct GlassPomodoroApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            PomodoroPanelView(model: model)
        } label: {
            MenuBarLabelView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// The menu-bar label. Kept as a real `View` (not a computed property on the `App`)
/// so `@Observable` changes re-render the label and the countdown ticks.
private struct MenuBarLabelView: View {
    @Bindable var model: AppModel

    var body: some View {
        let engine = model.engine
        let symbol = engine.breakPromptActive
            ? "bell.badge.fill"
            : (engine.isRunning ? engine.phase.symbolName : "timer")
        if let title = model.menuBarTitle {
            Label(title, systemImage: symbol)
                .labelStyle(.titleAndIcon)
        } else {
            Image(systemName: symbol)
        }
    }
}
