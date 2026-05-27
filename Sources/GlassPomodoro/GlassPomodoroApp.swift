import SwiftUI

@main
struct GlassPomodoroApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            PomodoroPanelView(model: model)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        let symbol = model.engine.breakPromptActive
            ? "bell.badge.fill"
            : (model.engine.isRunning ? model.engine.phase.symbolName : "timer")
        if let title = model.menuBarTitle {
            Label(title, systemImage: symbol)
        } else {
            Image(systemName: symbol)
        }
    }
}
