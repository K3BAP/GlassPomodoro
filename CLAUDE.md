# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A macOS 26 menu-bar Pomodoro timer (SwiftUI) with the Liquid Glass aesthetic. It runs as a
background agent (`LSUIElement = true`, no Dock icon) — its only UI surfaces are the `MenuBarExtra`
popover and a full-screen break overlay.

## Build & run

The Xcode project is **generated** from `project.yml` by XcodeGen — never hand-edit
`GlassPomodoro.xcodeproj`; it is regenerated and changes are lost. Sources are globbed, so adding a
new `.swift` file under `Sources/` requires regenerating before it will compile.

```
make generate   # xcodegen generate  (run after adding/removing/renaming source files)
make build      # regenerate + xcodebuild (Debug)
make run        # build + open the .app
make clean
```

Important environment facts (see git history / earlier setup):
- Full **Xcode** is required (not just Command Line Tools): the Liquid Glass `.glassEffect()` /
  `GlassEffectContainer` APIs only exist in the full Xcode SDK. If `xcodebuild` reports the active
  dir is CommandLineTools, prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Builds use ad-hoc signing. `make build` works as-is; if signing errors appear, pass
  `CODE_SIGNING_ALLOWED=NO` to `xcodebuild`. Under ad-hoc signing, **notifications and
  launch-at-login may not function** — that is expected, not a bug.

There are no tests or linters configured.

## Architecture

Single source of truth flows one way: **`Settings` + `PomodoroEngine` → views**. Both models are
`@Observable`; views read them directly and call engine methods. There is no separate view-model per
view.

- **`Model/PomodoroEngine.swift`** — the `@MainActor @Observable` state machine and the only timer.
  A single 1-second `Task` loop (`ticker`) drives everything; pausing cancels the task (no `Timer`,
  no drift accumulation). Phases cycle focus → break-prompt → break → focus. Key state the UI keys
  off of: `phase`, `secondsRemaining`, `isRunning`, `breakPromptActive`, `awaitingFocusConfirmation`,
  `pendingBreakPhase`. **Counting rule:** a focus session is counted exactly once, at the moment it
  *leaves* focus — i.e. in `beginBreak()` and `skipBreak()` (mutually exclusive per cycle). Do not
  add increments elsewhere (a prior double-count bug came from incrementing on break-completion too).
  `completedFocusCount` is the within-cycle counter (drives long-break cadence + dots);
  `totalFocusSessions` is the lifetime counter persisted in `UserDefaults`, cleared only by `reset()`.

- **`Model/Settings.swift`** — all user prefs, persisted as one JSON blob in `UserDefaults`
  (`Settings.load()` / `.save()`). It hand-rolls `Codable` (init + encode + CodingKeys) because
  `@Observable` adds stored properties that must be excluded; **every new setting must be added in
  four places**: the property, `CodingKeys`, the decode (`decodeIfPresent ?? default`), and encode.

- **`Model/AppModel.swift`** — the composition root owned by the `App`. Constructs `Settings` +
  `PomodoroEngine`, and wires the engine's two callbacks to side effects:
  - `onAnnounce(title, body, phase)` → `SoundPlayer` + `NotificationService` (gated by settings).
  - `onOverlayStateChanged()` → recomputes `engine.isOverlayActive` and shows/hides the overlay.
  This callback pattern is deliberate: the engine stays free of AppKit/UI dependencies and just
  signals intent. `menuBarTitle` returns the countdown text **only during focus** (breaks are shown
  in the overlay instead).

- **`Services/BreakOverlayController.swift`** — AppKit bridge. Creates one borderless
  `OverlayWindow` (subclassed so a borderless window can `canBecomeKey`) **per `NSScreen`** at
  `.screenSaver` level, hosting `BreakOverlayView`. A local key monitor maps **Esc → `engine.handleEscape()`**.
  Driven solely via `update(visible:engine:enabled:)`.

- **`Views/`** — pure SwiftUI, all reading the engine/settings.
  - `GlassPomodoroApp.swift`: the `@main` `App`. The `MenuBarExtra` label **must** be a real `View`
    (`MenuBarLabelView`), not a computed property on the `App` — otherwise `@Observable` changes
    don't re-render the label and the menu-bar countdown silently never updates.
  - `PomodoroPanelView.swift`: the popover. Switches between break prompt / confirm-focus / settings
    / timer based on engine state.
  - `BreakOverlayView.swift`: one view that morphs across three modes by reading engine state —
    break-due prompt, running break, and "ready to focus?" confirmation.
  - `BreakPromptView`, `TimerRingView`, `SettingsView`: popover sub-views.

## Behavior contracts (easy to break)

- **Break prompt** (`breakPromptActive`): Skip = double the *next* break (`nextBreakDoubled`);
  +5 min = `snooze()` (delay the break by adding focus time, prompt re-fires); Start = begin break.
  If `autoStartBreaks`, the prompt counts down and auto-starts (`promptShowsCountdown`).
- **Break end**: when `fullScreenBreakOverlay` is ON, a finished break does **not** auto-resume — it
  sets `awaitingFocusConfirmation` and waits for the user's "Start focusing". When that setting is
  OFF, it falls back to auto-resume so the user is never left with no way to continue. Preserve this
  fallback if you touch `completePhase()`.
- The overlay is a single set of windows that stays up and switches modes across prompt → break →
  confirm; `show()` early-returns if windows already exist. Visibility is recomputed from
  `engine.isOverlayActive` on every `onOverlayStateChanged`.
