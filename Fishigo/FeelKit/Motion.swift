import SwiftUI
import UIKit

/// §7 timing constitution. Animation is feedback, not decoration — every
/// constant here is a named contract, not a magic number at a call site.
enum Motion {
    /// Every input must be acknowledged (visual + haptic together) within this.
    static let ackDeadline: TimeInterval = 0.10

    /// Intentional hold AFTER a recognition result arrives, BEFORE the reveal.
    static let suspenseBeat: ClosedRange<TimeInterval> = 0.3...0.5

    /// Ceremony envelope. Tap-to-skip after first-ever viewing.
    static let ceremony: ClosedRange<TimeInterval> = 1.8...3.0

    /// Delay between the success and heavy haptic of a record. (§7 haptic map)
    static let recordDoubleTap: TimeInterval = 0.12

    // MARK: Springs — micro-interactions 150–300 ms (response 0.3–0.45, damping 0.7–0.85)

    /// Default micro-interaction spring.
    static let micro = Animation.spring(response: 0.35, dampingFraction: 0.8)
    /// Snappier end of the allowed band — button presses, chip selections.
    static let microSnappy = Animation.spring(response: 0.30, dampingFraction: 0.7)
    /// Softer end — card lifts, sheet nudges.
    static let microSoft = Animation.spring(response: 0.45, dampingFraction: 0.85)
    /// Screen/state transitions, 300–450 ms.
    static let transition = Animation.spring(response: 0.40, dampingFraction: 0.85)

    /// Stamp entrance: scale 2.1→1.0, ~9° rotation. cubic-bezier(.2,1.6,.4,1)
    static let stamp = Animation.timingCurve(0.2, 1.6, 0.4, 1, duration: 0.35)

    // MARK: Reduce Motion (§7: crossfade instead of movement; haptics stay)

    static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Wraps an animation so Reduce Motion swaps movement for a crossfade.
    /// Use for anything that translates/scales; pure opacity can animate as-is.
    static func honoring(_ animation: Animation) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : animation
    }
}
