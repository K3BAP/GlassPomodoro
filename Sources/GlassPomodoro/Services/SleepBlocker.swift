import Foundation
import IOKit.pwr_mgt

/// Holds IOKit power assertions to keep the Mac (and optionally its display) awake
/// while a timer is running, so the user never misses the end of a focus or break.
@MainActor
final class SleepBlocker {
    private var systemAssertion: IOPMAssertionID = 0
    private var displayAssertion: IOPMAssertionID = 0

    /// Reconcile the held assertions to the desired state.
    /// - preventSystemSleep: keep the system awake (timer keeps ticking even if idle).
    /// - preventDisplaySleep: also keep the screen on (implies system stays awake too).
    func update(preventSystemSleep: Bool, preventDisplaySleep: Bool) {
        set(&systemAssertion,
            on: preventSystemSleep && !preventDisplaySleep,
            type: kIOPMAssertPreventUserIdleSystemSleep,
            reason: "Glass Pomodoro timer is running")
        set(&displayAssertion,
            on: preventDisplaySleep,
            type: kIOPMAssertPreventUserIdleDisplaySleep,
            reason: "Glass Pomodoro break overlay is showing")
    }

    private func set(_ id: inout IOPMAssertionID, on: Bool, type: String, reason: String) {
        if on {
            guard id == 0 else { return }
            IOPMAssertionCreateWithName(type as CFString,
                                        IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                        reason as CFString,
                                        &id)
        } else {
            guard id != 0 else { return }
            IOPMAssertionRelease(id)
            id = 0
        }
    }
}
