<div align="center">

# 🍅 Glass Pomodoro

**A native macOS menu-bar Pomodoro timer built for macOS 26 Liquid Glass.**

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-black?style=flat-square&logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✦-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

</div>

---

<div align="center">

*Lives entirely in your menu bar. Takes over your screen when it's time to rest.*

</div>

---

## What it is

Glass Pomodoro runs silently in the background — no Dock icon, no clutter. It counts down from your menu bar and, when a break is due, covers your entire screen with a frosted-glass overlay so you actually take it.

Built with SwiftUI and the new **Liquid Glass** APIs introduced in macOS 26. It feels like it belongs there.

---

## Features

### Core timer
- **25 / 5 / 15** minute focus, short break, and long break durations (all configurable)
- Long break kicks in automatically after **4 focus sessions**
- Live **countdown in the menu bar** during focus — disappears during breaks

### Break handling
| Action | What happens |
|--------|-------------|
| **Start break** | Full-screen glass overlay appears immediately |
| **Snooze +5 min** | Adds focus time; prompt re-fires when it runs out |
| **Skip break** | Doubles the *next* break instead |
| **Auto-start** | Configurable countdown auto-begins the break |

### Full-screen overlay
The overlay morphs through three stages without hiding:
1. **Break due** — prompt with your three options
2. **Break running** — ambient countdown with blurred backdrop and radial glow
3. **Ready to focus?** — confirmation before the next session starts

Press **Esc** at any point to interact with the prompt or dismiss the confirmation.

### Everything else
- 🔊 Sound on every phase transition
- 🔔 Native system notifications
- 🚀 Launch at login
- 💤 Prevent sleep while a focus session is running
- ⚙️ All settings live in one tidy popover — no separate preferences window

---

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | **26.0+** |
| Xcode | **16+ (full Xcode, not just CLT)** |

> The `.glassEffect()` / `GlassEffectContainer` APIs ship only in the macOS 26 SDK. Older systems are not supported.

---

## Install

Download **GlassPomodoro.zip** from the [Releases](https://github.com/K3BAP/GlassPomodoro/releases/) page, unzip, and drag `GlassPomodoro.app` to `/Applications`.

> **First launch:** right-click → Open to bypass Gatekeeper (the build is ad-hoc signed, not notarized). After the first open it launches normally.

The app runs as a background agent — look for the 🍅 in your menu bar.

---

## Build from source

```bash
# 1. Clone
git clone https://github.com/K3BAP/GlassPomodoro
cd GlassPomodoro

# 2. Generate the Xcode project (required before first build and after adding files)
make generate

# 3. Build and run
make run
```

Other targets:

```bash
make build    # Debug build only (no launch)
make release  # Release build → dist/GlassPomodoro.zip
make install  # Release build → /Applications
make clean    # Remove build artifacts
```

> If `xcodebuild` complains about an active developer dir pointing to Command Line Tools, prefix with:
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer make build`

---

## Settings

All settings are saved automatically as a JSON blob in `UserDefaults`.

| Setting | Default | Description |
|---------|---------|-------------|
| Focus duration | 25 min | Length of a focus session |
| Short break | 5 min | Break after each session |
| Long break | 15 min | Break after every 4 sessions |
| Sessions before long break | 4 | How many focus sessions per cycle |
| Snooze length | 5 min | Added focus time when you snooze a break |
| Auto-start countdown | 10 sec | Seconds before break auto-begins |
| Auto-start focus | off | Skip the "ready to focus?" confirmation |
| Sound on phase change | on | Play a chime at transitions |
| System notifications | on | Show macOS notifications |
| Countdown in menu bar | on | Live timer while focusing |
| Full-screen overlay | on | Cover the screen during breaks |
| Launch at login | off | Start Glass Pomodoro on login |
| Prevent sleep | on | Block macOS sleep during focus sessions |

---

## Architecture

```
GlassPomodoroApp      ← @main, owns AppModel
│
├── AppModel           ← composition root; wires engine callbacks → side effects
│   ├── PomodoroEngine ← @Observable state machine; single 1-second Task ticker
│   └── Settings       ← @Observable prefs; persisted as JSON in UserDefaults
│
├── Views/
│   ├── MenuBarLabelView       ← menu-bar countdown label
│   ├── PomodoroPanelView      ← popover; switches between timer / prompt / settings
│   ├── BreakOverlayView       ← full-screen overlay (prompt → break → confirm)
│   ├── TimerRingView          ← arc progress ring
│   └── SettingsView           ← settings panel
│
└── Services/
    ├── BreakOverlayController ← AppKit bridge; one NSWindow per NSScreen
    ├── SoundPlayer            ← phase-transition chimes
    ├── NotificationService    ← UNUserNotificationCenter wrapper
    ├── SleepBlocker           ← IOPMAssertion to prevent display sleep
    └── LaunchAtLogin          ← SMAppService wrapper
```

The data flow is strictly one-way: `Settings` + `PomodoroEngine` → views. Views call engine methods; the engine fires callbacks for side effects; `AppModel` handles them. The engine has zero AppKit/UIKit imports.

---

## Project file note

The Xcode project (`GlassPomodoro.xcodeproj`) is **generated** from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). Never hand-edit it — run `make generate` instead. Adding or removing Swift source files requires a regeneration before they compile.

---

<div align="center">

Made with ☕ and way too many focus sessions.

</div>
