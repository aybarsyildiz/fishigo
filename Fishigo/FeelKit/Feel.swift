import UIKit
import CoreHaptics

/// §7 haptic map. One semantic method per app event — call sites never touch
/// generators or intensities directly, so the whole feel can be tuned here.
/// Every sound (added later) will have its haptic twin in this file.
/// TODO(sound): pair each event with its placeholder sound when audio lands.
@MainActor
final class Feel {
    static let shared = Feel()

    private let selection = UISelectionFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()

    private var engine: CHHapticEngine?

    private init() {}

    /// Prepares generators and spins up the CoreHaptics engine. Call at launch.
    func prepare() {
        selection.prepare()
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        notify.prepare()

        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.resetHandler = { [weak engine] in
                try? engine?.start()
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    // MARK: §7 haptic map — one method per semantic event

    func tabSwitch() { selection.selectionChanged() }
    func buttonTap() { impactLight.impactOccurred() }
    func cardLift() { impactSoft.impactOccurred() }
    func cardDrop() { impactRigid.impactOccurred() }
    /// One tick per card as the deks cascade flips. §7 signature reel-click.
    func deksCascadeTick() { selection.selectionChanged(); Ses.shared.tik() }
    func shutter() { impactMedium.impactOccurred() }
    func speciesConfirmed() { notify.notificationOccurred(.success) }
    /// One tick per centimeter on the ruler input. §7 signature reel-click.
    func rulerTick() { selection.selectionChanged(); Ses.shared.tik() }
    /// Empty trip logged. §7: warning, NEVER error — a fishless day is not a failure.
    func emptyCatch() { notify.notificationOccurred(.warning) }

    /// İLK YAKALAYIŞ stamp: heavy impact + sharp transient (intensity 1.0,
    /// sharpness 0.9) + dry ink-thunk sound (§7 signature).
    func stamp() {
        impactHeavy.impactOccurred()
        playTransients([(delay: 0, intensity: 1.0, sharpness: 0.9)])
        Ses.shared.damga()
    }

    /// Personal record: success, then heavy, 120 ms apart.
    func record() {
        notify.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + Motion.recordDoubleTap) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }
    }

    /// New-species ceremony: ramp 0.2→0.7 over 600 ms → 80 ms silence →
    /// heavy transient → two decaying softs, with the brass-paper sting (§7).
    func newSpeciesCeremony() {
        Ses.shared.yeniTur()
        guard let engine else {
            // Generator approximation for devices without CoreHaptics.
            impactSoft.impactOccurred(intensity: 0.4)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) { self.impactHeavy.impactOccurred() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.86) { self.impactSoft.impactOccurred(intensity: 0.6) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.04) { self.impactSoft.impactOccurred(intensity: 0.35) }
            return
        }

        let ramp = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
            ],
            relativeTime: 0,
            duration: 0.6)
        let rampCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.2),
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.6, value: 0.7),
            ],
            relativeTime: 0)
        let thunk = transientEvent(at: 0.68, intensity: 1.0, sharpness: 0.9)
        let echo1 = transientEvent(at: 0.86, intensity: 0.5, sharpness: 0.3)
        let echo2 = transientEvent(at: 1.04, intensity: 0.3, sharpness: 0.25)

        if let pattern = try? CHHapticPattern(events: [ramp, thunk, echo1, echo2], parameterCurves: [rampCurve]),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }

    // MARK: CoreHaptics plumbing

    private func transientEvent(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time)
    }

    private func playTransients(_ transients: [(delay: TimeInterval, intensity: Float, sharpness: Float)]) {
        guard let engine else { return }
        let events = transients.map { transientEvent(at: $0.delay, intensity: $0.intensity, sharpness: $0.sharpness) }
        if let pattern = try? CHHapticPattern(events: events, parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }
}
